import 'dart:convert';

import 'package:dcmcs/api_service.dart';
import 'package:dcmcs/app_state.dart';
import 'package:dcmcs/complaint_routing.dart';
import 'package:dcmcs/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const adviser = {'id': 2, 'name': 'Dr. Ahmed Khan', 'role': 'adviser'};
const chairman = {'id': 3, 'name': 'Dr. Usman Khan', 'role': 'chairman'};
const faculty = {'id': 4, 'name': 'Dr. Hassan Ali', 'role': 'faculty'};

Map<String, dynamic> routedComplaint({bool canForward = true}) => {
  'id': 125,
  'complaint_number': 'CMP-00125',
  'student_registration_number': 'FA23-BCS-123',
  'title': 'Attendance Issue',
  'details': 'Please review the attendance record.',
  'category': 'Academic',
  'priority': 'Medium',
  'status': 'forwarded',
  'current_handler_role': 'faculty',
  'created_at': '2026-09-25T08:00:00Z',
  'updated_at': '2026-09-25T10:00:00Z',
  'routing': {
    'received_from': chairman,
    'originally_forwarded_by': adviser,
    'batch_adviser': adviser,
    'forwarded_by': chairman,
    'forwarded_to': faculty,
    'next_forwarded_to': faculty,
    'currently_with': faculty,
  },
  'permissions': {'can_act': true, 'can_forward': canForward},
  'history': [
    {
      'event_type': 'submitted',
      'action': 'Complaint submitted',
      'actor': {'id': 1, 'name': 'FA23-BCS-123', 'role': 'student'},
      'recipient': adviser,
      'created_at': '2026-09-25T08:00:00Z',
    },
    {
      'event_type': 'forwarded',
      'action': 'Complaint forwarded',
      'actor': adviser,
      'recipient': chairman,
      'remarks': 'Please review this complaint.',
      'created_at': '2026-09-25T09:00:00Z',
    },
    {
      'event_type': 'forwarded',
      'action': 'Complaint forwarded',
      'actor': chairman,
      'recipient': faculty,
      'created_at': '2026-09-25T10:00:00Z',
    },
  ],
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('complaint list loads every resource collection page', () async {
    final pages = <String?>[];
    final client = MockClient((request) async {
      pages.add(request.url.queryParameters['page']);
      return http.Response(
        jsonEncode({
          'data': [
            {'id': pages.length},
          ],
          'meta': {'last_page': 2},
        }),
        200,
      );
    });
    addTearDown(client.close);
    final complaints = await ApiService(client: client).fetchComplaints();
    expect(complaints.map((c) => c['id']), [1, 2]);
    expect(pages, [null, '2']);
  });

  test(
    'routing model retains original adviser, latest sender, recipients and comments',
    () {
      final complaint = Complaint.fromJson(routedComplaint());
      expect(complaint.registrationNumber, 'FA23-BCS-123');
      expect(
        complaint.routingLabel('originally_forwarded_by'),
        'Dr. Ahmed Khan – Batch Adviser',
      );
      expect(
        complaint.routingLabel('received_from'),
        'Dr. Usman Khan – Chairman',
      );
      expect(complaint.currentlyWith, 'Dr. Hassan Ali – Faculty Member');
      expect(
        complaint.routingHistory[1].comment,
        'Please review this complaint.',
      );
      final returned = routedComplaint()..['status'] = 'returned';
      expect(Complaint.fromJson(returned).status.label, 'Returned');
    },
  );

  testWidgets(
    'complaint card shows named routing at phone and desktop widths',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = Store();
      addTearDown(store.dispose);
      final complaint = Complaint.fromJson(routedComplaint());
      for (final width in [360.0, 1100.0]) {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ComplaintCard(store, complaint),
              ),
            ),
          ),
        );
        expect(find.text('Complaint ID: CMP-00125'), findsOneWidget);
        expect(find.text('FA23-BCS-123'), findsOneWidget);
        expect(find.text('Dr. Ahmed Khan – Batch Adviser'), findsOneWidget);
        expect(find.text('Received From'), findsOneWidget);
        expect(find.text('Forwarded By'), findsOneWidget);
        expect(find.text('Forwarded To'), findsOneWidget);
        expect(find.text('Currently With'), findsOneWidget);
        expect(find.text('Date and Time'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'viewport width $width');
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'faculty details show routing history without viewer student details',
    (tester) async {
      final store = Store()..role = Role.faculty;
      addTearDown(store.dispose);
      store.authenticatedUser = {
        'id': 4,
        'name': 'Viewer name must not appear as student',
        'registration_number': 'WRONG-REG',
      };
      final complaint = Complaint.fromJson(routedComplaint(canForward: false));
      await tester.pumpWidget(MaterialApp(home: Detail(store, complaint)));
      expect(find.text('Complaint Routing'), findsOneWidget);
      expect(find.text('FA23-BCS-123'), findsOneWidget);
      expect(find.textContaining('WRONG-REG'), findsNothing);
      expect(find.textContaining('Viewer name'), findsNothing);
      await tester.scrollUntilVisible(find.text('Routing History'), 250);
      expect(find.text('Routing History'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Comment: Please review this complaint.'),
        250,
      );
      expect(
        find.text('Sent / acted by: Dr. Ahmed Khan – Batch Adviser'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Take action'), 250);
      expect(find.text('Forward Complaint'), findsNothing);
      expect(find.text('Return Complaint'), findsNothing);
      expect(find.text('Resolve'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'forward dialog selects a named recipient, displays role and sends comment',
    (tester) async {
      Map<String, dynamic>? submitted;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/recipients')) {
          return http.Response(
            jsonEncode({
              'data': [adviser, chairman],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/transition')) {
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          final updated = routedComplaint()..['status'] = 'returned';
          (updated['routing'] as Map)['currently_with'] = chairman;
          return http.Response(jsonEncode(updated), 200);
        }
        return http.Response('{"data":[]}', 200);
      });
      final store = Store(api: ApiService(client: client));
      final complaint = Complaint.fromJson(routedComplaint());
      store.complaints.add(complaint);
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      ForwardComplaintDialog(store, complaint, returning: true),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Usman Khan – Chairman').last);
      await tester.pumpAndSettle();
      expect(find.text('Chairman'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Please provide additional information.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Return Complaint'));
      await tester.pumpAndSettle();
      expect(submitted, {
        'action': 'return',
        'recipient_id': 3,
        'remarks': 'Please provide additional information.',
      });
      expect(
        store.complaints.firstWhere((c) => c.backendId == 125).status,
        Status.returned,
      );
      expect(find.byType(ForwardComplaintDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
