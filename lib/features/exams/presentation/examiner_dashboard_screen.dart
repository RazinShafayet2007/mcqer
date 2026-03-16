import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/exam_widgets.dart';
import '../data/app_state.dart';
import '../domain/models.dart';
import 'friends_section.dart';
import '../../profile/presentation/profile_banner.dart';

class ExaminerDashboardScreen extends ConsumerWidget {
  const ExaminerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final exams = state.exams;
    final user = ref.read(appStateProvider.notifier).currentUser;
    final published = exams.where((exam) => exam.isPublished).length;
    final drafts = exams.length - published;
    final attempts = state.attempts.where((attempt) => attempt.status != AttemptStatus.inProgress).length;

    return Scaffold(
      body: AppShell(
        title: 'Examiner Studio',
        subtitle: 'Shape question banks, preview parser output, and control publishing from one premium console.',
        actions: [
          OutlinedButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Profile'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(appStateProvider.notifier).switchRole(UserRole.examinee);
              context.go('/examinee');
            },
            child: const Text('Examinee mode'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/examiner/create'),
            child: const Text('Create exam'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileBanner(user: user),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: [
                MetricCard(label: 'Exams total', value: '${exams.length}', tone: AppColors.gold),
                MetricCard(label: 'Published live', value: '$published', tone: AppColors.emerald),
                MetricCard(label: 'Completed attempts', value: '$attempts', tone: AppColors.coral),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Exam inventory',
              subtitle: 'Drafts stay private; published papers appear on the examinee side only.',
            ),
            const SizedBox(height: 16),
            if (drafts > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('$drafts draft exam(s) still awaiting publication. Publish one before switching to examinee mode if you want to take it.'),
              ),
            ...exams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ExamCard(
                  exam: exam,
                  badge: exam.isPublished ? 'Live' : 'Draft',
                  onTap: () => context.go('/examiner/exam/${exam.id}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FriendsSection(
              title: 'Examinee connections',
              suggestionTitle: 'Suggested examinees',
              incomingTitle: 'Incoming requests',
              friendTitle: 'Accepted examinee friends',
            ),
          ],
        ),
      ),
    );
  }
}
