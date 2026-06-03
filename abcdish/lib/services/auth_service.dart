import 'package:abcdish/services/api_client.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'identifier': identifier, 'password': password},
    );

    await _saveAuthResponse(response);
  }

  Future<void> register({
    required String name,
    String? email,
    String? mobileNumber,
    String? password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      body: {
        'name': name,
        'email': email,
        'mobileNumber': mobileNumber,
        'password': password,
      },
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

  Future<void> requestMobileOtp(String mobileNumber) async {
    await _apiClient.post(
      '/api/auth/mobile/request-otp',
      body: {'destination': mobileNumber},
    );
  }

  Future<void> verifyMobileOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/mobile/verify-otp',
      body: {'destination': mobileNumber, 'otp': otp},
    );

    await _saveAuthResponse(response);
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post('/api/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/api/auth/reset-password',
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
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
