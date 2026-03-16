import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Roles, RolesGuard } from 'src/common/guards/roles.guard';
import { SaveAnswerDto } from './dto/save-answer.dto';
import { StartAttemptDto } from './dto/start-attempt.dto';
import { AttemptsService } from './attempts.service';

@Controller('attempts')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('EXAMINEE')
export class AttemptsController {
  constructor(private readonly attemptsService: AttemptsService) {}

  @Post('start')
  start(@CurrentUser() user: JwtUser, @Body() dto: StartAttemptDto) {
    return this.attemptsService.start(user.sub, dto);
  }

  @Get(':id/questions')
  questions(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.attemptsService.questions(user.sub, id);
  }

  @Post(':id/answer')
  saveAnswer(@CurrentUser() user: JwtUser, @Param('id') id: string, @Body() dto: SaveAnswerDto) {
    return this.attemptsService.saveAnswer(user.sub, id, dto);
  }

  @Post(':id/submit')
  submit(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.attemptsService.submit(user.sub, id);
  }
}
