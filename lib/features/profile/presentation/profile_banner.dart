import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../exams/domain/models.dart';
import 'profile_avatar.dart';

class ProfileBanner extends StatelessWidget {
  const ProfileBanner({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(user: user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('@${user.username}'),
                const SizedBox(height: 6),
                Text(user.headline, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(user.bio, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
