import 'package:flutter/material.dart';

import 'api_service.dart';
import 'dart:typed_data';

const navy = Color(0xFF0B1F3A);
const green = Color(0xFF16A085);
const canvas = Color(0xFFF4F7FB);

const studentName = 'Hawa Sabir';
const studentRegistrationNumber = '2023-CS-001';
const studentEmail = '2023cs001@uetmardan.edu.pk';

enum Role { student, adviser, coordinator, chairman, office, dean, faculty }

enum Status {
  submitted,
  review,
  forwarded,
  office,
  dean,
  resolved,
  rejected,
  returned,
}

extension RoleName on Role {
  String get label => const [
    'Student',
    'Batch Adviser',
    'Coordinator',
    'Chairman',
    'Department Staff',
    'Dean',
    'Faculty Member',
  ][index];
}

extension StatusName on Status {
  String get label => const [
    'Submitted',
    'Under Review',
    'Forwarded',
    'Waiting for Office',
    'Waiting for Dean',
    'Resolved',
    'Rejected',
    'Returned',
  ][index];

  Color get color => this == Status.resolved
      ? const Color(0xFF16835C)
      : this == Status.rejected
      ? const Color(0xFFD64545)
      : (this == Status.office || this == Status.dean)
      ? const Color(0xFFE28A19)
      : const Color(0xFF3867D6);
}

class RoutingPerson {
  const RoutingPerson({this.id, required this.name, required this.role});
  final int? id;
  final String name, role;
  String get roleLabel =>
      Role.values.where((r) => r.name == role).firstOrNull?.label ?? role;
  String get label =>
      '${name.isEmpty ? (role == 'student' ? 'Registration number unavailable' : 'Name not recorded') : name} – $roleLabel';

  factory RoutingPerson.fromJson(Map<String, dynamic> json) => RoutingPerson(
    id: json['id'] as int?,
    name: json['name']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
  );
}

class RoutingEvent {
  const RoutingEvent({
    required this.action,
    required this.type,
    this.actor,
    this.recipient,
    this.comment,
    this.createdAt,
  });
  final String action, type;
  final RoutingPerson? actor, recipient;
  final String? comment;
  final DateTime? createdAt;
  factory RoutingEvent.fromJson(Map<String, dynamic> json) => RoutingEvent(
    action: json['action']?.toString() ?? '',
    type: json['event_type']?.toString() ?? 'legacy',
    actor: json['actor'] is Map
        ? RoutingPerson.fromJson(Map<String, dynamic>.from(json['actor']))
        : null,
    recipient: json['recipient'] is Map
        ? RoutingPerson.fromJson(Map<String, dynamic>.from(json['recipient']))
        : null,
    comment: json['remarks']?.toString(),
    createdAt: DateTime.tryParse(
      json['created_at']?.toString() ?? '',
    )?.toLocal(),
  );
}

class Complaint {
  Complaint({
    this.backendId,
    required this.id,
    required this.title,
    required this.details,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.status = Status.submitted,
    this.handler = 'Batch Adviser',
    this.registrationNumber = 'Registration number unavailable',
    this.handlerRole = 'adviser',
    this.routing = const {},
    this.routingHistory = const [],
    this.permissions = const {},
    this.updatedAt,
    List<String>? history,
    this.attachmentName,
    this.attachmentUrl,
    List<ComplaintComment>? comments,
  }) : history = history ?? ['Complaint submitted'],
       comments = comments ?? [];

