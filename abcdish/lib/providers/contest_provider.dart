import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/contest_service.dart';

final contestsProvider = FutureProvider<List<Contest>>((ref) async {
  return ContestService.instance.fetchContests();
});
