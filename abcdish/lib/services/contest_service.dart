import 'package:abcdish/models/contest.dart';
import 'package:abcdish/models/contest_entry.dart';
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

  Future<String> submitEntry({
    required String contestId,
    required String title,
    required String description,
    required String videoUrl,
    required bool soundFreeConfirmed,
    required String competitionCategory,
    String thumbnailUrl = '',
    int duration = 30,
  }) async {
    final response = await _apiClient.post(
      '/api/contests/$contestId/entries',
      body: {
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
        'complexity': 'simple',
        'competitionCategory': competitionCategory,
        'categories': ['contest'],
        'ingredients': ['See cooking video'],
        'steps': ['Watch the contest cooking video and cook along.'],
        'glutenFree': false,
        'lactoseFree': false,
        'vegan': false,
        'vegetarian': false,
        'soundFreeConfirmed': soundFreeConfirmed,
        'aiNarrationRequested': true,
      },
    );

    if (response is Map<String, dynamic>) {
      return response['moderationStatus']?.toString() ?? 'PENDING_REVIEW';
    }

    return 'PENDING_REVIEW';
  }

  Future<List<ContestEntry>> fetchEntries(String contestId) async {
    final response = await _apiClient.get('/api/contests/$contestId/entries');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ContestEntry.fromJson)
          .toList();
    }

    return [];
  }

  Future<ContestEntry> likeEntry(String entryId) async {
    final response = await _apiClient.post(
      '/api/contests/entries/$entryId/likes',
    );
    return ContestEntry.fromJson(response as Map<String, dynamic>);
  }

  Future<ContestEntry> unlikeEntry(String entryId) async {
    final response = await _apiClient.delete(
      '/api/contests/entries/$entryId/likes',
    );
    return ContestEntry.fromJson(response as Map<String, dynamic>);
  }
}
