import 'package:abcdish/models/app_session.dart';
import 'package:abcdish/services/api_client.dart';

class AppSessionService {
  AppSessionService._internal();

  static final AppSessionService instance = AppSessionService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<AppSession> fetchSession() async {
    final response = await _apiClient.get(
      '/api/app/session',
      timeout: const Duration(seconds: 6),
    );

    return AppSession.fromJson(response as Map<String, dynamic>);
  }
}
