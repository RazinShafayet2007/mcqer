import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AttemptStatus } from '@prisma/client';

import { PrismaService } from 'src/infra/prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboardStats(userId: string) {
    const [examCount, publishedCount, attempts, profiles] = await Promise.all([
      this.prisma.exam.count({ where: { createdById: userId } }),
      this.prisma.exam.count({ where: { createdById: userId, isPublished: true } }),
      this.prisma.examAttempt.findMany({
        where: {
          exam: { createdById: userId },
          status: { not: AttemptStatus.IN_PROGRESS },
        },
      }),
      this.prisma.profile.count(),
    ]);

    const averageScore = attempts.length
      ? attempts.reduce((sum, attempt) => sum + Number(attempt.finalScore), 0) / attempts.length
      : 0;

    return {
      examCount,
      publishedCount,
      completedAttempts: attempts.length,
      averageScore,
      totalProfiles: profiles,
    };
  }

  async examAttempts(userId: string, examId: string) {
    const exam = await this.prisma.exam.findUnique({ where: { id: examId } });
    if (!exam) {
      throw new NotFoundException('Exam not found.');
    }
    if (exam.createdById !== userId) {
      throw new ForbiddenException('Not allowed to view exam analytics.');
    }

    const attempts = await this.prisma.examAttempt.findMany({
      where: {
        examId,
        status: { not: AttemptStatus.IN_PROGRESS },
      },
      include: {
        examinee: { include: { profile: true } },
      },
      orderBy: { startedAt: 'desc' },
    });

    return {
      examId,
      attemptCount: attempts.length,
      attempts,
    };
  }

  async userHistory(userId: string, targetUserId: string) {
    const attempts = await this.prisma.examAttempt.findMany({
      where: {
        examineeId: targetUserId,
        exam: { createdById: userId },
        status: { not: AttemptStatus.IN_PROGRESS },
      },
      include: {
        exam: true,
      },
      orderBy: { startedAt: 'desc' },
    });

    return {
      targetUserId,
      attemptCount: attempts.length,
      attempts,
    };
  }
}
