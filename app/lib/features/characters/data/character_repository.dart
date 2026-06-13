import 'package:flutter/foundation.dart';
import '../../../shared/models/character_model.dart';
import '../../../shared/services/http_client.dart';

class CharacterRepository {
  /// Lista todos os personagens ativos (para Galeria Bíblica).
  Future<List<CharacterModel>> fetchActiveCharacters() async {
    try {
      final response = await HttpClient.instance.get('/characters');
      final data = response.data;
      final List characters = (data is Map)
          ? (data['data']?['characters'] ?? data['characters'] ?? []) as List
          : [];
      return characters
          .map((json) => CharacterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CharacterRepository] Erro ao buscar personagens: $e');
      rethrow;
    }
  }

  /// Busca personagem por ID (para tela de detalhe na Galeria).
  Future<CharacterModel> fetchCharacterById(String id) async {
    final response = await HttpClient.instance.get('/characters/$id');
    final data = response.data;
    final character = (data is Map && data['data'] != null) ? data['data'] : data;
    return CharacterModel.fromJson(character as Map<String, dynamic>);
  }
}

final characterRepository = CharacterRepository();
