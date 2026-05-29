import 'package:flutter/material.dart';

import 'package:meals/models/category.dart';
import 'package:meals/models/meal.dart';

const availableCategories = [
  Category(id: 'c1', title: 'Indian', color: Colors.orange),
  Category(id: 'c2', title: 'Italian', color: Colors.red),
  Category(id: 'c3', title: 'Quick & Easy', color: Colors.green),
  Category(id: 'c4', title: 'Breakfast', color: Colors.blue),
  Category(id: 'c5', title: 'Healthy', color: Colors.teal),
];

const dummyMeals = [
  Meal(
    id: 'm1',
    categories: ['c1', 'c3'],
    title: 'Butter Chicken',
    imageUrl: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398',
    videoUrl:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    description: 'Creamy and rich Indian butter chicken recipe.',
    ingredients: [
      '500g Chicken',
      'Butter',
      'Cream',
      'Tomato Puree',
      'Garlic',
      'Ginger',
      'Spices',
    ],
    steps: [
      'Marinate chicken with spices.',
      'Cook onions, garlic and ginger.',
      'Add tomato puree.',
      'Cook chicken.',
      'Add butter and cream.',
      'Serve hot with rice or naan.',
    ],
    duration: 45,
    complexity: Complexity.challenging,
    affordability: Affordability.pricey,
    isGlutenFree: true,
    isLactoseFree: false,
    isVegan: false,
    isVegetarian: false,
    color: Colors.orange,
  ),

  Meal(
    id: 'm2',
    categories: ['c2'],
    title: 'Margherita Pizza',
    imageUrl: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143',
    videoUrl:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    description: 'Classic Italian pizza with mozzarella and basil.',
    ingredients: [
      'Pizza Dough',
      'Tomato Sauce',
      'Mozzarella',
      'Fresh Basil',
      'Olive Oil',
    ],
    steps: [
      'Prepare pizza dough.',
      'Spread tomato sauce.',
      'Add mozzarella cheese.',
      'Bake until crispy.',
      'Top with fresh basil.',
    ],
    duration: 30,
    complexity: Complexity.simple,
    affordability: Affordability.affordable,
    isGlutenFree: false,
    isLactoseFree: false,
    isVegan: false,
    isVegetarian: true,
    color: Colors.red,
  ),

  Meal(
    id: 'm3',
    categories: ['c4', 'c5'],
    title: 'Avocado Toast',
    imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d',
    videoUrl:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    description: 'Healthy avocado toast for a quick breakfast.',
    ingredients: [
      'Bread',
      'Avocado',
      'Lemon',
      'Salt',
      'Pepper',
      'Chilli Flakes',
    ],
    steps: [
      'Toast the bread.',
      'Mash avocado.',
      'Add lemon, salt and pepper.',
      'Spread on toast.',
      'Top with chilli flakes.',
    ],
    duration: 10,
    complexity: Complexity.simple,
    affordability: Affordability.affordable,
    isGlutenFree: false,
    isLactoseFree: true,
    isVegan: true,
    isVegetarian: true,
    color: Colors.green,
  ),

  Meal(
    id: 'm4',
    categories: ['c5'],
    title: 'Grilled Salmon Bowl',
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554',
    videoUrl:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    description: 'Healthy salmon bowl packed with protein.',
    ingredients: ['Salmon', 'Rice', 'Avocado', 'Cucumber', 'Soy Sauce'],
    steps: [
      'Season salmon.',
      'Grill salmon.',
      'Cook rice.',
      'Prepare vegetables.',
      'Assemble bowl and serve.',
    ],
    duration: 25,
    complexity: Complexity.simple,
    affordability: Affordability.luxurious,
    isGlutenFree: true,
    isLactoseFree: true,
    isVegan: false,
    isVegetarian: false,
    color: Colors.teal,
  ),
];
