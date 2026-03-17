import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../exams/data/app_state.dart';
import '../../exams/domain/models.dart';
import 'profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser!;
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username);
    _headlineController = TextEditingController(text: user.headline);
    _bioController = TextEditingController(text: user.bio);
    _profileImagePath = user.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final user = ref.read(appStateProvider.notifier).currentUser;
    final role = state.role;
    final previewUser = user.copyWith(
      name: _nameController.text,
      username: _usernameController.text,
      headline: _headlineController.text,
      bio: _bioController.text,
      profileImagePath: _profileImagePath,
      clearProfileImagePath: _profileImagePath == null,
    );

    return Scaffold(
      body: AppShell(
        title: role == UserRole.examiner ? 'Examiner Profile' : 'Examinee Profile',
        subtitle: 'Shape how you appear in suggestions, friend requests, and private exam sharing.',
        actions: [
          OutlinedButton(
            onPressed: () async {
              await ref.read(appStateProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/roles');
            },
            child: const Text('Logout'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => context.go(role == UserRole.examiner ? '/examiner' : '/examinee'),
            child: const Text('Back'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassPanel(
              child: Row(
                children: [
                  ProfileAvatar(
                    user: previewUser,
                    radius: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previewUser.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('@${previewUser.username}'),
                        const SizedBox(height: 6),
                        Text(previewUser.headline, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(controller: _headlineController, decoration: const InputDecoration(labelText: 'Headline')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 20),
            const SectionHeading(
              title: 'Profile picture',
              subtitle: 'Upload a real image from your device. If you skip it, the app falls back to your initials.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Upload image'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _profileImagePath = null),
                  child: const Text('Remove image'),
                ),
                if (_profileImagePath != null)
                  Text(
                    _profileImagePath!.split(Platform.pathSeparator).last,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ref.read(appStateProvider.notifier).updateCurrentUserProfile(
                      name: _nameController.text,
                      username: _usernameController.text,
                      bio: _bioController.text,
                      profileImagePath: _profileImagePath,
                      headline: _headlineController.text,
                    );
                if (!mounted) return;
                context.go(role == UserRole.examiner ? '/examiner' : '/examinee');
              },
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    setState(() => _profileImagePath = path);
  }
}
