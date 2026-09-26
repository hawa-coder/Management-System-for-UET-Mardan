import 'dart:async';
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
  for (final role in [Role.student, Role.adviser]) {
    testWidgets('saved ${role.name} login opens the dashboard directly', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'saved-token'});
      final profile = Completer<http.Response>();
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/profile')) {
          expect(request.headers['Authorization'], 'Bearer saved-token');
          return profile.future;
        }
        return http.Response('{"data":[]}', 200);
      });
      addTearDown(client.close);

      await tester.pumpWidget(DcmcsApp(api: ApiService(client: client)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Onboarding), findsNothing);
      expect(find.byType(Login), findsNothing);

      profile.complete(
        http.Response(
          jsonEncode({
            'id': 1,
            'name': 'Returning User',
            'email': 'returning@uetmardan.edu.pk',
            'role': role.name,
            'account_status': 'approved',
          }),
          200,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dashboard), findsOneWidget);
      expect(find.byType(Onboarding), findsNothing);
      expect(find.byType(Login), findsNothing);
      final store = tester.widget<Shell>(find.byType(Shell)).store;
      expect(store.role, role);
      expect(store.displayName, 'Returning User');

      await store.logout();
      await tester.pumpAndSettle();
      expect(find.byType(Login), findsOneWidget);
      expect(find.byType(Onboarding), findsNothing);
      expect(find.byType(Dashboard), findsNothing);
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final status in [401, 403]) {
    testWidgets('rejected saved session ($status) cannot open a dashboard', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'invalid-token',
      });
      final client = MockClient(
        (_) async => http.Response('{"message":"Session unavailable"}', status),
      );
      addTearDown(client.close);
      await tester.pumpWidget(DcmcsApp(api: ApiService(client: client)));
      await tester.pumpAndSettle();
      expect(find.byType(Dashboard), findsNothing);
      expect(find.byType(Onboarding), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('signing out offline prevents restoring the saved login', () async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'saved-token'});
    final client = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    addTearDown(client.close);
    final api = ApiService(client: client);
    final store = Store(api: api)..signedIn = true;
    addTearDown(store.dispose);

    await store.logout();

    expect(store.signedIn, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'), isNull);
    expect(await api.restoreProfile(), isNull);
  });
}
