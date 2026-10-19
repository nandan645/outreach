import 'package:flutter_test/flutter_test.dart';
import 'package:heydoc_outreach/main.dart';

void main() {
  testWidgets('App loads home screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const PresentationApp());
    expect(find.text('Create new slide'), findsOneWidget);
  });
}
