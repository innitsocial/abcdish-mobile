import 'package:flutter/material.dart';

enum Complexity {
  simple,
  challenging,
  hard,
}

enum Affordability {
  affordable,
  pricey,
  luxurious,
}

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
}