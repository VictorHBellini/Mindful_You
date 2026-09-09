import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_you/app.dart';

void main() {
  testWidgets('exibe a tela inicial do aplicativo', (WidgetTester tester) async {
    await tester.pumpWidget(const MindfulYouApp());

    expect(find.text('MINDFUL'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
  });
}
