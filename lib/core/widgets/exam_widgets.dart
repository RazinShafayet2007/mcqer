import 'package:flutter/material.dart';

import '../../features/exams/domain/models.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.exam,
    required this.onTap,
    this.badge,
  });

  final Exam exam;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = exam.highlight.map(Color.new).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.night),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.night.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.night),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exam.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.night.withValues(alpha: 0.78)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(label: '${exam.questions.length} questions'),
                _Pill(label: '${exam.durationMinutes} min'),
                _Pill(label: '-${exam.negativeMarkPerWrong} wrong'),
                _Pill(label: exam.isPublished ? 'Published' : 'Draft'),
                _Pill(label: exam.assignedExamineeIds.isEmpty ? 'Open access' : 'Friend-only'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.night.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.night),
      ),
    );
  }
}
