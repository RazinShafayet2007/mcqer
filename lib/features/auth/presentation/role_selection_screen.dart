import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../exams/data/app_state.dart';
import '../../exams/domain/models.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppShell(
        title: 'MCQer',
        subtitle: 'Majestic exam operations for examiners, fast confidence for examinees.',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            final cards = [
              _RoleCard(
                title: 'Examiner',
                subtitle: 'Create timed exams, import MCQs, review parser previews, and publish safely.',
                actionLabel: 'Enter control room',
                onTap: () {
                  ref.read(appStateProvider.notifier).chooseRole(UserRole.examiner);
                  context.go('/login');
                },
              ),
              _RoleCard(
                title: 'Examinee',
                subtitle: 'Take polished timed assessments, track progress, and view final scoring instantly.',
                actionLabel: 'Start journey',
                onTap: () {
                  ref.read(appStateProvider.notifier).chooseRole(UserRole.examinee);
                  context.go('/login');
                },
              ),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlassPanel(
                  child: Text(
                    'Built for role-based testing: hidden answers, parser-driven creation, timer-safe delivery, and elegant reporting.',
                  ),
                ),
                const SizedBox(height: 24),
                wide
                    ? Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 18),
                          Expanded(child: cards[1]),
                        ],
                      )
                    : Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 18),
                          cards[1],
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(subtitle),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
