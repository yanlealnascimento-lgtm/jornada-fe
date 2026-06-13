import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/mission_model.dart';
import '../data/mission_repository.dart';

final missionsProvider =
    FutureProvider.autoDispose<Map<String, List<UserMissionModel>>>((ref) async {
  return missionRepository.fetchAchievements();
});
