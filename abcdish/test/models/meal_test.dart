import 'package:abcdish/models/meal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Meal.fromJson', () {
    test('maps backend meal fields into the app model', () {
      final meal = Meal.fromJson({
        'id': 42,
        'categories': ['breakfast', 'vegetarian'],
        'title': 'Masala Omelette',
        'imageUrl': 'https://cdn.abcdish.com/omelette.jpg',
        'videoUrl': 'https://cdn.abcdish.com/omelette.mp4',
        'description': 'A quick spiced breakfast.',
        'ingredients': ['eggs', 'onion', 'chilli'],
        'steps': ['Beat eggs', 'Cook until set'],
        'duration': 12,
        'complexity': 'challenging',
        'affordability': 'affordable',
        'glutenFree': true,
        'lactoseFree': true,
        'vegan': false,
        'vegetarian': true,
      });

      expect(meal.id, '42');
      expect(meal.categories, ['breakfast', 'vegetarian']);
      expect(meal.title, 'Masala Omelette');
      expect(meal.videoUrl, 'https://cdn.abcdish.com/omelette.mp4');
      expect(meal.ingredients, ['eggs', 'onion', 'chilli']);
      expect(meal.steps, ['Beat eggs', 'Cook until set']);
      expect(meal.duration, 12);
      expect(meal.complexity, Complexity.challenging);
      expect(meal.affordability, Affordability.affordable);
      expect(meal.isGlutenFree, isTrue);
      expect(meal.isLactoseFree, isTrue);
      expect(meal.isVegan, isFalse);
      expect(meal.isVegetarian, isTrue);
    });

    test('uses safe defaults for optional or unexpected backend fields', () {
      final meal = Meal.fromJson({
        'id': 'draft-1',
        'complexity': 'unknown',
        'affordability': 'unknown',
      });

      expect(meal.id, 'draft-1');
      expect(meal.categories, isEmpty);
      expect(meal.title, isEmpty);
      expect(meal.imageUrl, isEmpty);
      expect(meal.videoUrl, isEmpty);
      expect(meal.description, isEmpty);
      expect(meal.ingredients, isEmpty);
      expect(meal.steps, isEmpty);
      expect(meal.duration, 0);
      expect(meal.complexity, Complexity.simple);
      expect(meal.affordability, Affordability.affordable);
      expect(meal.isGlutenFree, isFalse);
      expect(meal.isLactoseFree, isFalse);
      expect(meal.isVegan, isFalse);
      expect(meal.isVegetarian, isFalse);
    });
  });
}
