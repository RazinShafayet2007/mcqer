import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcqer_frontend/features/auth/presentation/role_selection_screen.dart';

void main() {
  testWidgets('role selection screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoleSelectionScreen())));
    await tester.pump();

    expect(find.text('MCQer'), findsOneWidget);
    expect(find.text('Examiner'), findsOneWidget);
    expect(find.text('Examinee'), findsOneWidget);
  });
}
