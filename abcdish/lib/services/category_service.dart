import 'package:abcdish/models/category.dart';
import 'package:abcdish/services/api_client.dart';

class CategoryService {
  CategoryService._internal();

  static final CategoryService instance = CategoryService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.get('/api/categories');

    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      return Category.fromJson(item as Map<String, dynamic>);
    }).toList();
  }
}
