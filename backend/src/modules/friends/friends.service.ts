import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FriendRequestStatus, UserRole } from '@prisma/client';

import { PrismaService } from 'src/infra/prisma/prisma.service';

import { CreateFriendRequestDto } from './dto/create-friend-request.dto';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  async suggestions(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    const oppositeRole = user.role === UserRole.EXAMINER ? UserRole.EXAMINEE : UserRole.EXAMINER;
    const requests = await this.prisma.friendRequest.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      select: { senderId: true, receiverId: true, status: true },
    });

    const excludedIds = new Set<string>([userId]);
    for (const request of requests) {
      if (request.status === FriendRequestStatus.PENDING || request.status === FriendRequestStatus.ACCEPTED) {
        excludedIds.add(request.senderId);
        excludedIds.add(request.receiverId);
      }
    }

    return this.prisma.user.findMany({
      where: {
        role: oppositeRole,
        id: { notIn: [...excludedIds] },
      },
      include: { profile: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  incoming(userId: string) {
    return this.prisma.friendRequest.findMany({
      where: { receiverId: userId, status: FriendRequestStatus.PENDING },
      include: {
        sender: { include: { profile: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  outgoing(userId: string) {
    return this.prisma.friendRequest.findMany({
      where: { senderId: userId },
      include: {
        receiver: { include: { profile: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createRequest(userId: string, dto: CreateFriendRequestDto) {
    if (userId === dto.receiverId) {
      throw new BadRequestException('Cannot send a friend request to yourself.');
    }
    const [sender, receiver] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.user.findUnique({ where: { id: dto.receiverId } }),
    ]);
    if (!sender || !receiver) {
      throw new NotFoundException('User not found.');
    }
    if (sender.role === receiver.role) {
      throw new ForbiddenException('Friend requests must be cross-role only.');
    }

    const existing = await this.prisma.friendRequest.findFirst({
      where: {
        OR: [
          { senderId: userId, receiverId: dto.receiverId },
          { senderId: dto.receiverId, receiverId: userId },
        ],
      },
    });
    if (existing) {
      throw new BadRequestException('A friend request or friendship already exists between these users.');
    }

    return this.prisma.friendRequest.create({
      data: {
        senderId: userId,
        receiverId: dto.receiverId,
      },
    });
  }

  async acceptRequest(userId: string, requestId: string) {
    const request = await this.prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request) {
      throw new NotFoundException('Friend request not found.');
    }
    if (request.receiverId !== userId) {
      throw new ForbiddenException('Only the receiver can accept this request.');
    }

    return this.prisma.friendRequest.update({
      where: { id: requestId },
      data: {
        status: FriendRequestStatus.ACCEPTED,
        acceptedAt: new Date(),
      },
    });
  }

  async listFriends(userId: string) {
    const requests = await this.prisma.friendRequest.findMany({
      where: {
        status: FriendRequestStatus.ACCEPTED,
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      include: {
        sender: { include: { profile: true } },
        receiver: { include: { profile: true } },
      },
    });

    return requests.map((request) => (request.senderId === userId ? request.receiver : request.sender));
  }
}
