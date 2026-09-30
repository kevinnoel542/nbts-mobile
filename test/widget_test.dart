import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/features/auth/screens/welcome_screen.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    LanguageController.code.value = 'en';
    await tester.pumpWidget(
      MaterialApp(routes: AppRoutes.routes, home: const WelcomeScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows NBTS welcome screen', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Donate blood.'), findsOneWidget);
    expect(find.text('Save lives.'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('opens donor registration flow', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Donor registration'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(find.text('DONOR PROFILE'), findsOneWidget);
  });
}
