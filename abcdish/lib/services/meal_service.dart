import 'package:abcdish/models/meal.dart';
import 'package:abcdish/services/api_client.dart';

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
}
