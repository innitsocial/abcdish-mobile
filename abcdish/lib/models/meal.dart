import 'package:flutter/material.dart';

enum Complexity { simple, challenging, hard }

enum Affordability { affordable, pricey, luxurious }

class Meal {
  const Meal({
    required this.id,
    required this.recipeCode,
    required this.categories,
    required this.title,
    required this.imageUrl,
    required this.videoUrl,
    required this.trailerUrl,
    required this.trailerType,
    required this.promoTrailerTitle,
    required this.promoTrailerSubtitle,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.duration,
    required this.complexity,
    required this.affordability,
    required this.isGlutenFree,
    required this.isLactoseFree,
    required this.isVegan,
    required this.isVegetarian,
    required this.color,
    this.sourceType = 'RECIPE',
    this.creatorKey = 'abcdish',
    this.creatorName = 'ABCDish Kitchen',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.likedByCurrentUser = false,
    this.followedByCurrentUser = false,
    this.contestId,
    this.acceptanceThreshold = 0,
    this.acceptedMealId,
    this.reviewUnlocked = false,
    this.competitionCategory = 'admin',
    this.competitionStatus = 'OFFICIAL_RECIPE',
    this.finalistRank,
    this.londonQualified = false,
    this.prizeAmountGbp,
    this.moderationStatus = 'APPROVED',
    this.moderationReason = '',
  });

  final String id;

  final String recipeCode;

  final List<String> categories;

  final String title;

  // Thumbnail / cover image
  final String imageUrl;

  // Cooking video URL
  final String videoUrl;

  // Short 30-second feed trailer hosted by ABCDish
  final String trailerUrl;

  final String trailerType;

  final String promoTrailerTitle;

  final String promoTrailerSubtitle;

  // Short recipe description
  final String description;

  final List<String> ingredients;

  final List<String> steps;

  // Cooking duration in minutes
  final int duration;

  final Complexity complexity;

  final Affordability affordability;

  final bool isGlutenFree;

  final bool isLactoseFree;

  final bool isVegan;

  final bool isVegetarian;

  final Color color;

  final String sourceType;

  final String creatorKey;

  final String creatorName;

  final int likeCount;

  final int commentCount;

  final int shareCount;

  final bool likedByCurrentUser;

  final bool followedByCurrentUser;

  final String? contestId;

  final int acceptanceThreshold;

  final String? acceptedMealId;

  final bool reviewUnlocked;

  final String competitionCategory;

  final String competitionStatus;

  final int? finalistRank;

  final bool londonQualified;

  final int? prizeAmountGbp;

  final String moderationStatus;

  final String moderationReason;

  factory Meal.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['mealId']).toString();
    final numericId = int.tryParse(id);

    return Meal(
      id: id,
      recipeCode:
          json['recipeCode']?.toString() ??
          (numericId == null ? id : (10000 + numericId).toString()),
      categories: List<String>.from(json['categories'] ?? []),
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      trailerUrl: json['trailerUrl'] ?? '',
      trailerType: json['trailerType'] ?? '',
      promoTrailerTitle: json['promoTrailerTitle'] ?? '',
      promoTrailerSubtitle: json['promoTrailerSubtitle'] ?? '',
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      duration: json['duration'] ?? 0,
      complexity: Complexity.values.firstWhere(
        (value) => value.name == json['complexity'],
        orElse: () => Complexity.simple,
      ),
      affordability: Affordability.values.firstWhere(
        (value) => value.name == json['affordability'],
        orElse: () => Affordability.affordable,
      ),
      isGlutenFree: json['glutenFree'] ?? false,
      isLactoseFree: json['lactoseFree'] ?? false,
      isVegan: json['vegan'] ?? false,
      isVegetarian: json['vegetarian'] ?? false,
      color: Colors.orange,
      sourceType: json['sourceType'] ?? 'RECIPE',
      creatorKey: json['creatorKey'] ?? 'abcdish',
      creatorName: json['creatorName'] ?? 'ABCDish Kitchen',
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] ?? false,
      followedByCurrentUser: json['followedByCurrentUser'] ?? false,
      contestId: json['contestId']?.toString(),
      acceptanceThreshold: _intFromJson(json['acceptanceThreshold']),
      acceptedMealId: json['acceptedMealId']?.toString(),
      reviewUnlocked: json['reviewUnlocked'] ?? false,
      competitionCategory:
          json['competitionCategory']?.toString() ??
          (json['sourceType'] == 'CONTEST_ENTRY' ? 'main' : 'admin'),
      competitionStatus:
          json['competitionStatus']?.toString() ??
          (json['sourceType'] == 'CONTEST_ENTRY'
              ? 'VOTING'
              : 'OFFICIAL_RECIPE'),
      finalistRank: json['finalistRank'] == null
          ? null
          : _intFromJson(json['finalistRank']),
      londonQualified: json['londonQualified'] == true,
      prizeAmountGbp: json['prizeAmountGbp'] == null
          ? null
          : _intFromJson(json['prizeAmountGbp']),
      moderationStatus: json['moderationStatus'] ?? 'APPROVED',
      moderationReason: json['moderationReason'] ?? '',
    );
  }

  bool get isContestEntry => sourceType == 'CONTEST_ENTRY';

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
