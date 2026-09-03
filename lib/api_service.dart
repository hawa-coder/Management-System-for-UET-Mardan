import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _storage = FlutterSecureStorage();
  String? _token;

  String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/login'),
          headers: const {'Accept': 'application/json'},
          body: {
            'email': email.trim().toLowerCase(),
            'password': password,
            'role': role,
          },
        )
        .timeout(const Duration(seconds: 15));

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(body), response.statusCode);
    }

    final token = body['token'] as String;
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
    return AuthResult(
      token: token,
      user: Map<String, dynamic>.from(body['user'] as Map),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String registrationNumber,
    required int semester,
    required String section,
    required String mobileNumber,
    required int batchAdviserId,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/register'),
          headers: const {'Accept': 'application/json'},
          body: {
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'registration_number': registrationNumber.trim().toUpperCase(),
            'semester': semester.toString(),
            'section': section.trim().toUpperCase(),
            'mobile_number': mobileNumber.trim(),
            'batch_adviser_id': batchAdviserId.toString(),
            'password': password,
            'password_confirmation': password,
          },
        )
        .timeout(const Duration(seconds: 15));

    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_errorMessage(body), response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdvisers() async {
    final body = await get('/advisers');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPendingStudents() async {
    final body = await get('/student-approvals');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> reviewStudent(int studentId, String action) async {
    await post('/student-approvals/$studentId', {'action': action});
  }

  Future<List<Map<String, dynamic>>> fetchAdviserApprovals() async {
    final body = await get('/adviser-approvals');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> reviewAdviser(int adviserId, String action) async {
    await post('/adviser-approvals/$adviserId', {'action': action});
  }

  Future<Map<String, dynamic>> addAdviser(Map<String, dynamic> data) async {
    final body = await post('/adviser-approvals', data);
    return Map<String, dynamic>.from(body['adviser'] as Map);
  }

  Future<String> forgotPassword(String email) async {
    final body = await post('/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
    return body['message']?.toString() ?? 'Reset code sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final body = await post('/reset-password', {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': password,
    });
    return body['message']?.toString() ?? 'Password reset successfully.';
  }

  Future<String> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    final body = await post('/change-password', {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': password,
    });
    return body['message']?.toString() ?? 'Password changed successfully.';
  }

  Future<void> logout() async {
    final token = _token ?? await _storage.read(key: 'auth_token');
    if (token != null) {
      await _client.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }
    await _storage.delete(key: 'auth_token');
    _token = null;
  }

  Future<Map<String, dynamic>?> restoreProfile() async {
    _token = await _storage.read(key: 'auth_token');
    if (_token == null) return null;
    try {
      return await get('/profile');
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        _token = null;
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchProfile() => get('/profile');

  Future<List<Map<String, dynamic>>> fetchComplaints() async {
    final body = await get('/complaints');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createComplaint(
    Map<String, dynamic> data, {
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/complaints'),
    );
    request.headers.addAll(await _headers());
    request.fields.addAll(
      data.map((key, value) => MapEntry(key, value.toString())),
    );
    if (attachmentBytes != null && attachmentName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          attachmentBytes,
          filename: attachmentName,
        ),
      );
    }
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    return _handle(await http.Response.fromStream(streamed));
  }

  String absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}${path.startsWith('/') ? path : '/$path'}';
  }

  Future<Map<String, dynamic>> transitionComplaint(int id, String action) =>
      post('/complaints/$id/transition', {'action': action});

  Future<Map<String, dynamic>> addComplaintComment(int id, String comment) =>
      post('/complaints/$id/comments', {'comment': comment});

  Future<Map<String, dynamic>> publishResolutionNotice(
    int id, {
    required String title,
    required String body,
  }) => post('/complaints/$id/publish-resolution', {
    'title': title,
    'body': body,
  });

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final body = await get('/notifications');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> readNotification(int id) async {
    await post('/notifications/$id/read', const {});
  }

  Future<void> readAllNotifications() async {
    await post('/notifications/read-all', const {});
  }

  Future<List<Map<String, dynamic>>> fetchNotices() async {
    final body = await get('/notices');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$path'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handle(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(json: true),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(response);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    _token ??= await _storage.read(key: 'auth_token');
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Map<String, dynamic> _handle(http.Response response) {
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body), response.statusCode);
    }
    return body;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw ApiException(
        'The server returned an invalid response.',
        response.statusCode,
      );
    }
  }

  String _errorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return body['message']?.toString() ?? 'Unable to complete the request.';
  }
}
