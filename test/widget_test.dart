import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_connect/main.dart';

void main() {
  testWidgets('Login page loads correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify that the Login page is displayed
    expect(find.text('Login'), findsOneWidget);

    // Check that email and password TextFields exist
    expect(find.byType(TextField), findsNWidgets(2));

    // Optionally, check for a Login button if you have a RaisedButton / ElevatedButton
    expect(find.byType(ElevatedButton), findsOneWidget);

    // You can simulate a user entering text
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com'); // email
    await tester.enterText(find.byType(TextField).at(1), 'password123');       // password

    // Tap the Login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // If login navigates to another page, check for some widget/text on that page
    // Example:
    // expect(find.text('Welcome'), findsOneWidget);
  });
}
