import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/contest_service.dart';

final contestsProvider = FutureProvider<List<Contest>>((ref) async {
  try {
    return ContestService.instance.fetchContests();
  } catch (_) {
    return const [];
  }
});
