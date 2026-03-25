import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/main.dart';

void main() {
  testWidgets('MyApp smoke – builds widget tree without crashing',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    // AuthCheck FutureBuilder starts in waiting state → loading spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let async FutureBuilders resolve (empty prefs → uid is null → RegisterScreen)
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Scaffold), findsWidgets);
  });
}
