import 'package:flutter_test/flutter_test.dart';
import 'package:jorhat_repair_marketplace/main.dart';

void main() {
  testWidgets('App initializes cleanly test', (WidgetTester tester) async {
    await tester.pumpWidget(const JorhatRepairApp());
    expect(find.byType(JorhatRepairApp), findsOneWidget);
  });
}
