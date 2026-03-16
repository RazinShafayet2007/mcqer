import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtUser } from 'src/common/decorators/current-user.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { CreateFriendRequestDto } from './dto/create-friend-request.dto';
import { FriendsService } from './friends.service';

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get('suggestions')
  suggestions(@CurrentUser() user: JwtUser) {
    return this.friendsService.suggestions(user.sub);
  }

  @Get('requests/incoming')
  incoming(@CurrentUser() user: JwtUser) {
    return this.friendsService.incoming(user.sub);
  }

  @Get('requests/outgoing')
  outgoing(@CurrentUser() user: JwtUser) {
    return this.friendsService.outgoing(user.sub);
  }

  @Post('requests')
  createRequest(@CurrentUser() user: JwtUser, @Body() dto: CreateFriendRequestDto) {
    return this.friendsService.createRequest(user.sub, dto);
  }

  @Post('requests/:id/accept')
  acceptRequest(@CurrentUser() user: JwtUser, @Param('id') id: string) {
    return this.friendsService.acceptRequest(user.sub, id);
  }

  @Get()
  friends(@CurrentUser() user: JwtUser) {
    return this.friendsService.listFriends(user.sub);
  }
}
