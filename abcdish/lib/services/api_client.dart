import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:abcdish/config/app_config.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =========================
  // GET
  // =========================

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================
  // POST
  // =========================

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  // =========================
  // PUT
  // =========================

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  // =========================
  // DELETE
  // =========================

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================
  // SAVE JWT TOKEN
  // =========================

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // =========================
  // GET JWT TOKEN
  // =========================

  Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  // =========================
  // CLEAR TOKEN
  // =========================

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // =========================
  // RESPONSE HANDLER
  // =========================

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw Exception('API Error (${response.statusCode}): ${response.body}');
  }
}
