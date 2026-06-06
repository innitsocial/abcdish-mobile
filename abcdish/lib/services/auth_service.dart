import 'package:abcdish/services/api_client.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<void> requestRegisterEmailOtp({
    required String name,
    required String email,
  }) async {
    await _apiClient.post(
      '/api/auth/register/email/request-otp',
      body: {'name': name, 'email': email},
    );
  }

  Future<void> verifyRegisterEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register/email/verify-otp',
      body: {'destination': email, 'otp': otp},
    );

    await _saveAuthResponse(response);
  }

  Future<void> requestEmailOtp(String email) async {
    await _apiClient.post(
      '/api/auth/email/request-otp',
      body: {'destination': email},
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/email/verify-otp',
      body: {'destination': email, 'otp': otp},
    );

    await _saveAuthResponse(response);
  }

  Future<void> refreshToken() async {
    final refreshToken = await _apiClient.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token found');
    }

    final response = await _apiClient.post(
      '/api/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    await _saveAuthResponse(response);
  }

  Future<void> logout() async {
    final refreshToken = await _apiClient.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.post(
          '/api/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // Still clear local tokens even if backend logout fails.
      }
    }

    await _apiClient.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveAuthResponse(dynamic response) async {
    final accessToken = response['token']?.toString();
    final refreshToken = response['refreshToken']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Access token missing from response');
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Refresh token missing from response');
    }

    await _apiClient.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
