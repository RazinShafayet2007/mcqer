import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../data/app_state.dart';
import '../domain/models.dart';

class CreateExamScreen extends ConsumerStatefulWidget {
  const CreateExamScreen({super.key});

  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _titleController = TextEditingController(text: 'Strategic Reasoning Mock');
  final _descriptionController = TextEditingController(text: 'Timed mixed-discipline paper with negative marking.');
  final _durationController = TextEditingController(text: '20');
  final _negativeController = TextEditingController(text: '0.25');
  final _rawController = TextEditingController(
    text: '1. Which planet is known as the Red Planet?\nA. Venus\nB. Mars\nC. Jupiter\nD. Mercury\nAnswer: B\n\n2. Which data structure uses FIFO order?\nA. Stack\nB. Tree\nC. Queue\nD. Graph\nAnswer: C',
  );
  _DeliveryMode _deliveryMode = _DeliveryMode.public;
  final Set<String> _selectedFriendIds = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _negativeController.dispose();
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(appStateProvider).parserDrafts;
    final controller = ref.read(appStateProvider.notifier);
    final friendExaminees = controller.acceptedFriendsForRole(UserRole.examinee);

    return Scaffold(
      body: AppShell(
        title: 'Create Exam',
        subtitle: 'Paste MCQs, validate the parser preview, then save a backend-ready frontend draft.',
        actions: [
          OutlinedButton(
            onPressed: () => context.go('/examiner'),
            child: const Text('Back to studio'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              controller.switchRole(UserRole.examinee);
              context.go('/examinee');
            },
            child: const Text('Examinee mode'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Exam title')),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Minutes')),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(controller: _negativeController, decoration: const InputDecoration(labelText: 'Negative mark')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _rawController,
              maxLines: 14,
              decoration: const InputDecoration(labelText: 'Paste raw MCQ text'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => controller.parseQuestions(_rawController.text),
                  child: const Text('Parse questions'),
                ),
                OutlinedButton(
                  onPressed: drafts.isEmpty
                      ? null
                      : () {
                          controller.createExam(
                            title: _titleController.text,
                            description: _descriptionController.text,
                            durationMinutes: int.tryParse(_durationController.text) ?? 20,
                            negativeMarkPerWrong: double.tryParse(_negativeController.text) ?? 0.25,
                            assignedExamineeIds: _resolveRecipients(friendExaminees),
                          );
                          context.go('/examiner');
                        },
                  child: const Text('Save draft'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Friend delivery',
              subtitle: 'Public exams reach everyone. Friend-only exams can target all examinee friends or only selected ones.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Public exam'),
                  selected: _deliveryMode == _DeliveryMode.public,
                  onSelected: (_) => setState(() => _deliveryMode = _DeliveryMode.public),
                ),
                ChoiceChip(
                  label: const Text('All examinee friends'),
                  selected: _deliveryMode == _DeliveryMode.allFriends,
                  onSelected: friendExaminees.isEmpty ? null : (_) => setState(() => _deliveryMode = _DeliveryMode.allFriends),
                ),
                ChoiceChip(
                  label: const Text('Selected friends'),
                  selected: _deliveryMode == _DeliveryMode.selectedFriends,
                  onSelected: friendExaminees.isEmpty ? null : (_) => setState(() => _deliveryMode = _DeliveryMode.selectedFriends),
                ),
              ],
            ),
            if (friendExaminees.isEmpty) ...[
              const SizedBox(height: 12),
              const GlassPanel(
                child: Text('No accepted examinee friends yet. Add and accept examinee friends from the dashboard to unlock private friend exams.'),
              ),
            ] else if (_deliveryMode == _DeliveryMode.selectedFriends) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: friendExaminees.map((friend) {
                  final selected = _selectedFriendIds.contains(friend.id);
                  return FilterChip(
                    label: Text(friend.name),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedFriendIds.add(friend.id);
                        } else {
                          _selectedFriendIds.remove(friend.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Parser preview',
              subtitle: 'Correct answers are visible here for the examiner only and stay hidden from examinee routes.',
            ),
            const SizedBox(height: 16),
            if (drafts.isEmpty)
              const GlassPanel(child: Text('No parser output yet. Paste a question bank and run the parser.')),
            ...drafts.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q${entry.key + 1}. ${entry.value.prompt}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...entry.value.options.asMap().entries.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${'ABCD'[option.key]}. ${option.value}${option.key == entry.value.correctIndex ? '  (correct)' : ''}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _resolveRecipients(List<AppUser> friendExaminees) {
    switch (_deliveryMode) {
      case _DeliveryMode.public:
        return const [];
      case _DeliveryMode.allFriends:
        return friendExaminees.map((friend) => friend.id).toList();
      case _DeliveryMode.selectedFriends:
        return _selectedFriendIds.toList();
    }
  }
}

enum _DeliveryMode { public, allFriends, selectedFriends }
