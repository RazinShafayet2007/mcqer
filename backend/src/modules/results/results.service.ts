import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from 'src/infra/prisma/prisma.service';

@Injectable()
export class ResultsService {
  constructor(private readonly prisma: PrismaService) {}

  async attemptResult(userId: string, attemptId: string) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: {
        exam: {
          include: {
            questions: {
              orderBy: { orderIndex: 'asc' },
            },
          },
        },
        answers: true,
      },
    });
    if (!attempt) {
      throw new NotFoundException('Attempt not found.');
    }
    if (attempt.examineeId !== userId) {
      throw new ForbiddenException('Not allowed to view this result.');
    }

    return {
      id: attempt.id,
      examId: attempt.examId,
      status: attempt.status,
      startedAt: attempt.startedAt,
      submittedAt: attempt.submittedAt,
      summary: {
        correctCount: attempt.correctCount,
        wrongCount: attempt.wrongCount,
        unansweredCount: attempt.unansweredCount,
        negativeMarks: Number(attempt.negativeMarks),
        finalScore: Number(attempt.finalScore),
      },
      questions: attempt.exam.questions.map((question) => {
        const answer = attempt.answers.find((item) => item.questionId === question.id);
        return {
          id: question.id,
          questionText: question.questionText,
          options: {
            A: question.optionA,
            B: question.optionB,
            C: question.optionC,
            D: question.optionD,
          },
          selectedOption: answer?.selectedOption ?? null,
          correctOption: question.correctOption,
          isCorrect: answer?.isCorrect ?? null,
        };
      }),
    };
  }
}
