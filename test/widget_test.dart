// Smoke test: the app boots to the truckfinder splash screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:truckfinder/main.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const TruckFinderApp());
    expect(find.text('truckfinder'), findsOneWidget);
  });
}
