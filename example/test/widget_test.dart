// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_media_widgets_example/main.dart';

void main() {
  testWidgets('Smart Media Widgets Example app smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('Smart Media Widgets Example'), findsOneWidget);

    // Verify that the bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that the navigation items are present
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Cache'), findsOneWidget);

    // Verify that the main content area is present
    expect(find.text('Image Display Examples'), findsOneWidget);
  });

  testWidgets('Navigation between tabs works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Initially on Images tab
    expect(find.text('Image Display Examples'), findsOneWidget);

    // Tap on Videos tab
    await tester.tap(find.text('Videos'));
    await tester.pump();

    // Verify we're on Videos tab (without waiting for video initialization)
    expect(find.text('Video Display Examples'), findsOneWidget);

    // Tap on Cache tab
    await tester.tap(find.text('Cache'));
    await tester.pump();

    // Verify we're on Cache tab
    expect(find.text('Cache Management'), findsOneWidget);
  });

  testWidgets('App structure is correct', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify app structure
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
