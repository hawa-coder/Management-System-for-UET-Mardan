import 'dart:convert';

import 'package:dcmcs/api_service.dart';
import 'package:dcmcs/app_state.dart';
import 'package:dcmcs/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'student can complete account creation with a loaded Batch Adviser',
    (tester) async {
      Map<String, String>? registration;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/advisers')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 10,
                  'name': 'Dr. Shams Ur Rahman',
                  'batch': 'Batch 05',
                  'semester': 8,
                  'section': 'AI',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/register')) {
          registration = Map<String, String>.from(request.bodyFields);
          return http.Response(
            jsonEncode({
              'message':
                  'Account submitted. Your batch adviser must approve it before you can sign in.',
            }),
            201,
          );
        }
        return http.Response('{}', 404);
      });
      final store = Store(api: ApiService(client: client));
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(home: Login(store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account').last);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'New Student',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'University email'),
        'new.student@uetmardan.edu.pk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registration number'),
        '23-MDBCS-425',
      );
      final semesterField = find.byType(DropdownButtonFormField<int>).at(0);
      await tester.ensureVisible(semesterField);
      await tester.tap(semesterField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 8').last);
      await tester.pumpAndSettle();
      final sectionField = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(sectionField);
      await tester.tap(sectionField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI').last);
      await tester.pumpAndSettle();
      final adviserField = find.byType(DropdownButtonFormField<int>).at(1);
      await tester.ensureVisible(adviserField);
      await tester.tap(adviserField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Shams Ur Rahman').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile number'),
        '03001234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Student@123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'Student@123',
      );
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(registration?['registration_number'], '23-MDBCS-425');
      expect(registration?['batch_adviser_id'], '10');
      expect(registration?['semester'], '8');
      expect(registration?['section'], 'AI');
      expect(find.text('Sign in to track your complaints'), findsOneWidget);
      expect(find.textContaining('Account submitted.'), findsOneWidget);
    },
  );

  testWidgets(
    'student registration shows adviser loading failure and retries',
    (tester) async {
      var adviserRequests = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/advisers')) {
          adviserRequests++;
          return http.Response(
            jsonEncode({
              'message': 'Batch Adviser list is temporarily unavailable.',
            }),
            503,
          );
        }
        return http.Response('{}', 404);
      });
      final store = Store(api: ApiService(client: client));
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(home: Login(store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account').last);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.ensureVisible(find.text('Retry'));
      expect(
        find.text('Batch Adviser list is temporarily unavailable.'),
        findsOneWidget,
      );
      final requestsBeforeRetry = adviserRequests;
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(adviserRequests, requestsBeforeRetry + 1);
      expect(
        find.text('Batch Adviser list is temporarily unavailable.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('valid email addresses work in registration and sign in', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('{"data":[]}', 200));
    final store = Store(api: ApiService(client: client));
    addTearDown(client.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(home: Login(store)));
    await tester.pumpAndSettle();

    for (final createAccount in [false, true]) {
      if (createAccount) {
        final button = find.text('Create account').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 500));
      }

      final emailField = find.widgetWithText(TextFormField, 'University email');
      for (final email in [
        '23mdbcs345@uetmardan.edu.pk',
        '123mdbcs345@uetmardan.edu.pk',
        '2023cs009@uetmardan.edu.pk',
        'student.name@uetmardan.edu.pk',
        'my.name+study@uetmardan.edu.pk',
      ]) {
        await tester.enterText(emailField, email);
        expect(
          tester.state<FormFieldState<String>>(emailField).validate(),
          isTrue,
          reason: email,
        );
      }
      for (final email in [
        'student@gmail.com',
        'student@sub.uetmardan.edu.pk',
        'student@uetmardan.edu.pk.example.com',
        'student-without-domain',
        'student@',
        'student name@uetmardan.edu.pk',
        '@uetmardan.edu.pk',
      ]) {
        await tester.enterText(emailField, email);
        expect(
          tester.state<FormFieldState<String>>(emailField).validate(),
          isFalse,
          reason: email,
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

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

    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pump();
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    final createAccountButton = find.text(
      'Create account',
      skipOffstage: false,
    );
    await tester.ensureVisible(createAccountButton.last);
    await tester.tap(createAccountButton.last);
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Registration number'), findsOneWidget);
    expect(find.text('Semester'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
