import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jorhat_repair_marketplace/main.dart';

void main() {
  testWidgets('App initializes cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FixlyApp()));
    expect(find.byType(FixlyApp), findsOneWidget);
  });
}
