import 'package:abcdish/models/meal.dart';
import 'package:abcdish/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealService {
  MealService._internal();

  static final MealService instance = MealService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Meal>> fetchMeals() async {
    final response = await _apiClient.get('/api/meals');

    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      return Meal.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  Future<List<Meal>> fetchManagedMeals() async {
    final response = await _apiClient.get('/api/meals/manage');

    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      return Meal.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  Future<Meal> fetchMeal(String id) async {
    final response = await _apiClient.get('/api/meals/$id');
    return Meal.fromJson(response as Map<String, dynamic>);
  }

  Future<Meal> createMeal({
    required String title,
    required String description,
    required String imageUrl,
    required String videoUrl,
    required String trailerUrl,
    required String trailerType,
    required String promoTrailerTitle,
    required String promoTrailerSubtitle,
    required int duration,
    required String complexity,
    required String affordability,
    required List<String> categories,
    required List<String> ingredients,
    required List<String> steps,
    required bool glutenFree,
    required bool lactoseFree,
    required bool vegan,
    required bool vegetarian,
  }) async {
    final response = await _apiClient.post(
      '/api/meals',
      body: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'trailerUrl': trailerUrl,
        'trailerType': trailerType,
        'promoTrailerTitle': promoTrailerTitle,
        'promoTrailerSubtitle': promoTrailerSubtitle,
        'duration': duration,
        'complexity': complexity,
        'affordability': affordability,
        'categories': categories,
        'ingredients': ingredients,
        'steps': steps,
        'glutenFree': glutenFree,
        'lactoseFree': lactoseFree,
        'vegan': vegan,
        'vegetarian': vegetarian,
      },
    );

    return Meal.fromJson(response as Map<String, dynamic>);
  }

  Future<Meal> updateMeal({
    required String id,
    required String title,
    required String description,
    required String imageUrl,
    required String videoUrl,
    required String trailerUrl,
    required String trailerType,
    required String promoTrailerTitle,
    required String promoTrailerSubtitle,
    required int duration,
    required String complexity,
    required String affordability,
    required List<String> categories,
    required List<String> ingredients,
    required List<String> steps,
    required bool glutenFree,
    required bool lactoseFree,
    required bool vegan,
    required bool vegetarian,
  }) async {
    final response = await _apiClient.put(
      '/api/meals/$id',
      body: {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'trailerUrl': trailerUrl,
        'trailerType': trailerType,
        'promoTrailerTitle': promoTrailerTitle,
        'promoTrailerSubtitle': promoTrailerSubtitle,
        'duration': duration,
        'complexity': complexity,
        'affordability': affordability,
        'categories': categories,
        'ingredients': ingredients,
        'steps': steps,
        'glutenFree': glutenFree,
        'lactoseFree': lactoseFree,
        'vegan': vegan,
        'vegetarian': vegetarian,
      },
    );

    return Meal.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteMeal(String id) async {
    await _apiClient.delete('/api/meals/$id');
  }

  Future<String> uploadRecipeTrailer(String filePath) async {
    final response = await _apiClient.uploadFile(
      '/api/media/recipe-trailer',
      fieldName: 'file',
      filePath: filePath,
    );

    if (response is Map<String, dynamic>) {
      return response['publicUrl']?.toString() ?? '';
    }

    return '';
  }

  Future<String> uploadRecipeVideo(String filePath) async {
    final response = await _apiClient.uploadFile(
      '/api/media/recipe-video',
      fieldName: 'file',
      filePath: filePath,
    );

    if (response is Map<String, dynamic>) {
      return response['publicUrl']?.toString() ?? '';
    }

    return '';
  }

  Future<Map<String, dynamic>> createDraft({
    required String sourceType,
    required String sourceUrl,
    String titleHint = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'en';

    final response = await _apiClient.post(
      '/api/meals/draft',
      body: {
        'sourceType': sourceType,
        'sourceUrl': sourceUrl,
        'titleHint': titleHint,
        'languageCode': languageCode,
      },
    );

    return response as Map<String, dynamic>;
  }
}
