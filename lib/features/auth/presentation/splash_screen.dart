import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_shell.dart';
import '../../exams/data/app_state.dart';
import '../../exams/domain/models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final restored = await ref.read(appStateProvider.notifier).restoreSession();
      if (!mounted) return;
      if (restored) {
        final role = ref.read(appStateProvider).role;
        context.go(role == UserRole.examiner ? '/examiner' : '/examinee');
      } else {
        context.go('/roles');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppShell(
        title: 'Mcqer',
        subtitle: 'Restoring your secure session.',
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
