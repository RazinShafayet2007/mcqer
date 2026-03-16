import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { OptionLabel } from '@prisma/client';

import { PrismaService } from 'src/infra/prisma/prisma.service';

import { ImportQuestionsDto } from './dto/import-questions.dto';

@Injectable()
export class ParserService {
  constructor(private readonly prisma: PrismaService) {}

  async importQuestions(userId: string, examId: string, dto: ImportQuestionsDto) {
    const exam = await this.prisma.exam.findUnique({ where: { id: examId } });
    if (!exam) {
      throw new NotFoundException('Exam not found.');
    }
    if (exam.createdById !== userId) {
      throw new ForbiddenException('You do not own this exam.');
    }

    const parsed = this.parseRawText(dto.rawText);

    await this.prisma.$transaction([
      this.prisma.question.deleteMany({ where: { examId } }),
      this.prisma.question.createMany({
        data: parsed.valid.map((item, index) => ({
          examId,
          questionText: item.questionText,
          optionA: item.options[0],
          optionB: item.options[1],
          optionC: item.options[2],
          optionD: item.options[3],
          correctOption: item.correctOption,
          orderIndex: index + 1,
        })),
      }),
      this.prisma.parserImportLog.create({
        data: {
          examId,
          rawInputText: dto.rawText,
          parsedCount: parsed.valid.length,
          failedCount: parsed.invalid.length,
        },
      }),
    ]);

    return parsed;
  }

  private parseRawText(rawText: string) {
    const blocks = rawText
      .split(/\n\s*\n/)
      .map((block) => block.trim())
      .filter(Boolean);

    const valid: Array<{ questionText: string; options: [string, string, string, string]; correctOption: OptionLabel }> = [];
    const invalid: string[] = [];

    for (const block of blocks) {
      const lines = block.split('\n').map((line) => line.trim()).filter(Boolean);
      const questionLine = lines.find((line) => /^\d+[.)]/.test(line));
      const options = lines.filter((line) => /^[A-D][.):]/i.test(line));
      const answerLine = lines.find((line) => /^(Answer|Ans|Correct Answer)\s*:/i.test(line));

      if (!questionLine || options.length !== 4 || !answerLine) {
        invalid.push(block);
        continue;
      }

      const answerMatch = answerLine.match(/([A-D])\s*$/i);
      if (!answerMatch) {
        invalid.push(block);
        continue;
      }

      valid.push({
        questionText: questionLine.replace(/^\d+[.)]\s*/, ''),
        options: options.map((line) => line.replace(/^[A-D][.):]\s*/i, '')) as [string, string, string, string],
        correctOption: answerMatch[1].toUpperCase() as OptionLabel,
      });
    }

    return { valid, invalid };
  }
}
