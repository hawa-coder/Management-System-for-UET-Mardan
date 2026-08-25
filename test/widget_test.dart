import 'package:dcmcs/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding opens and reaches login', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const DcmcsApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to DCMS'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Real-time Updates'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Student Access'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Registration number'), findsOneWidget);
    expect(find.text('Semester'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
