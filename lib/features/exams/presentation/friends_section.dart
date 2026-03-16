import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_shell.dart';
import '../data/app_state.dart';

class FriendsSection extends ConsumerWidget {
  const FriendsSection({
    super.key,
    required this.title,
    required this.suggestionTitle,
    required this.incomingTitle,
    required this.friendTitle,
  });

  final String title;
  final String suggestionTitle;
  final String incomingTitle;
  final String friendTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appStateProvider.notifier);
    final suggestions = controller.oppositeRoleSuggestions();
    final incoming = controller.incomingFriendRequests();
    final friends = controller.acceptedFriends();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Send requests only across roles. Accepting a request unlocks targeted exam sharing.'),
          const SizedBox(height: 18),
          _FriendSubsection(
            title: suggestionTitle,
            emptyText: 'No new suggestions right now.',
            children: suggestions.map((user) {
              final pending = controller.hasPendingRequestWith(user.id);
              return _FriendTile(
                title: user.name,
                subtitle: user.role.name,
                action: OutlinedButton(
                  onPressed: pending ? null : () => controller.sendFriendRequest(user.id),
                  child: Text(pending ? 'Pending' : 'Add friend'),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FriendSubsection(
            title: incomingTitle,
            emptyText: 'No incoming requests.',
            children: incoming.map((request) {
              final sender = controller.userById(request.senderId);
              return _FriendTile(
                title: sender.name,
                subtitle: 'Wants to connect as ${sender.role.name}',
                action: ElevatedButton(
                  onPressed: () => controller.acceptFriendRequest(request.id),
                  child: const Text('Accept'),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FriendSubsection(
            title: friendTitle,
            emptyText: 'No accepted friends yet.',
            children: friends
                .map(
                  (user) => _FriendTile(
                    title: user.name,
                    subtitle: 'Connected ${user.role.name}',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FriendSubsection extends StatelessWidget {
  const _FriendSubsection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...children,
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
