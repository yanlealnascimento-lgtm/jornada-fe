import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/gamification_model.dart';
import '../../shared/services/http_client.dart';
import 'user_provider.dart';

// Provider da liga do usuario
final leagueProvider = FutureProvider<LeagueData>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) throw Exception('Usuario nao autenticado');

  try {
    final response = await HttpClient.instance.get(
      '/leagues/me',
      queryParams: {'user_id': user.id},
    );
    final data = response.data;
    final payload = (data is Map && data['data'] != null) ? data['data'] : data;
    return LeagueData.fromJson(payload as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[leagueProvider] Erro ao buscar liga: $e');
    rethrow;
  }
});

// Provider de conquistas
final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];

  try {
    final response = await HttpClient.instance.get('/achievements?user_id=${user.id}');
    final data = response.data;

    List items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      final payload = data['data'];
      if (payload is List) {
        items = payload;
      } else if (payload is Map) {
        items = payload['achievements'] ?? payload['items'] ?? payload['docs'] ?? [];
      } else {
        items = [];
      }
    } else {
      items = [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((a) => AchievementModel.fromJson(a))
        .toList();
  } catch (e) {
    debugPrint('[achievementsProvider] Erro ao buscar conquistas: $e');
    return [];
  }
});

// Provider de personagens
final charactersProvider = FutureProvider<List<CharacterModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];

  try {
    final response = await HttpClient.instance.get('/characters?user_id=${user.id}');
    final data = response.data;

    // Extrai a lista de personagens de forma robusta
    List items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      final payload = data['data'];
      if (payload is List) {
        items = payload;
      } else if (payload is Map) {
        // Backend pode retornar { data: { characters: [...] } } ou { data: { items: [...] } }
        items = payload['characters'] ?? payload['items'] ?? payload['docs'] ?? [];
      } else {
        items = [];
      }
    } else {
      items = [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((c) => CharacterModel.fromJson(c))
        .toList();
  } catch (e) {
    debugPrint('[charactersProvider] Erro ao buscar personagens: $e');
    return [];
  }
});
