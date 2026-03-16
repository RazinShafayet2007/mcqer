import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Roles, RolesGuard } from 'src/common/guards/roles.guard';
import { CreateExamDto } from './dto/create-exam.dto';
import { UpdateExamDto } from './dto/update-exam.dto';
import { ExamsService } from './exams.service';

@Controller('exams')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ExamsController {
  constructor(private readonly examsService: ExamsService) {}

  @Post()
  @Roles('EXAMINER')
  create(@CurrentUser() user: JwtUser, @Body() dto: CreateExamDto) {
    return this.examsService.createExam(user.sub, dto);
  }

  @Patch(':id')
  @Roles('EXAMINER')
  update(@CurrentUser() user: JwtUser, @Param('id') id: string, @Body() dto: UpdateExamDto) {
    return this.examsService.updateExam(user.sub, id, dto);
  }

  @Patch(':id/publish')
  @Roles('EXAMINER')
  publish(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.examsService.publishExam(user.sub, id);
  }

  @Get('my')
  @Roles('EXAMINER')
  my(@CurrentUser() user: JwtUser) {
    return this.examsService.myExams(user.sub);
  }

  @Get('available')
  @Roles('EXAMINEE')
  available(@CurrentUser() user: JwtUser) {
    return this.examsService.availableExams(user.sub);
  }

  @Get(':id/results')
  @Roles('EXAMINER')
  results(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.examsService.examResults(user.sub, id);
  }

  @Get(':id')
  detail(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.examsService.examDetail(user.sub, id);
  }
}
