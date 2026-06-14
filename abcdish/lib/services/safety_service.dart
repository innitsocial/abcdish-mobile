import 'package:abcdish/services/api_client.dart';

class SafetyService {
  SafetyService._internal();

  static final SafetyService instance = SafetyService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String details = '',
  }) async {
    await _apiClient.post(
      '/api/safety/reports',
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        'details': details,
      },
    );
  }
}
