import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/exam_widgets.dart';
import '../data/app_state.dart';
import '../domain/models.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  const ExamDetailScreen({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).refreshExamDetail(widget.examId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appStateProvider.notifier);
    final exam = controller.examById(widget.examId);
    final isExaminer = state.role == UserRole.examiner;
    final latestAttempt = isExaminer ? null : controller.latestCompletedAttemptForExam(exam.id);
    final histories = isExaminer ? controller.attemptHistoryForExam(exam.id) : const <ExamineeAttemptHistory>[];

    return Scaffold(
      body: AppShell(
        title: exam.title,
        subtitle: exam.description,
        actions: [
          OutlinedButton(
            onPressed: () => context.go(isExaminer ? '/examiner' : '/examinee'),
            child: Text(isExaminer ? 'Back to studio' : 'Back to hall'),
          ),
          if (isExaminer) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                controller.switchRole(UserRole.examinee);
                context.go('/examinee');
              },
              child: const Text('Examinee mode'),
            ),
          ],
        ],
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
                MetricCard(label: 'Questions', value: '${exam.questions.length}', tone: AppColors.gold),
                MetricCard(label: 'Duration', value: '${exam.durationMinutes}m', tone: AppColors.emerald),
                MetricCard(label: 'Penalty', value: '-${exam.negativeMarkPerWrong}', tone: AppColors.coral),
                MetricCard(label: 'State', value: exam.isPublished ? 'Live' : 'Draft', tone: AppColors.ice),
              ],
            ),
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isExaminer ? 'Examiner controls' : 'Exam instructions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    isExaminer
                        ? 'Review question quality, then publish when the paper is ready for examinees.'
                        : latestAttempt == null
                            ? 'Timer starts from the server-derived attempt window. Correct answers remain hidden until scoring.'
                            : 'You can retake this exam any time. Your latest completed attempt stays available for review.',
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (isExaminer) {
                            await controller.publishExam(exam.id);
                            if (!mounted) return;
                            await controller.refreshExamDetail(exam.id);
                          } else {
                            final attempt = await controller.startAttempt(exam.id);
                            if (!mounted || attempt == null) return;
                            context.go('/attempt/${attempt.id}');
                          }
                        },
                        child: Text(isExaminer ? (exam.isPublished ? 'Published' : 'Publish exam') : latestAttempt == null ? 'Start exam' : 'Retake exam'),
                      ),
                      if (!isExaminer && latestAttempt != null)
                        OutlinedButton(
                          onPressed: () => context.go('/result/${latestAttempt.id}'),
                          child: const Text('View latest result'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExaminer) ...[
              const SizedBox(height: 24),
              SectionHeading(
                title: 'Examinee results',
                subtitle: histories.isEmpty ? 'No one has completed this exam yet.' : 'Track who attempted this exam, how many times they took it, and their latest and best scores.',
              ),
              const SizedBox(height: 16),
              if (histories.isEmpty) const GlassPanel(child: Text('No completed attempts yet. Publish the exam and let examinees start taking it.')),
              ...histories.map((history) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(history.examineeName, style: Theme.of(context).textTheme.titleLarge)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                                child: Text('${history.attempts.length} attempt(s)'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _ExaminerStatPill(label: 'Latest score', value: history.latestSummary.finalScore.toStringAsFixed(2)),
                              _ExaminerStatPill(label: 'Best score', value: history.bestScore.toStringAsFixed(2)),
                              _ExaminerStatPill(label: 'Correct', value: '${history.latestSummary.correctCount}'),
                              _ExaminerStatPill(label: 'Wrong', value: '${history.latestSummary.wrongCount}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              const SectionHeading(
                title: 'Question preview',
                subtitle: 'Only the examiner can inspect prompts, options, and hidden answers before publishing.',
              ),
              const SizedBox(height: 16),
              ...exam.questions.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q${entry.key + 1}. ${entry.value.prompt}', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          ...entry.value.options.asMap().entries.map((option) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('${'ABCD'[option.key]}. ${option.value}${option.key == entry.value.correctIndex ? '  (hidden answer)' : ''}'),
                              )),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExaminerStatPill extends StatelessWidget {
  const _ExaminerStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
      child: Text('$label: $value'),
    );
  }
}
