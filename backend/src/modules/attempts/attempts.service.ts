import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AttemptStatus, ExamVisibility, OptionLabel, Prisma } from '@prisma/client';

import { PrismaService } from 'src/infra/prisma/prisma.service';

import { SaveAnswerDto } from './dto/save-answer.dto';
import { StartAttemptDto } from './dto/start-attempt.dto';

@Injectable()
export class AttemptsService {
  constructor(private readonly prisma: PrismaService) {}

  async start(userId: string, dto: StartAttemptDto) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: dto.examId },
      include: { assignments: true },
    });
    if (!exam || !exam.isPublished) {
      throw new NotFoundException('Exam not found.');
    }
    if (exam.visibility !== ExamVisibility.PUBLIC && !exam.assignments.some((item) => item.examineeId === userId)) {
      throw new ForbiddenException('This exam is not assigned to you.');
    }

    const startedAt = new Date();
    const endAt = new Date(startedAt.getTime() + exam.durationMinutes * 60 * 1000);
    return this.prisma.examAttempt.create({
      data: {
        examId: dto.examId,
        examineeId: userId,
        startedAt,
        endAt,
      },
    });
  }

  async questions(userId: string, attemptId: string) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: { exam: { include: { questions: { orderBy: { orderIndex: 'asc' } } } }, answers: true },
    });
    if (!attempt) {
      throw new NotFoundException('Attempt not found.');
    }
    if (attempt.examineeId !== userId) {
      throw new ForbiddenException('Not your attempt.');
    }

    return {
      attemptId: attempt.id,
      startedAt: attempt.startedAt,
      endAt: attempt.endAt,
      status: attempt.status,
      questions: attempt.exam.questions.map((question) => ({
        id: question.id,
        questionText: question.questionText,
        options: {
          A: question.optionA,
          B: question.optionB,
          C: question.optionC,
          D: question.optionD,
        },
        selectedOption: attempt.answers.find((answer) => answer.questionId === question.id)?.selectedOption ?? null,
      })),
    };
  }

  async saveAnswer(userId: string, attemptId: string, dto: SaveAnswerDto) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: { exam: true },
    });
    if (!attempt) {
      throw new NotFoundException('Attempt not found.');
    }
    if (attempt.examineeId !== userId) {
      throw new ForbiddenException('Not your attempt.');
    }
    if (attempt.status !== AttemptStatus.IN_PROGRESS) {
      throw new BadRequestException('Attempt is already submitted.');
    }
    if (attempt.endAt.getTime() < Date.now()) {
      throw new BadRequestException('Attempt time has expired. Submit instead.');
    }

    return this.prisma.examAnswer.upsert({
      where: {
        attemptId_questionId: {
          attemptId,
          questionId: dto.questionId,
        },
      },
      update: {
        selectedOption: dto.selectedOption as OptionLabel,
        submittedAt: new Date(),
      },
      create: {
        attemptId,
        questionId: dto.questionId,
        selectedOption: dto.selectedOption as OptionLabel,
        submittedAt: new Date(),
      },
    });
  }

  async submit(userId: string, attemptId: string) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: {
        exam: { include: { questions: { orderBy: { orderIndex: 'asc' } } } },
        answers: true,
      },
    });
    if (!attempt) {
      throw new NotFoundException('Attempt not found.');
    }
    if (attempt.examineeId !== userId) {
      throw new ForbiddenException('Not your attempt.');
    }
    if (attempt.status !== AttemptStatus.IN_PROGRESS) {
      return attempt;
    }

    let correctCount = 0;
    let wrongCount = 0;
    let unansweredCount = 0;

    const updates = attempt.exam.questions.map((question) => {
      const answer = attempt.answers.find((item) => item.questionId === question.id);
      if (!answer?.selectedOption) {
        unansweredCount += 1;
        return this.prisma.examAnswer.upsert({
          where: { attemptId_questionId: { attemptId, questionId: question.id } },
          update: { isCorrect: null, marksAwarded: new Prisma.Decimal(0) },
          create: { attemptId, questionId: question.id, isCorrect: null, marksAwarded: new Prisma.Decimal(0) },
        });
      }

      const isCorrect = answer.selectedOption === question.correctOption;
      if (isCorrect) {
        correctCount += 1;
      } else {
        wrongCount += 1;
      }

      return this.prisma.examAnswer.update({
        where: { attemptId_questionId: { attemptId, questionId: question.id } },
        data: {
          isCorrect,
          marksAwarded: new Prisma.Decimal(isCorrect ? Number(question.marksPerQuestion) : 0 - Number(attempt.exam.negativeMarkPerWrong)),
        },
      });
    });

    const negativeMarks = wrongCount * Number(attempt.exam.negativeMarkPerWrong);
    const finalScore = correctCount - negativeMarks;

    await this.prisma.$transaction([
      ...updates,
      this.prisma.examAttempt.update({
        where: { id: attemptId },
        data: {
          submittedAt: new Date(),
          status: AttemptStatus.COMPLETED,
          correctCount,
          wrongCount,
          unansweredCount,
          negativeMarks: new Prisma.Decimal(negativeMarks),
          finalScore: new Prisma.Decimal(finalScore),
        },
      }),
    ]);

    return this.prisma.examAttempt.findUniqueOrThrow({
      where: { id: attemptId },
      include: { answers: true },
    });
  }
}
