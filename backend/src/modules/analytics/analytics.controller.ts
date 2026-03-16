import { Controller, Get, Param, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Roles, RolesGuard } from 'src/common/guards/roles.guard';
import { AnalyticsService } from './analytics.service';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('EXAMINER')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('dashboard/stats')
  dashboard(@CurrentUser() user: JwtUser) {
    return this.analyticsService.dashboardStats(user.sub);
  }

  @Get('exams/:id/attempts')
  examAttempts(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.analyticsService.examAttempts(user.sub, id);
  }

  @Get('users/:id/history')
  userHistory(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.analyticsService.userHistory(user.sub, id);
  }
}
