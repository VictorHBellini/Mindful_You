import 'package:flutter_test/flutter_test.dart';

import 'package:mindful_you/app.dart';

void main() {
  testWidgets('exibe a tela inicial do aplicativo', (WidgetTester tester) async {
    await tester.pumpWidget(const MindfulYouApp());

    expect(find.text('MINDFUL'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);

    // Avança o tempo para disparar o timer da splash screen e evitar timers pendentes
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  });
}
