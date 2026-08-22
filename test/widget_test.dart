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

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });
}
