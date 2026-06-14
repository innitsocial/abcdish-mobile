class Story {
  const Story({
    required this.id,
    required this.title,
    required this.caption,
    required this.creatorName,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    this.moderationStatus = 'APPROVED',
    this.moderationReason = '',
  });

  final String id;
  final String title;
  final String caption;
  final String creatorName;
  final String imageUrl;
  final String videoUrl;
  final DateTime createdAt;
  final String moderationStatus;
  final String moderationReason;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      creatorName: json['creatorName'] ?? 'ABCDish Creator',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      moderationStatus: json['moderationStatus'] ?? 'APPROVED',
      moderationReason: json['moderationReason'] ?? '',
    );
  }
}
