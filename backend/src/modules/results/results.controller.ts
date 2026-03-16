import { Controller, Get, Param, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { ResultsService } from './results.service';

@Controller('attempts')
@UseGuards(JwtAuthGuard)
export class ResultsController {
  constructor(private readonly resultsService: ResultsService) {}

  @Get(':id/result')
  result(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.resultsService.attemptResult(user.sub, id);
  }
}
