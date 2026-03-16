# MCQer Frontend

Flutter frontend scaffold for a role-based online exam platform with:

- examiner and examinee flows
- parser preview for pasted MCQs
- draft and publish exam states
- timed exam-taking UI
- negative-marking result summary
- premium dark editorial design system

## Structure

- `lib/core` - router, theme, reusable shell/widgets
- `lib/features/auth` - role selection and login
- `lib/features/exams` - exam state, parser, dashboards, creation, detail views
- `lib/features/attempts` - timed attempt and result screens

## Packages

- `flutter_riverpod`
- `go_router`
- `google_fonts`

## Run

1. Install Flutter SDK.
2. From this directory run `flutter pub get`.
3. Generate platform folders if needed with `flutter create .`.
4. Launch with `flutter run`.

## Notes

- Data is mock in-memory state for now.
- Correct answers are intentionally only referenced in examiner/result logic.
- Backend integration can plug into the current Riverpod state layer later.
