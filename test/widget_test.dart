// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:second_brain/app.dart';

void main() {
  testWidgets('App displays placeholder home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: App()));

    // Verify that the app title is displayed
    expect(find.text('🧠 Second Brain'), findsOneWidget);
    
    // Verify that welcome message is displayed
    expect(find.text('Welcome to Second Brain'), findsOneWidget);
    
    // Verify that the brain icon is displayed
    expect(find.byIcon(Icons.psychology), findsOneWidget);
  });
}
