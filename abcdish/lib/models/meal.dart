import 'package:flutter/material.dart';

enum Complexity { simple, challenging, hard }

enum Affordability { affordable, pricey, luxurious }

class Meal {
  const Meal({
    required this.id,
    required this.categories,
    required this.title,
    required this.imageUrl,
    required this.videoUrl,
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
  });

  final String id;

  final List<String> categories;

  final String title;

  // Thumbnail / cover image
  final String imageUrl;

  // Cooking video URL
  final String videoUrl;

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

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: (json['id'] ?? json['mealId']).toString(),
      categories: List<String>.from(json['categories'] ?? []),
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
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
    );
  }
}
