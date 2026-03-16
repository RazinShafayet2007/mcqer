# MCQer Backend Plan

Recommended stack:

- NestJS
- Prisma
- PostgreSQL
- Redis
- S3-compatible object storage

## Status

Already scaffolded:

- NestJS project config
- Prisma schema
- app bootstrap and env validation
- JWT strategy and auth module skeleton
- users, profiles, uploads, friends, exams, parser, attempts, results, analytics module skeletons
- `.env.example`

Verified locally:

- `npm install`
- `npm run build`
- `npx prisma generate`

## Local setup commands

```bash
cd backend
cp .env.example .env
docker compose up -d
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run build
npm run start:dev
```

## What is already done

- project scaffold and module wiring
- Prisma schema for all current features
- JWT auth/register/login/refresh service logic
- profile persistence logic
- friend request and friendship logic
- exam creation/update/publish/availability logic
- parser import and question persistence logic
- attempt start/question fetch/answer save/submit scoring logic
- result review payloads
- analytics payloads
- local Postgres and Redis compose file

## What is still needed from you

- real values in `.env` for:
  - `JWT_ACCESS_SECRET`
  - `JWT_REFRESH_SECRET`
  - `S3_ENDPOINT`
  - `S3_ACCESS_KEY`
  - `S3_SECRET_KEY`
  - `S3_BUCKET`
  - `APP_BASE_URL`
- optionally replace local `DATABASE_URL` and `REDIS_URL` if you are not using the provided Docker setup

Once those values are filled, the remaining work is operational:

- run migrations
- boot the server
- test endpoints against the real services

## Module layout

```text
backend/
  prisma/
    schema.prisma
  src/
    main.ts
    app.module.ts
    config/
      env.validation.ts
    common/
      decorators/
      guards/
      interceptors/
      filters/
      pipes/
      utils/
    modules/
      auth/
        auth.module.ts
        auth.controller.ts
        auth.service.ts
        dto/
      users/
        users.module.ts
        users.controller.ts
        users.service.ts
        dto/
      profiles/
        profiles.module.ts
        profiles.controller.ts
        profiles.service.ts
        dto/
      uploads/
        uploads.module.ts
        uploads.controller.ts
        uploads.service.ts
      friends/
        friends.module.ts
        friends.controller.ts
        friends.service.ts
        dto/
      exams/
        exams.module.ts
        exams.controller.ts
        exams.service.ts
        dto/
      parser/
        parser.module.ts
        parser.controller.ts
        parser.service.ts
        dto/
      attempts/
        attempts.module.ts
        attempts.controller.ts
        attempts.service.ts
        dto/
      results/
        results.module.ts
        results.controller.ts
        results.service.ts
      analytics/
        analytics.module.ts
        analytics.controller.ts
        analytics.service.ts
    infra/
      prisma/
      redis/
      storage/
      queue/
```

## ER map

```text
User 1---1 Profile
User 1---* Exam(created_by)
User 1---* FriendRequest(sender)
User 1---* FriendRequest(receiver)
User 1---* ExamAssignment(examinee)
User 1---* ExamAttempt(examinee)

Exam 1---* Question
Exam 1---* ExamAssignment
Exam 1---* ExamAttempt
Exam 1---* ParserImportLog

ExamAttempt 1---* ExamAnswer
Question 1---* ExamAnswer
```

## Product rules

- Only `examiner -> examinee` or `examinee -> examiner` friend requests are valid
- Only accepted friends can be targeted in friend-only exams
- `PUBLIC` exams are visible to all examinees
- `ALL_FRIENDS` exams are visible to all accepted examinee friends of the creator
- `SELECTED_FRIENDS` exams are visible only to assigned examinees
- Retakes are unlimited by default; each retake creates a new attempt row
- Correct answers never leave examiner/result-safe APIs before submission
- Timer is enforced from server timestamps, never client time

## Things you need to bring

- PostgreSQL database connection string
- Redis connection string
- S3/R2 bucket credentials for profile image uploads
- JWT secrets
- Real MCQ text samples for parser hardening
- Final decision on auth method if you want anything other than email/password
