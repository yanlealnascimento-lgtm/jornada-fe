import 'package:flutter/foundation.dart';
import '../../../shared/models/mission_model.dart';
import '../../../shared/services/http_client.dart';

class MissionRepository {
  /// Fetches all active achievements from the API and groups them
  /// into daily, weekly, and one_time categories.
  Future<Map<String, List<UserMissionModel>>> fetchAchievements() async {
    try {
      final r = await HttpClient.instance.get('/achievements');
      final data = r.data;

      // API returns { data: [...] } or just [...]
      final List rawList;
      if (data is Map && data['data'] != null) {
        rawList = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }

      final all = rawList
          .map((j) => UserMissionModel.fromJson(j as Map<String, dynamic>))
          .toList();

      return {
        'daily': all.where((a) => a.cycle == 'daily').toList(),
        'weekly': all.where((a) => a.cycle == 'weekly').toList(),
        'one_time': all.where((a) => a.cycle == 'one_time' || a.cycle.isEmpty).toList(),
      };
    } catch (e) {
      debugPrint('[MissionRepository] Erro ao buscar conquistas: $e');
      rethrow;
    }
  }
}

final missionRepository = MissionRepository();
