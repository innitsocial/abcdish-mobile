import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/api_client.dart';

class ContestService {
  ContestService._internal();

  static final ContestService instance = ContestService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Contest>> fetchContests() async {
    final response = await _apiClient.get('/api/contests');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Contest.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic> && response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Contest.fromJson)
          .toList();
    }

    return [];
  }

  Future<void> submitEntry({
    required String contestId,
    required String title,
    required String videoUrl,
  }) async {
    await _apiClient.post(
      '/api/contests/$contestId/entries',
      body: {'title': title, 'videoUrl': videoUrl},
    );
  }
}
