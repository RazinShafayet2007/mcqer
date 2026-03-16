import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { envValidationSchema } from './config/env.validation';
import { AuthModule } from './modules/auth/auth.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { UsersModule } from './modules/users/users.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { FriendsModule } from './modules/friends/friends.module';
import { ExamsModule } from './modules/exams/exams.module';
import { ParserModule } from './modules/parser/parser.module';
import { AttemptsModule } from './modules/attempts/attempts.module';
import { ResultsModule } from './modules/results/results.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { StorageModule } from './infra/storage/storage.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      validationSchema: envValidationSchema,
    }),
    PrismaModule,
    RedisModule,
    StorageModule,
    AuthModule,
    UsersModule,
    ProfilesModule,
    UploadsModule,
    FriendsModule,
    ExamsModule,
    ParserModule,
    AttemptsModule,
    ResultsModule,
    AnalyticsModule,
  ],
})
export class AppModule {}
