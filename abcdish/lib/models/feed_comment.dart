class FeedComment {
  const FeedComment({
    required this.id,
    required this.mealId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final int mealId;
  final int userId;
  final String text;
  final DateTime? createdAt;

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] ?? 0,
      mealId: json['mealId'] ?? 0,
      userId: json['userId'] ?? 0,
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
