import 'dart:convert';

import 'package:abcdish/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await _sendWithRefresh(
      () async =>
          http.get(Uri.parse('$apiBaseUrl$path'), headers: await _headers()),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _sendWithRefresh(
      () async => http
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15)),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await _sendWithRefresh(
      () async => http.put(
        Uri.parse('$apiBaseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _sendWithRefresh(
      () async =>
          http.delete(Uri.parse('$apiBaseUrl$path'), headers: await _headers()),
    );

    return _handleResponse(response);
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();

    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _tryRefreshToken();

    if (!refreshed) {
      await clearTokens();
      return response;
    }

    return request();
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final newAccessToken = decoded['token']?.toString();
      final newRefreshToken = decoded['refreshToken']?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return false;
      }

      await saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (error) {
      await clearTokens();
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (error) {
      await clearTokens();
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    String message = response.body;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      // Keep raw response body.
    }

    throw Exception(message);
  }
}
