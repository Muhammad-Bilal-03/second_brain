// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_brain/app.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';

void main() {
  testWidgets('App displays notes list screen', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );

    // Wait for the async providers to load
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('🧠 Second Brain'), findsOneWidget);
    
    // Verify that search bar is displayed
    expect(find.byType(TextField), findsWidgets);
    
    // Verify that FAB is displayed
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
