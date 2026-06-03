import 'package:abcdish/models/meal.dart';

class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.videoUrl,
    required this.creatorName,
    required this.mealId,
    required this.likesCount,
    required this.commentsCount,
    required this.isContestEntry,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final String creatorName;
  final String? mealId;
  final int likesCount;
  final int commentsCount;
  final bool isContestEntry;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['mealTitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl:
          json['imageUrl']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      creatorName:
          json['creatorName']?.toString() ??
          json['authorName']?.toString() ??
          'ABCDish',
      mealId: json['mealId']?.toString(),
      likesCount: int.tryParse(json['likesCount']?.toString() ?? '') ?? 0,
      commentsCount: int.tryParse(json['commentsCount']?.toString() ?? '') ?? 0,
      isContestEntry:
          json['contestEntry'] == true || json['isContestEntry'] == true,
    );
  }

  factory FeedItem.fromMeal(Meal meal) {
    return FeedItem(
      id: meal.id,
      title: meal.title,
      description: meal.description,
      imageUrl: meal.imageUrl,
      videoUrl: meal.videoUrl,
      creatorName: 'ABCDish Kitchen',
      mealId: meal.id,
      likesCount: 0,
      commentsCount: 0,
      isContestEntry: false,
    );
  }
}
