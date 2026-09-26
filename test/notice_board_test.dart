import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dcmcs/api_service.dart';
import 'package:dcmcs/app_state.dart';
import 'package:dcmcs/main.dart';
import 'package:dcmcs/notice_board.dart';
import 'package:dcmcs/notice_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> sampleNotice(int id, {String priority = 'Normal'}) => {
  'id': id,
  'published_by': 10,
  'title': id == 1
      ? 'Final Year Project Meeting'
      : 'Revised examination timetable',
  'body':
      'All selected students are requested to attend the project progress meeting on Monday in the Computer Science seminar room.',
  'publisher': {'name': 'Dr. Ahmed', 'role': 'adviser'},
  'audience': 'student',
  'priority': priority,
  'category': id == 1 ? 'FYP' : 'Examination',
  'departments': ['Computer Science'],
  'batches': ['FA23'],
  'semesters': [7],
  'sections': ['A'],
  'notice_date': DateTime.now()
      .subtract(const Duration(hours: 1))
      .toIso8601String(),
  'is_read': false,
};

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_NOTICE_SCREENS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('outputs/notices').create(recursive: true);
    await File(
      'outputs/notices/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_NOTICE_SCREENS')) return;
    final packages =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map;
    final flutter =
        (packages['packages'] as List).firstWhere((p) => p['name'] == 'flutter')
            as Map;
    final sdk = Directory.fromUri(
      Uri.parse(flutter['rootUri'] as String),
    ).parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    for (final entry in {
      'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final name in entry.value) {
        loader.addFont(
          File(
            '$fonts/$name',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await loader.load();
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'search, priority filters, and opening notices update read indicators',
    (tester) async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({...sampleNotice(1, priority: 'Urgent'), 'is_read': true}),
          200,
        ),
      );
      final store = Store(api: ApiService(client: client));
      store.notifications.clear();
      store.notices.addAll([
        DepartmentNotice.fromJson(sampleNotice(1, priority: 'Urgent')),
        DepartmentNotice.fromJson(sampleNotice(2)),
      ]);
      store.notifications.add(
        AppNotification(
          backendId: 2,
          noticeId: 1,
          title: 'New Notice',
          message: 'Meeting',
          time: 'Now',
          type: NotificationType.notice,
        ),
      );
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: NoticeBoard(store))),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Search notices'),
        'Project',
      );
      await tester.pumpAndSettle();
      expect(find.text('Final Year Project Meeting'), findsOneWidget);
      expect(find.text('Revised examination timetable'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Search notices'),
        '',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Urgent'));
      await tester.pumpAndSettle();
      expect(find.byType(AnnouncementCard), findsOneWidget);
      await tester.ensureVisible(find.text('View notice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View notice'));
      await tester.pumpAndSettle();
      expect(find.byType(NoticeDetails), findsOneWidget);
      expect(store.notices.firstWhere((n) => n.id == 1).isRead, isTrue);
      expect(store.unreadNotificationCount, 0);
      expect(store.unreadNoticeCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'staff can manage scheduled notices and retain changes after validation errors',
    (tester) async {
      final item = {
        ...sampleNotice(1),
        'notice_date': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
      };
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/options')) {
          return http.Response(
            '{"department":[],"batch":[],"section":[],"students":[],"courses":[]}',
            200,
          );
        }
        if (request.method == 'POST') {
          return http.Response(
            '{"message":"Please review the audience."}',
            422,
          );
        }
        return http.Response(
          jsonEncode({
            'data': [item],
          }),
          200,
        );
      });
      final store = Store(api: ApiService(client: client))
        ..role = Role.chairman
        ..authenticatedUser = {'id': 10, 'account_status': 'approved'};
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: NoticeBoard(store))),
      );
      await tester.tap(find.text('My Notices'));
      await tester.pumpAndSettle();
      expect(find.text('My Notices / Manage Notices'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Scheduled'), findsOneWidget);
      await tester.ensureVisible(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final title = find.widgetWithText(TextFormField, 'Notice Title');
      await tester.enterText(title, 'Updated project meeting');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.byType(NoticeComposer), findsOneWidget);
      expect(find.text('Updated project meeting'), findsOneWidget);
      expect(find.text('Please review the audience.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final width in [430.0, 1440.0]) {
    testWidgets('notice screens fit a ${width.toInt()} pixel viewport', (
      tester,
    ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'department': ['Computer Science'],
            'batch': ['FA23', 'SP24'],
            'section': ['A', 'B'],
            'students': [],
            'courses': [],
            'scope_description': 'Students in your department.',
          }),
          200,
        ),
      );
      final store = Store(api: ApiService(client: client))
        ..role = Role.chairman
        ..tab = 2
        ..authenticatedUser = {
          'id': 10,
          'name': 'Dr. Ahmed',
          'account_status': 'approved',
          'department': 'Computer Science',
        };
      store.notices.addAll([
        DepartmentNotice.fromJson(sampleNotice(1, priority: 'Urgent')),
        DepartmentNotice.fromJson(sampleNotice(2, priority: 'Important')),
      ]);
      addTearDown(client.close);
      addTearDown(store.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: canvas,
              colorScheme: ColorScheme.fromSeed(
                seedColor: green,
                primary: green,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            home: Shell(store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'board-${width.toInt()}');
      await tester.tap(find.text('Create Notice'));
      await tester.pumpAndSettle();
      expect(find.byType(NoticeComposer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'composer-${width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
