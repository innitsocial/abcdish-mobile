class ContestEntry {
  const ContestEntry({
    required this.id,
    required this.contestId,
    required this.userId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.votes,
    required this.approved,
    required this.likedByCurrentUser,
    required this.acceptanceThreshold,
    this.acceptedMealId,
    required this.soundFreeConfirmed,
    required this.aiNarrationRequested,
    required this.narrationStatus,
    required this.competitionCategory,
    required this.competitionStatus,
    this.finalistRank,
    required this.londonQualified,
    this.prizeAmountGbp,
    required this.moderationStatus,
    required this.moderationReason,
  });

  final String id;
  final String contestId;
  final int userId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int votes;
  final bool approved;
  final bool likedByCurrentUser;
  final int acceptanceThreshold;
  final String? acceptedMealId;
  final bool soundFreeConfirmed;
  final bool aiNarrationRequested;
  final String narrationStatus;
  final String competitionCategory;
  final String competitionStatus;
  final int? finalistRank;
  final bool londonQualified;
  final int? prizeAmountGbp;
  final String moderationStatus;
  final String moderationReason;

  factory ContestEntry.fromJson(Map<String, dynamic> json) {
    return ContestEntry(
      id: json['id']?.toString() ?? '',
      contestId: json['contestId']?.toString() ?? '',
      userId: _intFromJson(json['userId']),
      title: json['title']?.toString() ?? 'Contest entry',
      description: json['description']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      votes: _intFromJson(json['votes']),
      approved: json['approved'] == true,
      likedByCurrentUser: json['likedByCurrentUser'] == true,
      acceptanceThreshold: _intFromJson(json['acceptanceThreshold']),
      acceptedMealId: json['acceptedMealId']?.toString(),
      soundFreeConfirmed: json['soundFreeConfirmed'] == true,
      aiNarrationRequested: json['aiNarrationRequested'] != false,
      narrationStatus: json['narrationStatus']?.toString() ?? 'PENDING_REVIEW',
      competitionCategory: json['competitionCategory']?.toString() ?? 'main',
      competitionStatus:
          json['competitionStatus']?.toString() ?? 'PENDING_ADMIN_REVIEW',
      finalistRank: json['finalistRank'] == null
          ? null
          : _intFromJson(json['finalistRank']),
      londonQualified: json['londonQualified'] == true,
      prizeAmountGbp: json['prizeAmountGbp'] == null
          ? null
          : _intFromJson(json['prizeAmountGbp']),
      moderationStatus:
          json['moderationStatus']?.toString() ?? 'PENDING_REVIEW',
      moderationReason: json['moderationReason']?.toString() ?? '',
    );
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
