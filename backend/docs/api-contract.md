# API Contract

## Auth

- `POST /auth/register`
  - body: `RegisterDto`
  - returns: access token, refresh token, user summary
- `POST /auth/login`
  - body: `LoginDto`
  - returns: access token, refresh token, user summary
- `POST /auth/refresh`
  - body: `RefreshTokenDto`
- `POST /auth/logout`

## Profile

- `GET /me`
- `PATCH /me/profile`
  - body: `UpdateProfileDto`
- `POST /uploads/profile-image`
  - multipart file upload
  - returns: `fileKey`, `publicUrl`

## Friends

- `GET /friends/suggestions`
- `GET /friends/requests/incoming`
- `GET /friends/requests/outgoing`
- `POST /friends/requests`
  - body: `CreateFriendRequestDto`
- `POST /friends/requests/:id/accept`
- `GET /friends`

## Exams

- `POST /exams`
  - body: `CreateExamDto`
- `PATCH /exams/:id`
  - body: `UpdateExamDto`
- `PATCH /exams/:id/publish`
- `GET /exams/my`
- `GET /exams/available`
- `GET /exams/:id`
- `GET /exams/:id/results`

## Parser

- `POST /exams/:id/import-questions`
  - body: `ImportQuestionsDto`
  - returns: parser preview + validation summary

## Attempts

- `POST /attempts/start`
  - body: `StartAttemptDto`
- `GET /attempts/:id/questions`
- `POST /attempts/:id/answer`
  - body: `SaveAnswerDto`
- `POST /attempts/:id/submit`
- `GET /attempts/:id/result`

## Analytics

- `GET /dashboard/stats`
- `GET /exams/:id/attempts`
- `GET /users/:id/history`

## DTO list

### Auth

```ts
class RegisterDto {
  email: string
  password: string
  role: 'EXAMINER' | 'EXAMINEE'
  name: string
  username: string
}

class LoginDto {
  email: string
  password: string
}

class RefreshTokenDto {
  refreshToken: string
}
```

### Profile

```ts
class UpdateProfileDto {
  name: string
  username: string
  bio?: string
  headline?: string
  profileImageUrl?: string | null
}
```

### Friends

```ts
class CreateFriendRequestDto {
  receiverId: string
}
```

### Exams

```ts
class CreateExamDto {
  title: string
  description?: string
  durationMinutes: number
  negativeMarkPerWrong: number
  visibility: 'PUBLIC' | 'ALL_FRIENDS' | 'SELECTED_FRIENDS'
  assignedExamineeIds?: string[]
}

class UpdateExamDto {
  title?: string
  description?: string
  durationMinutes?: number
  negativeMarkPerWrong?: number
  visibility?: 'PUBLIC' | 'ALL_FRIENDS' | 'SELECTED_FRIENDS'
  assignedExamineeIds?: string[]
}

class ImportQuestionsDto {
  rawText: string
}
```

### Attempts

```ts
class StartAttemptDto {
  examId: string
}

class SaveAnswerDto {
  questionId: string
  selectedOption: 'A' | 'B' | 'C' | 'D'
}
```

## Response notes

- Examiner exam detail responses may include hidden answer data
- Examinee question responses must never include `correctOption`
- Result responses may include correct answers only after submission
