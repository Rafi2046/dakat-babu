import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/main.dart';

void main() {
  testWidgets('DakatBabuApp smoke test - renders HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DakatBabuApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app brand and mode options are rendered
    expect(find.text('DakatBabu'), findsOneWidget);
    expect(find.text('CREATE ROOM'), findsAtLeastNWidgets(1));
    expect(find.text('JOIN ROOM'), findsOneWidget);
  });
}
