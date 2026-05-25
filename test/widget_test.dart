// ==========================================================================
// AeroQuiz Widget Smoke Test Suite
// ==========================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:aeroquiz_app/main.dart';

void main() {
  testWidgets('AeroQuiz App Boot Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AeroQuizApp());

    // Verify that our app starts on the welcome screen and finds key headers
    expect(find.text('AeroQuiz'), findsOneWidget);
    expect(find.text('Convert PDFs to Smart Quizzes'), findsOneWidget);
  });
}
