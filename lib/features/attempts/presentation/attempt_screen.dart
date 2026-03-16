import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../exams/data/app_state.dart';

class AttemptScreen extends ConsumerStatefulWidget {
  const AttemptScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends ConsumerState<AttemptScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(appStateProvider.notifier).loadAttempt(widget.attemptId);
      _syncTimer();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncTimer());
    });
  }

  void _syncTimer() {
    final attempt = ref.read(appStateProvider).activeAttempt;
    if (attempt == null) return;
    final remaining = attempt.endAt.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      ref.read(appStateProvider.notifier).submitAttempt(widget.attemptId).then((_) {
        if (mounted) context.go('/result/${widget.attemptId}');
      });
      _timer?.cancel();
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appStateProvider.notifier);
    final attempt = state.activeAttempt;
    if (attempt == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final exam = state.exams.firstWhere((item) => item.id == attempt.examId, orElse: () => controller.examById(attempt.examId));
    final questions = state.attemptQuestions;

    return Scaffold(
      body: AppShell(
        title: 'Attempt in Progress',
        subtitle: 'Server-shaped countdown, autosave-style answer state, and clean submission flow.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassPanel(
              child: Row(
                children: [
                  Expanded(child: Text(exam.title, style: Theme.of(context).textTheme.titleLarge)),
                  Text(_format(_remaining), style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...questions.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${entry.key + 1}. ${entry.value.prompt}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: entry.value.options.asMap().entries.map((option) {
                            final isSelected = attempt.answers[entry.value.id] == option.key;
                            return ChoiceChip(
                              label: Text('${'ABCD'[option.key]}. ${option.value}'),
                              selected: isSelected,
                              onSelected: (_) => controller.answerQuestion(attempt.id, entry.value.id, option.key),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                )),
            ElevatedButton(
              onPressed: () async {
                await controller.submitAttempt(widget.attemptId);
                if (!mounted) return;
                context.go('/result/${widget.attemptId}');
              },
              child: const Text('Submit exam'),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
}
