import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/exam_widgets.dart';
import '../../exams/data/app_state.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appStateProvider.notifier);
    final attempt = controller.attemptById(attemptId);
    final exam = controller.examById(attempt.examId);
    final summary = controller.summaryForAttempt(attemptId);

    return Scaffold(
      body: AppShell(
        title: 'Result Vault',
        subtitle: 'Final marks, negative deductions, and completion state are calculated from hidden answer data.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: [
                MetricCard(label: 'Final score', value: summary.finalScore.toStringAsFixed(2), tone: AppColors.gold),
                MetricCard(label: 'Correct', value: '${summary.correctCount}', tone: AppColors.emerald),
                MetricCard(label: 'Wrong', value: '${summary.wrongCount}', tone: AppColors.coral),
                MetricCard(label: 'Unanswered', value: '${summary.unansweredCount}', tone: AppColors.ice),
              ],
            ),
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text('Negative marks deducted: ${summary.negativeDeduction.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Completion status: ${attempt.status.name}'),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final newAttempt = controller.startAttempt(exam.id);
                          context.go('/attempt/${newAttempt.id}');
                        },
                        child: const Text('Retake exam'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/examinee'),
                        child: const Text('Back to exam hall'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Answer review',
              subtitle: 'Each question shows what the examinee picked and whether it was correct, wrong, or unanswered.',
            ),
            const SizedBox(height: 16),
            ...exam.questions.asMap().entries.map((entry) {
              final question = entry.value;
              final selectedIndex = attempt.answers[question.id];
              final status = _resultStatusFor(question.correctIndex, selectedIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Q${entry.key + 1}. ${question.prompt}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          _StatusBadge(status: status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...question.options.asMap().entries.map((option) {
                        final isSelected = selectedIndex == option.key;
                        final isCorrect = question.correctIndex == option.key;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _optionTone(status, isSelected, isCorrect),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _optionBorder(status, isSelected, isCorrect),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text('${'ABCD'[option.key]}. ${option.value}')),
                                if (isCorrect)
                                  const Text('Correct answer')
                                else if (isSelected)
                                  const Text('Your answer'),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  _ReviewStatus _resultStatusFor(int correctIndex, int? selectedIndex) {
    if (selectedIndex == null) {
      return _ReviewStatus.unanswered;
    }
    if (selectedIndex == correctIndex) {
      return _ReviewStatus.correct;
    }
    return _ReviewStatus.wrong;
  }
}

enum _ReviewStatus { correct, wrong, unanswered }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _badgeColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(_label(status)),
    );
  }

  String _label(_ReviewStatus status) {
    switch (status) {
      case _ReviewStatus.correct:
        return 'Correct';
      case _ReviewStatus.wrong:
        return 'Wrong';
      case _ReviewStatus.unanswered:
        return 'Unanswered';
    }
  }

  Color _badgeColor(_ReviewStatus status) {
    switch (status) {
      case _ReviewStatus.correct:
        return AppColors.emerald.withValues(alpha: 0.24);
      case _ReviewStatus.wrong:
        return AppColors.coral.withValues(alpha: 0.24);
      case _ReviewStatus.unanswered:
        return AppColors.ice.withValues(alpha: 0.2);
    }
  }
}

Color _optionTone(_ReviewStatus status, bool isSelected, bool isCorrect) {
  if (isCorrect) {
    return AppColors.emerald.withValues(alpha: 0.16);
  }
  if (isSelected && status == _ReviewStatus.wrong) {
    return AppColors.coral.withValues(alpha: 0.14);
  }
  return Colors.white.withValues(alpha: 0.04);
}

Color _optionBorder(_ReviewStatus status, bool isSelected, bool isCorrect) {
  if (isCorrect) {
    return AppColors.emerald.withValues(alpha: 0.55);
  }
  if (isSelected && status == _ReviewStatus.wrong) {
    return AppColors.coral.withValues(alpha: 0.55);
  }
  if (isSelected) {
    return AppColors.gold.withValues(alpha: 0.35);
  }
  return Colors.white.withValues(alpha: 0.08);
}