  final int? backendId;
  final String id, title, details, category, priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String registrationNumber, handlerRole;
  final Map<String, RoutingPerson?> routing;
  final List<RoutingEvent> routingHistory;
  final Map<String, dynamic> permissions;
  bool get canAct => permissions['can_act'] == true;
  bool get canForward => permissions['can_forward'] == true;
  bool get canSendResolution => permissions['can_send_resolution'] == true;
  String routingLabel(String key, {String fallback = 'Not yet forwarded'}) =>
      routing[key]?.label ?? fallback;
  String get currentlyWith => routingLabel(
    'currently_with',
    fallback: handlerRole == 'closed'
        ? 'Closed'
        : 'Name not recorded – $handler',
  );
  final String? attachmentName, attachmentUrl;
  Status status;
  String handler;
  final List<String> history;
  final List<ComplaintComment> comments;

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final history = (json['history'] as List? ?? const [])
        .map((entry) => (entry as Map)['action']?.toString() ?? '')
        .where((action) => action.isNotEmpty)
        .toList();
    final handler = json['current_handler_role']?.toString() ?? 'adviser';
    return Complaint(
      backendId: json['id'] as int?,
      id: json['complaint_number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      )?.toLocal(),
      registrationNumber:
          json['student_registration_number']?.toString() ??
          'Registration number unavailable',
      handlerRole: handler,
      routing: Map<String, dynamic>.from(json['routing'] as Map? ?? {}).map(
        (key, value) => MapEntry(
          key,
          value is Map
              ? RoutingPerson.fromJson(Map<String, dynamic>.from(value))
              : null,
        ),
      ),
      routingHistory: (json['history'] as List? ?? [])
          .map(
            (entry) =>
                RoutingEvent.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      permissions: Map<String, dynamic>.from(json['permissions'] as Map? ?? {}),
      status: Status.values.byName(json['status']?.toString() ?? 'submitted'),
      handler: handler == 'closed'
          ? 'Closed'
          : Role.values
                    .where((role) => role.name == handler)
                    .map((role) => role.label)
                    .firstOrNull ??
                handler,
      history: history.isEmpty ? ['Complaint submitted'] : history,
      attachmentName: json['attachment_name']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      comments: (json['comments'] as List? ?? const [])
          .map(
            (item) => ComplaintComment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class ComplaintComment {
  const ComplaintComment({
    required this.author,
    required this.role,
    required this.comment,
    required this.createdAt,
  });

  final String author, role, comment;
  final DateTime createdAt;

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    final author = Map<String, dynamic>.from(
      json['author'] as Map? ?? const {},
    );
    return ComplaintComment(
      author: author['name']?.toString() ?? 'Staff member',
      role: author['role']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum NotificationType { complaint, notice, account }

class AppNotification {
  AppNotification({
    this.backendId,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.noticeId,
  });

  final int? backendId;
  final int? noticeId;
  final String title, message, time;
  final NotificationType type;
  bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'account';
    return AppNotification(
      backendId: json['id'] as int?,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      noticeId: json['notice_id'] as int?,
      time: _relativeTime(json['created_at']?.toString()),
      type:
          NotificationType.values
              .where((type) => type.name == rawType)
              .firstOrNull ??
          NotificationType.account,
      isRead: json['read_at'] != null,
    );
  }
}

class DepartmentNotice {
  DepartmentNotice({
    required this.title,
    required this.body,
    required this.meta,
    this.data = const {},
    this.isRead = false,
  });
  final String title, body, meta;
  final Map<String, dynamic> data;
  bool isRead;
  int get id => data['id'] as int? ?? 0;
  String get category => data['category']?.toString() ?? 'Department';
  String get priority => data['priority']?.toString() ?? 'Normal';
  String get status {
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return 'Expired';
    }
    if (date != null && date!.isAfter(DateTime.now())) return 'Scheduled';
    return 'Active';
  }

  DateTime? get date => DateTime.tryParse(
    (data['notice_date'] ?? data['published_at'])?.toString() ?? '',
  )?.toLocal();
  DateTime? get expiresAt =>
      DateTime.tryParse(data['expires_at']?.toString() ?? '')?.toLocal();
  String? get attachmentName => data['attachment_name']?.toString();
  String get publisherName =>
      (data['publisher'] as Map?)?['name']?.toString() ?? 'University staff';
  String get publisherRole {
    final role = (data['publisher'] as Map?)?['role'];
    return Role.values.where((r) => r.name == role).firstOrNull?.label ??
        'Staff';
  }

  String get targetSummary {
    final parts = <String>[];
    for (final entry in {
      'departments': 'Department',
      'batches': 'Batch',
      'semesters': 'Semester',
      'sections': 'Section',
    }.entries) {
      final values = data[entry.key] as List? ?? [];
      if (values.isNotEmpty) parts.add('${entry.value}: ${values.join(', ')}');
    }
    for (final entry in {
      'department': 'Department',
      'batch': 'Batch',
      'semester': 'Semester',
      'section': 'Section',
    }.entries) {
      if (data[entry.key] != null) {
        parts.add('${entry.value}: ${data[entry.key]}');
      }
    }
    if ((data['course_ids'] as List? ?? []).isNotEmpty) {
      parts.add('${(data['course_ids'] as List).length} selected course(s)');
    }
    if ((data['student_ids'] as List? ?? []).isNotEmpty) {
      parts.add('${(data['student_ids'] as List).length} selected student(s)');
    }
    if (data['target_adviser_id'] != null) parts.add('Assigned students');
    if (data['target_faculty_id'] != null) parts.add('Taught classes only');
    if (data['scope_department'] != null) {
      parts.add('${data['scope_department']}');
    }
    return parts.isEmpty ? 'All students' : parts.join(' · ');
  }

  factory DepartmentNotice.fromJson(Map<String, dynamic> json) {
    final publisher = json['publisher'] as Map?;
    final audience = json['audience']?.toString() ?? 'all';
    final labels = [
      if (publisher != null)
        '${publisher['name']} (${Role.values.where((r) => r.name == publisher['role']).firstOrNull?.label ?? publisher['role']})',
      audience == 'all'
          ? 'All users'
          : Role.values.where((r) => r.name == audience).firstOrNull?.label ??
                audience,
      if (json['department'] != null) '${json['department']}',
      if (json['batch'] != null) 'Batch ${json['batch']}',
      if (json['semester'] != null) 'Semester ${json['semester']}',
      if (json['section'] != null) 'Section / field ${json['section']}',
      if (json['target_adviser_id'] != null) 'Assigned students only',
      _relativeTime(json['published_at']?.toString()),
    ];
    return DepartmentNotice(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      meta: labels.where((label) => label.isNotEmpty).join(' · '),
      data: json,
      isRead: json['is_read'] == true,
    );
  }
}

String _relativeTime(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return '';
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
  if (difference.inDays < 1) return '${difference.inHours} hours ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

class Store extends ChangeNotifier {
  Store({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;
  bool _disposed = false;
  bool _refreshingAnnouncements = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool signedIn = false;
  bool authenticating = false;
  bool initializing = true;
  bool loadingData = false;
  String? authenticationError;
  String? dataError;
  Role role = Role.student;
  int tab = 0;
  Map<String, dynamic>? authenticatedUser;
  final pendingStudents = <Map<String, dynamic>>[];
  final adviserApprovals = <Map<String, dynamic>>[];

  bool get canPublishNotices =>
      const {
        Role.chairman,
        Role.adviser,
        Role.faculty,
        Role.coordinator,
        Role.dean,
      }.contains(role) &&
      authenticatedUser?['account_status'] == 'approved';

  final myNotices = <DepartmentNotice>[];

  int get unreadNoticeCount =>
      notices.where((n) => !n.isRead && n.status == 'Active').length;

  void _updateNotice(Map<String, dynamic> json) {
    final notice = DepartmentNotice.fromJson(json);
    notices.removeWhere((n) => n.id == notice.id);
    if (notice.status == 'Active') notices.add(notice);
    myNotices.removeWhere((n) => n.id == notice.id);
    if (json['published_by'] == authenticatedUser?['id']) myNotices.add(notice);
    const priorities = {'Urgent': 0, 'Important': 1, 'Normal': 2};
    for (final list in [notices, myNotices]) {
      list.sort((a, b) {
        final order = (priorities[a.priority] ?? 2).compareTo(
          priorities[b.priority] ?? 2,
        );
        return order != 0
            ? order
            : (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000));
      });
    }
    notifyListeners();
  }

  Future<void> publishNotice(
    Map<String, dynamic> data, {
    int? id,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    _updateNotice(
      await api.publishNotice(
        data,
        id: id,
        attachmentBytes: attachmentBytes,
        attachmentName: attachmentName,
      ),
    );
  }

  Future<void> loadMyNotices() async {
    final result = await api.fetchMyNotices();
    myNotices
      ..clear()
      ..addAll(result.map(DepartmentNotice.fromJson));
    notifyListeners();
  }

  Future<DepartmentNotice> openNotice(int id) async {
    final result = await api.openNotice(id);
    _updateNotice(result);
    for (final notification in notifications.where((n) => n.noticeId == id)) {
      notification.isRead = true;
    }
    notifyListeners();
    return DepartmentNotice.fromJson(result);
  }

  Future<void> deleteNotice(int id) async {
    await api.deleteNotice(id);
    notices.removeWhere((n) => n.id == id);
    myNotices.removeWhere((n) => n.id == id);
    notifications.removeWhere((n) => n.noticeId == id);
    notifyListeners();
  }

  Future<void> republishNotice(int id) async =>
      _updateNotice(await api.republishNotice(id));

  Future<void> refreshAnnouncements() async {
    if (_disposed || !signedIn || loadingData || _refreshingAnnouncements) {
      return;
    }
    _refreshingAnnouncements = true;
    final userId = authenticatedUser?['id'];
    try {
      final result = await Future.wait([
        api.fetchNotices(),
        api.fetchNotifications(),
      ]);
      if (_disposed || !signedIn || authenticatedUser?['id'] != userId) return;
      notices
        ..clear()
        ..addAll(result[0].map(DepartmentNotice.fromJson));
      notifications
        ..clear()
        ..addAll(result[1].map(AppNotification.fromJson));
      notifyListeners();
    } catch (_) {
      // Keep the last loaded board during a temporary connection failure.
    } finally {
      _refreshingAnnouncements = false;
    }
  }

  String get displayName =>
      authenticatedUser?['name']?.toString() ?? studentName;
  String get displayEmail =>
      authenticatedUser?['email']?.toString() ?? studentEmail;
  String get displayRegistrationNumber =>
      authenticatedUser?['registration_number']?.toString() ??
      studentRegistrationNumber;
  String get displayBatch => authenticatedUser?['batch']?.toString() ?? '2023';
  String get displaySemester =>
      authenticatedUser?['semester']?.toString() ?? '';
  String get displaySection => authenticatedUser?['section']?.toString() ?? 'A';
  String get displayMobileNumber =>
      authenticatedUser?['mobile_number']?.toString() ?? '';
  String get displayBatchAdviser =>
      (authenticatedUser?['batch_adviser'] as Map?)?['name']?.toString() ??
      'Not assigned';
  bool get studentApproved =>
      role != Role.student ||
      authenticatedUser?['account_status'] == 'approved';
  int get approvedStudentsCount =>
      int.tryParse(
        authenticatedUser?['approved_students_count']?.toString() ?? '',
      ) ??
      0;
  int get totalStudentsCount =>
      int.tryParse(
        authenticatedUser?['total_students_count']?.toString() ?? '',
      ) ??
      0;

  final complaints = <Complaint>[
    Complaint(
      id: 'CMP-24031',
      title: 'Lab computers are not working',
      details: 'Six systems in Lab 2 fail to boot.',
      category: 'Lab',
      priority: 'High',
      createdAt: DateTime.now(),
      status: Status.review,
      history: ['Complaint submitted', 'Received by adviser'],
    ),
    Complaint(
      id: 'CMP-24028',
      title: 'Result correction request',
      details: 'Sessional marks do not match the signed sheet.',
      category: 'Result',
      priority: 'Medium',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: Status.office,
      handler: 'Office',
      history: [
        'Complaint submitted',
        'Received by adviser',
        'Forwarded to chairman',
        'Sent to office',
      ],
    ),
    Complaint(
      id: 'CMP-24012',
      title: 'Internet connectivity in Room 7',
      details: 'Wi-Fi disconnects during lectures.',
      category: 'Internet',
      priority: 'Low',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      status: Status.resolved,
      handler: 'Closed',
      history: [
        'Complaint submitted',
        'Received by adviser',
        'Forwarded to chairman',
        'Resolved',
      ],
    ),
  ];

  final notifications = <AppNotification>[
    AppNotification(
      title: 'Complaint is under review',
      message: 'CMP-24031 has been received by your batch adviser.',
      time: '10 minutes ago',
      type: NotificationType.complaint,
    ),
    AppNotification(
      title: 'New department notice',
      message: 'The revised mid-term examination schedule is available.',
      time: '2 hours ago',
      type: NotificationType.notice,
    ),
    AppNotification(
      title: 'Complaint forwarded',
      message: 'CMP-24028 has been forwarded to the department office.',
      time: 'Yesterday',
      type: NotificationType.complaint,
      isRead: true,
    ),
    AppNotification(
      title: 'Account signed in',
      message: 'Your university account was used to access DCMCS.',
      time: '2 days ago',
      type: NotificationType.account,
      isRead: true,
    ),
  ];
  final notices = <DepartmentNotice>[];

  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> markNotificationRead(AppNotification notification) async {
    if (notification.isRead) return;
    if (notification.backendId != null) {
      await api.readNotification(notification.backendId!);
    }
    notification.isRead = true;
    for (final notice in notices.where((n) => n.id == notification.noticeId)) {
      notice.isRead = true;
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final unread = notifications
        .where((notification) => !notification.isRead)
        .toList();
    if (unread.isEmpty) return;

    for (final notification in unread) {
      notification.isRead = true;
    }
    notifyListeners();

    try {
      await api.readAllNotifications();
      for (final notice in notices.where(
        (n) => unread.any((item) => item.noticeId == n.id),
      )) {
        notice.isRead = true;
      }
      notifyListeners();
    } catch (_) {
      for (final notification in unread) {
        notification.isRead = false;
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> initialize() async {
    try {
      final profile = await api.restoreProfile();
      if (profile != null) {
        authenticatedUser = profile;
        role = Role.values.byName(profile['role'] as String);
        signedIn = true;
        await refreshData();
      }
    } catch (_) {
      dataError = 'Unable to restore the previous session.';
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    loadingData = true;
    dataError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.fetchComplaints(),
        api.fetchNotifications(),
        api.fetchNotices(),
        role == Role.adviser
            ? api.fetchPendingStudents()
            : role == Role.coordinator
            ? api.fetchAdviserApprovals()
            : Future.value(<Map<String, dynamic>>[]),
      ]);
      complaints
        ..clear()
        ..addAll(results[0].map(Complaint.fromJson));
      notifications
        ..clear()
        ..addAll(results[1].map(AppNotification.fromJson));
      notices
        ..clear()
        ..addAll(results[2].map(DepartmentNotice.fromJson));
      pendingStudents
        ..clear()
        ..addAll(
          role == Role.adviser
              ? results[3].map((item) => Map<String, dynamic>.from(item))
              : const [],
        );
      adviserApprovals
        ..clear()
        ..addAll(
          role == Role.coordinator
              ? results[3].map((item) => Map<String, dynamic>.from(item))
              : const [],
        );
    } on ApiException catch (error) {
      dataError = error.message;
    } catch (_) {
      dataError = 'Unable to load information from the server.';
    } finally {
      loadingData = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, Role value) async {
    authenticating = true;
    authenticationError = null;
    notifyListeners();
    try {
      final result = await api.login(
        email: email,
        password: password,
        role: value.name,
      );
      authenticatedUser = result.user;
      role = Role.values.byName(result.user['role'] as String);
      signedIn = true;
      await refreshData();
      return true;
    } on ApiException catch (error) {
      authenticationError = error.message;
      return false;
    } catch (_) {
      authenticationError =
          'Cannot connect to the DCMCS server. Please try again.';
      return false;
    } finally {
      authenticating = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String registrationNumber,
    required int semester,
    required String section,
    required String mobileNumber,
    required int batchAdviserId,
    required String password,
  }) async {
    authenticating = true;
    authenticationError = null;
    notifyListeners();
    try {
      await api.register(
        name: name,
        email: email,
        registrationNumber: registrationNumber,
        semester: semester,
        section: section,
        mobileNumber: mobileNumber,
        batchAdviserId: batchAdviserId,
        password: password,
      );
      return true;
    } on ApiException catch (error) {
      authenticationError = error.message;
      return false;
    } catch (_) {
      authenticationError =
          'Cannot connect to the DCMCS server. Please try again.';
      return false;
    } finally {
      authenticating = false;
      notifyListeners();
    }
  }

  Future<void> reviewStudent(int studentId, String action) async {
    await api.reviewStudent(studentId, action);
    pendingStudents.removeWhere((student) => student['id'] == studentId);
    if (action == 'approve' && authenticatedUser != null) {
      authenticatedUser!['approved_students_count'] = approvedStudentsCount + 1;
    }
    notifyListeners();
  }

  Future<void> reviewAdviser(int adviserId, String action) async {
    await api.reviewAdviser(adviserId, action);
    final adviser = adviserApprovals.firstWhere(
      (item) => item['id'] == adviserId,
    );
    adviser['account_status'] = action == 'approve' ? 'approved' : 'rejected';
    notifyListeners();
  }

  Future<void> addAdviser(Map<String, dynamic> data) async {
    final adviser = await api.addAdviser(data);
    adviserApprovals.insert(0, adviser);
    notifyListeners();
  }

  Future<void> checkApprovalStatus() async {
    authenticatedUser = await api.fetchProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Local sign-out must still complete if the server is unavailable.
    }
    signedIn = false;
    authenticatedUser = null;
    notices.clear();
    myNotices.clear();
    notifications.clear();
    complaints.clear();
    pendingStudents.clear();
    adviserApprovals.clear();
    tab = 0;
    notifyListeners();
  }

  void go(int index) {
    tab = index;
    notifyListeners();
  }

  Future<void> add(
    Complaint complaint, {
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final created = await api.createComplaint(
      {
        'title': complaint.title,
        'details': complaint.details,
        'category': complaint.category,
        'priority': complaint.priority,
      },
      attachmentBytes: attachmentBytes,
      attachmentName: attachmentName,
    );
    complaints.insert(0, Complaint.fromJson(created));
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> move(
    Complaint complaint,
    String action, {
    int? recipientId,
    String? remarks,
  }) async {
    if (complaint.backendId == null) return;
    final updated = await api.transitionComplaint(
      complaint.backendId!,
      action,
      recipientId: recipientId,
      remarks: remarks,
    );
    final index = complaints.indexWhere(
      (c) => c.backendId == complaint.backendId,
    );
    if (index >= 0) complaints[index] = Complaint.fromJson(updated);
    notifyListeners();
    // The routing operation has already succeeded even if notification refresh fails.
    try {
      await _refreshNotifications();
    } on ApiException {
      /* Retry on the next refresh. */
    }
  }

  Future<Complaint> openComplaint(int id) async {
    final complaint = Complaint.fromJson(await api.fetchComplaint(id));
    final index = complaints.indexWhere((c) => c.backendId == id);
    if (index >= 0) complaints[index] = complaint;
    notifyListeners();
    return complaint;
  }

  Future<void> addComplaintComment(Complaint complaint, String text) async {
    if (complaint.backendId == null) return;
    final created = await api.addComplaintComment(complaint.backendId!, text);
    complaint.comments.add(ComplaintComment.fromJson(created));
    notifyListeners();
  }

  Future<void> publishResolutionNotice(
    Complaint complaint, {
    required String title,
    required String body,
  }) async {
    if (complaint.backendId == null) return;
    await api.publishResolutionNotice(
      complaint.backendId!,
      title: title,
      body: body,
    );
    await refreshData();
  }

  Future<void> _refreshNotifications() async {
    final remote = await api.fetchNotifications();
    notifications
      ..clear()
      ..addAll(remote.map(AppNotification.fromJson));
  }
}
