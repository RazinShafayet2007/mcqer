import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attempts/presentation/attempt_screen.dart';
import '../../features/attempts/presentation/result_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/exams/presentation/examinee_dashboard_screen.dart';
import '../../features/exams/presentation/examiner_dashboard_screen.dart';
import '../../features/exams/presentation/create_exam_screen.dart';
import '../../features/exams/presentation/exam_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/examiner',
        builder: (context, state) => const ExaminerDashboardScreen(),
      ),
      GoRoute(
        path: '/examiner/create',
        builder: (context, state) => const CreateExamScreen(),
      ),
      GoRoute(
        path: '/examiner/exam/:examId',
        builder: (context, state) => ExamDetailScreen(examId: state.pathParameters['examId']!),
      ),
      GoRoute(
        path: '/examinee',
        builder: (context, state) => const ExamineeDashboardScreen(),
      ),
      GoRoute(
        path: '/examinee/exam/:examId',
        builder: (context, state) => ExamDetailScreen(examId: state.pathParameters['examId']!),
      ),
      GoRoute(
        path: '/attempt/:attemptId',
        builder: (context, state) => AttemptScreen(attemptId: state.pathParameters['attemptId']!),
      ),
      GoRoute(
        path: '/result/:attemptId',
        builder: (context, state) => ResultScreen(attemptId: state.pathParameters['attemptId']!),
      ),
    ],
  );
});
