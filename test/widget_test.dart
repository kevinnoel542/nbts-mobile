import 'package:flutter_test/flutter_test.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Services.instance.init();
    await tester.pumpWidget(const NBTSApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('shows NBTS welcome screen', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Donate blood.'), findsOneWidget);
    expect(find.text('Save lives.'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('opens donor registration flow', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Donor registration'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('DONOR PROFILE'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
