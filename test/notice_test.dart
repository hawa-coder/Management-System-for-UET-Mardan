import 'dart:convert';

import 'package:dcmcs/api_service.dart';
import 'package:dcmcs/app_state.dart';
import 'package:dcmcs/main.dart';
import 'package:dcmcs/notice_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'publishing a targeted notice sends filters and updates the board',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? sent;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/options')) {
          return http.Response(
            jsonEncode({
              'department': ['Computer Science'],
              'batch': ['FA23', 'SP24'],
              'section': ['AI'],
            }),
            200,
          );
        }
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            ...sent!,
            'id': 1,
            'published_at': DateTime.now().toIso8601String(),
            'publisher': {'name': 'Dr. Teacher', 'role': 'faculty'},
          }),
          201,
        );
      });
      final store = Store(api: ApiService(client: client))
        ..role = Role.faculty
        ..authenticatedUser = {
          'name': 'Dr. Teacher',
          'department': 'Computer Science',
          'account_status': 'approved',
        };
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: store,
              builder: (_, _) => Notices(store),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Create Notice'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notice Title'),
        'AI class update',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notice Message'),
        'Meet in lab 2.',
      );
      for (final entry in {
        'Department / Field': ['Computer Science'],
        'Batches': ['FA23', 'SP24'],
        'Semesters': ['Semester 5'],
        'Sections': ['AI'],
      }.entries) {
        final field = find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(OutlinedButton),
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        for (final value in entry.value) {
          final checkbox = find.widgetWithText(CheckboxListTile, value);
          await tester.ensureVisible(checkbox);
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Publish notice'));
      await tester.pumpAndSettle();
      expect(sent!['title'], 'AI class update');
      expect(sent!['departments'], ['Computer Science']);
      expect(sent!['batches'], ['FA23', 'SP24']);
      expect(sent!['semesters'], [5]);
      expect(sent!['sections'], ['AI']);
      expect(sent!['priority'], 'Normal');
      expect(find.byType(NoticeComposer), findsNothing);
      expect(find.text('AI class update'), findsOneWidget);
      expect(store.notices.single.meta, contains('Faculty Member'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'students have a read only board and advisers have a scoped composer',
    (tester) async {
      final client = MockClient(
        (_) async => http.Response(
          '{"department":[],"batch":[],"section":[],"scope_description":"Only students assigned to you."}',
          200,
        ),
      );
      final store = Store(api: ApiService(client: client))
        ..authenticatedUser = {'account_status': 'approved'};
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Notices(store))),
      );
      expect(find.text('Create Notice'), findsNothing);
      store.role = Role.adviser;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Notices(store))),
      );
      await tester.tap(find.text('Create Notice'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Only students assigned to you'),
        findsOneWidget,
      );
      expect(find.text('Audience'), findsNothing);
      await tester.tap(find.text('Publish notice'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a notice title.'), findsOneWidget);
      expect(find.text('Enter the notice message.'), findsOneWidget);
      expect(find.byType(NoticeComposer), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('notice loading includes later pages', () async {
    final client = MockClient((request) async {
      final page = request.url.queryParameters['page'] ?? '1';
      return http.Response(
        jsonEncode({
          'data': [
            {'title': 'Page $page'},
          ],
          'last_page': 2,
        }),
        200,
      );
    });
    addTearDown(client.close);
    final notices = await ApiService(client: client).fetchNotices();
    expect(notices.map((n) => n['title']), ['Page 1', 'Page 2']);
  });
}
