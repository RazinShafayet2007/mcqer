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

class ExamineeDashboardScreen extends ConsumerWidget {
  const ExamineeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final liveExams = ref.read(appStateProvider.notifier).visibleExamsForCurrentUser();
    final user = ref.read(appStateProvider.notifier).currentUser;
    final completedCount = liveExams.where((exam) => ref.read(appStateProvider.notifier).isCompleted(exam.id)).length;
    final showExaminerToggle = state.entryRole == UserRole.examiner;

    return Scaffold(
      body: AppShell(
        title: 'Examinee Hall',
        subtitle: 'Pick a live paper, watch the timer, and get instant scoring with negative marking applied.',
        actions: showExaminerToggle
            ? [
                OutlinedButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Profile'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    ref.read(appStateProvider.notifier).switchRole(UserRole.examiner);
                    context.go('/examiner');
                  },
                  child: const Text('Examiner mode'),
                ),
              ]
            : [
                OutlinedButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Profile'),
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
                MetricCard(label: 'Live exams', value: '${liveExams.length}', tone: AppColors.gold),
                MetricCard(label: 'Completed', value: '$completedCount', tone: AppColors.emerald),
                const MetricCard(label: 'Negative rule', value: '-0.25', tone: AppColors.coral),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Available exams',
              subtitle: 'Published exams only. Hidden answers never leave the examiner-safe state layer.',
            ),
            const SizedBox(height: 16),
            ...liveExams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ExamCard(
                  exam: exam,
                  badge: ref.read(appStateProvider.notifier).isCompleted(exam.id) ? 'Completed' : 'Open',
                  onTap: () => context.go('/examinee/exam/${exam.id}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FriendsSection(
              title: 'Examiner connections',
              suggestionTitle: 'Suggested examiners',
              incomingTitle: 'Incoming requests',
              friendTitle: 'Accepted examiner friends',
            ),
          ],
        ),
      ),
    );
  }
}
