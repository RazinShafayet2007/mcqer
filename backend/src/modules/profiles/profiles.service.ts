import { BadRequestException, Injectable } from '@nestjs/common';

import { PrismaService } from 'src/infra/prisma/prisma.service';

import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const username = dto.username.trim().toLowerCase();
    const existing = await this.prisma.profile.findFirst({
      where: {
        username,
        NOT: { userId },
      },
    });
    if (existing) {
      throw new BadRequestException('Username already in use.');
    }

    return this.prisma.profile.upsert({
      where: { userId },
      update: {
        name: dto.name.trim(),
        username,
        bio: dto.bio?.trim(),
        headline: dto.headline?.trim(),
        profileImageUrl: dto.profileImageUrl ?? null,
      },
      create: {
        userId,
        name: dto.name.trim(),
        username,
        bio: dto.bio?.trim(),
        headline: dto.headline?.trim(),
        profileImageUrl: dto.profileImageUrl ?? null,
      },
    });
  }
}
