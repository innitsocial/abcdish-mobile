import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/api_client.dart';

class ContestService {
  ContestService._internal();

  static final ContestService instance = ContestService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Contest>> fetchContests() async {
    final response = await _apiClient.get('/api/contests');
    final data = response is List
        ? response
        : response['content'] ?? response['items'] ?? [];
    return (data as List)
        .map((item) => Contest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> joinContest({
    required String contestId,
    required String title,
    required String description,
    required String videoUrl,
  }) async {
    await _apiClient.post(
      '/api/contests/$contestId/entries',
      body: {'title': title, 'description': description, 'videoUrl': videoUrl},
    );
  }
}
