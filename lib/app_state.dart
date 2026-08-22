import 'package:flutter/material.dart';

import 'api_service.dart';

const navy = Color(0xFF0B1F3A);
const green = Color(0xFF16A085);
const canvas = Color(0xFFF4F7FB);

const studentName = 'Hawa Sabir';
const studentRegistrationNumber = '2023-CS-001';
const studentEmail = '2023cs001@uetmardan.edu.pk';

enum Role { student, adviser, coordinator, chairman, office, dean }

enum Status { submitted, review, forwarded, office, dean, resolved, rejected }

extension RoleName on Role {
  String get label => const [
    'Student',
    'Batch Adviser',
    'Coordinator',
    'Chairman',
    'Office Staff',
    'Dean',
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
  ][index];

  Color get color => this == Status.resolved
      ? const Color(0xFF16835C)
      : this == Status.rejected
      ? const Color(0xFFD64545)
      : (this == Status.office || this == Status.dean)
      ? const Color(0xFFE28A19)
      : const Color(0xFF3867D6);
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
    List<String>? history,
  }) : history = history ?? ['Complaint submitted'];

  final int? backendId;
  final String id, title, details, category, priority;
  final DateTime createdAt;
  Status status;
  String handler;
  final List<String> history;

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
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: Status.values.byName(json['status']?.toString() ?? 'submitted'),
      handler: handler == 'closed'
          ? 'Closed'
          : Role.values
                    .where((role) => role.name == handler)
                    .map((role) => role.label)
                    .firstOrNull ??
                handler,
      history: history.isEmpty ? ['Complaint submitted'] : history,
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
  });

  final int? backendId;
  final String title, message, time;
  final NotificationType type;
  bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? 'account';
    return AppNotification(
      backendId: json['id'] as int?,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
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
  const DepartmentNotice({
    required this.title,
    required this.body,
    required this.meta,
  });
  final String title, body, meta;

  factory DepartmentNotice.fromJson(
    Map<String, dynamic> json,
  ) => DepartmentNotice(
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    meta:
        '${json['audience'] == 'all' ? 'All users' : json['audience']} · ${_relativeTime(json['published_at']?.toString())}',
  );
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
  bool signedIn = false;
  bool authenticating = false;
  bool initializing = true;
  bool loadingData = false;
  String? authenticationError;
  String? dataError;
  Role role = Role.student;
  int tab = 0;
  Map<String, dynamic>? authenticatedUser;

  String get displayName =>
      authenticatedUser?['name']?.toString() ?? studentName;
  String get displayEmail =>
      authenticatedUser?['email']?.toString() ?? studentEmail;
  String get displayRegistrationNumber =>
      authenticatedUser?['registration_number']?.toString() ??
      studentRegistrationNumber;
  String get displayBatch => authenticatedUser?['batch']?.toString() ?? '2023';
  String get displaySection => authenticatedUser?['section']?.toString() ?? 'A';

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
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await api.readAllNotifications();
    for (final notification in notifications) {
      notification.isRead = true;
    }
    notifyListeners();
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

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Local sign-out must still complete if the server is unavailable.
    }
    signedIn = false;
    authenticatedUser = null;
    tab = 0;
    notifyListeners();
  }

  void go(int index) {
    tab = index;
    notifyListeners();
  }

  Future<void> add(Complaint complaint) async {
    final created = await api.createComplaint({
      'title': complaint.title,
      'details': complaint.details,
      'category': complaint.category,
      'priority': complaint.priority,
    });
    complaints.insert(0, Complaint.fromJson(created));
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> move(Complaint complaint, String action) async {
    if (complaint.backendId == null) return;
    final updated = await api.transitionComplaint(complaint.backendId!, action);
    final index = complaints.indexOf(complaint);
    if (index >= 0) complaints[index] = Complaint.fromJson(updated);
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> _refreshNotifications() async {
    final remote = await api.fetchNotifications();
    notifications
      ..clear()
      ..addAll(remote.map(AppNotification.fromJson));
  }
}
