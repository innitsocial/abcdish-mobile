import 'dart:convert';

import 'package:abcdish/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _languageStorageKey = 'app_language';

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    final languageCode = await _languageCode();

    return {
      'Content-Type': 'application/json',
      'Accept-Language': languageCode,
      'X-ABCDish-Language': languageCode,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    final languageCode = await _languageCode();

    return {
      'Accept-Language': languageCode,
      'X-ABCDish-Language': languageCode,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> _languageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageStorageKey) ?? 'en';
  }

  Future<dynamic> get(
    String path, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _sendWithRefresh(
      () async => http
          .get(Uri.parse('$apiBaseUrl$path'), headers: await _headers())
          .timeout(timeout),
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

  Future<dynamic> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
  }) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl$path'),
      );

      request.headers.addAll(await _authHeaders());
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      return http.Response.fromStream(streamedResponse);
    }

    final response = await _sendWithRefresh(send);

    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await _sendWithRefresh(
      () async => http
          .put(
            Uri.parse('$apiBaseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15)),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _sendWithRefresh(
      () async => http
          .delete(Uri.parse('$apiBaseUrl$path'), headers: await _headers())
          .timeout(const Duration(seconds: 15)),
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
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 8));

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
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {
      // Ignore keychain cleanup failures so app startup never crashes.
    }
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

    throw ApiException(statusCode: statusCode, message: message);
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message.isEmpty ? 'HTTP $statusCode' : message;
}
