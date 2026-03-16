import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ExamVisibility, FriendRequestStatus, Prisma, UserRole } from '@prisma/client';

import { PrismaService } from 'src/infra/prisma/prisma.service';

import { CreateExamDto } from './dto/create-exam.dto';
import { UpdateExamDto } from './dto/update-exam.dto';

@Injectable()
export class ExamsService {
  constructor(private readonly prisma: PrismaService) {}

  async createExam(userId: string, dto: CreateExamDto) {
    const visibility = dto.visibility as ExamVisibility;
    const assignedExamineeIds = await this.resolveAssignments(userId, visibility, dto.assignedExamineeIds ?? []);

    return this.prisma.exam.create({
      data: {
        title: dto.title,
        description: dto.description,
        durationMinutes: dto.durationMinutes,
        negativeMarkPerWrong: new Prisma.Decimal(dto.negativeMarkPerWrong),
        visibility,
        createdById: userId,
        assignments: assignedExamineeIds.length
          ? {
              createMany: {
                data: assignedExamineeIds.map((examineeId) => ({ examineeId })),
              },
            }
          : undefined,
      },
      include: { assignments: true },
    });
  }

  async updateExam(userId: string, examId: string, dto: UpdateExamDto) {
    await this.assertExamOwner(userId, examId);
    const visibility = dto.visibility as ExamVisibility | undefined;
    const assignedExamineeIds = visibility
      ? await this.resolveAssignments(userId, visibility, dto.assignedExamineeIds ?? [])
      : dto.assignedExamineeIds;

    return this.prisma.exam.update({
      where: { id: examId },
      data: {
        title: dto.title,
        description: dto.description,
        durationMinutes: dto.durationMinutes,
        negativeMarkPerWrong: dto.negativeMarkPerWrong === undefined ? undefined : new Prisma.Decimal(dto.negativeMarkPerWrong),
        visibility,
        assignments: assignedExamineeIds
          ? {
              deleteMany: {},
              createMany: {
                data: assignedExamineeIds.map((examineeId) => ({ examineeId })),
              },
            }
          : undefined,
      },
      include: { assignments: true },
    });
  }

  async publishExam(userId: string, examId: string) {
    const exam = await this.assertExamOwner(userId, examId);
    const questionCount = await this.prisma.question.count({ where: { examId } });
    if (questionCount === 0) {
      throw new BadRequestException('Cannot publish an exam without questions.');
    }
    if (exam.visibility !== ExamVisibility.PUBLIC) {
      const assignmentCount = await this.prisma.examAssignment.count({ where: { examId } });
      if (assignmentCount === 0) {
        throw new BadRequestException('Friend-only exams must have assigned examinees before publishing.');
      }
    }
    return this.prisma.exam.update({ where: { id: examId }, data: { isPublished: true } });
  }

  myExams(userId: string) {
    return this.prisma.exam.findMany({
      where: { createdById: userId },
      include: {
        questions: true,
        assignments: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  availableExams(userId: string) {
    return this.prisma.exam.findMany({
      where: {
        isPublished: true,
        OR: [
          { visibility: ExamVisibility.PUBLIC },
          { assignments: { some: { examineeId: userId } } },
        ],
      },
      include: {
        createdBy: { include: { profile: true } },
        assignments: true,
        _count: { select: { questions: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async examDetail(userId: string, examId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
      include: {
        questions: { orderBy: { orderIndex: 'asc' } },
        assignments: true,
        createdBy: { include: { profile: true } },
      },
    });
    if (!exam) {
      throw new NotFoundException('Exam not found.');
    }

    if (user.role === UserRole.EXAMINER) {
      if (exam.createdById !== userId) {
        throw new ForbiddenException('Not allowed to view this examiner exam.');
      }
      return exam;
    }

    const canView = exam.isPublished && (exam.visibility === ExamVisibility.PUBLIC || exam.assignments.some((item) => item.examineeId === userId));
    if (!canView) {
      throw new ForbiddenException('Exam is not available to this examinee.');
    }

    return {
      ...exam,
      questions: exam.questions.map((question) => ({
        id: question.id,
        questionText: question.questionText,
        optionA: question.optionA,
        optionB: question.optionB,
        optionC: question.optionC,
        optionD: question.optionD,
        orderIndex: question.orderIndex,
      })),
    };
  }

  async examResults(userId: string, examId: string) {
    await this.assertExamOwner(userId, examId);
    const attempts = await this.prisma.examAttempt.findMany({
      where: {
        examId,
        status: { not: 'IN_PROGRESS' },
      },
      include: {
        examinee: { include: { profile: true } },
      },
      orderBy: { startedAt: 'desc' },
    });

    const grouped = new Map<string, typeof attempts>();
    for (const attempt of attempts) {
      const list = grouped.get(attempt.examineeId) ?? [];
      list.push(attempt);
      grouped.set(attempt.examineeId, list);
    }

    return [...grouped.entries()].map(([examineeId, items]) => {
      const sorted = [...items].sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime());
      const latest = sorted[0];
      const best = sorted.reduce((prev, curr) =>
        Number(curr.finalScore) > Number(prev.finalScore) ? curr : prev,
      );
      return {
        examineeId,
        examinee: latest.examinee.profile,
        attemptCount: sorted.length,
        latestAttempt: latest,
        bestScore: Number(best.finalScore),
        attempts: sorted,
      };
    });
  }

  private async assertExamOwner(userId: string, examId: string) {
    const exam = await this.prisma.exam.findUnique({ where: { id: examId } });
    if (!exam) {
      throw new NotFoundException('Exam not found.');
    }
    if (exam.createdById !== userId) {
      throw new ForbiddenException('You do not own this exam.');
    }
    return exam;
  }

  private async resolveAssignments(userId: string, visibility: ExamVisibility, requestedIds: string[]) {
    if (visibility === ExamVisibility.PUBLIC) {
      return [];
    }
    const acceptedFriendIds = await this.getAcceptedExamineeFriendIds(userId);
    if (visibility === ExamVisibility.ALL_FRIENDS) {
      return acceptedFriendIds;
    }

    const invalidIds = requestedIds.filter((id) => !acceptedFriendIds.includes(id));
    if (invalidIds.length > 0) {
      throw new BadRequestException('Selected examinees must already be accepted friends of the examiner.');
    }
    return requestedIds;
  }

  private async getAcceptedExamineeFriendIds(userId: string) {
    const requests = await this.prisma.friendRequest.findMany({
      where: {
        status: FriendRequestStatus.ACCEPTED,
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      include: {
        sender: true,
        receiver: true,
      },
    });

    const ids = requests.map((request) => (request.senderId === userId ? request.receiverId : request.senderId));
    const examinees = await this.prisma.user.findMany({
      where: {
        id: { in: ids },
        role: UserRole.EXAMINEE,
      },
      select: { id: true },
    });
    return examinees.map((user) => user.id);
  }
}
