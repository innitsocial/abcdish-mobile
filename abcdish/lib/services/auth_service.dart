import 'package:meals/services/api_client.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    final token = response['token'] as String;

    await _apiClient.saveToken(token);

    return token;
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );

    final token = response['token'] as String;

    await _apiClient.saveToken(token);

    return token;
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _apiClient.logout();
  }
}
