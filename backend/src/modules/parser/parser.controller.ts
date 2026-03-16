import { Body, Controller, Param, Post, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Roles, RolesGuard } from 'src/common/guards/roles.guard';
import { ImportQuestionsDto } from './dto/import-questions.dto';
import { ParserService } from './parser.service';

@Controller('exams')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ParserController {
  constructor(private readonly parserService: ParserService) {}

  @Post(':id/import-questions')
  @Roles('EXAMINER')
  importQuestions(@CurrentUser() user: JwtUser, @Param('id') id: string, @Body() dto: ImportQuestionsDto) {
    return this.parserService.importQuestions(user.sub, id, dto);
  }
}
