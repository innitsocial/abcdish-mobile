import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/category.dart';
import 'package:abcdish/services/category_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return CategoryService.instance.fetchCategories();
});
