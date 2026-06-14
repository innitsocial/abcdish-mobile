class Story {
  const Story({
    required this.id,
    required this.userId,
    required this.title,
    required this.caption,
    required this.creatorName,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.expiresAt,
    this.moderationStatus = 'APPROVED',
    this.moderationReason = '',
    this.viewCount = 0,
    this.likeCount = 0,
    this.likedByCurrentUser = false,
  });

  final String id;
  final int userId;
  final String title;
  final String caption;
  final String creatorName;
  final String imageUrl;
  final String videoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String moderationStatus;
  final String moderationReason;
  final int viewCount;
  final int likeCount;
  final bool likedByCurrentUser;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'].toString(),
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      creatorName: json['creatorName'] ?? 'ABCDish Creator',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      moderationStatus: json['moderationStatus'] ?? 'APPROVED',
      moderationReason: json['moderationReason'] ?? '',
      viewCount: _intFromJson(json['viewCount']),
      likeCount: _intFromJson(json['likeCount']),
      likedByCurrentUser: json['likedByCurrentUser'] == true,
    );
  }

  Story copyWith({int? viewCount, int? likeCount, bool? likedByCurrentUser}) {
    return Story(
      id: id,
      userId: userId,
      title: title,
      caption: caption,
      creatorName: creatorName,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      createdAt: createdAt,
      expiresAt: expiresAt,
      moderationStatus: moderationStatus,
      moderationReason: moderationReason,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
    );
  }
}

class StoryViewer {
  const StoryViewer({
    required this.userId,
    required this.name,
    required this.viewedAt,
  });

  final int userId;
  final String name;
  final DateTime viewedAt;

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: _intFromJson(json['userId']),
      name: json['name']?.toString() ?? 'ABCDish Foodie',
      viewedAt:
          DateTime.tryParse(json['viewedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

int _intFromJson(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
