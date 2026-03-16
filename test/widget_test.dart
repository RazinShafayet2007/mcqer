import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcqer_frontend/main.dart';

void main() {
  testWidgets('role selection screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: McqerApp()));
    await tester.pumpAndSettle();

    expect(find.text('MCQer'), findsOneWidget);
    expect(find.text('Examiner'), findsOneWidget);
    expect(find.text('Examinee'), findsOneWidget);
  });
}
