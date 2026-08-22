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

  Future<List<Map<String, dynamic>>> fetchComplaints() async {
    final body = await get('/complaints');
    return (body['data'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createComplaint(Map<String, dynamic> data) =>
      post('/complaints', data);

  Future<Map<String, dynamic>> transitionComplaint(int id, String action) =>
      post('/complaints/$id/transition', {'action': action});

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
