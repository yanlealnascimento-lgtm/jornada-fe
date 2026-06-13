import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/character_repository.dart';
import '../../../shared/models/character_model.dart';

/// Lista completa de personagens ativos para a Galeria Bíblica.
final charactersProvider = FutureProvider.autoDispose<List<CharacterModel>>(
  (_) => characterRepository.fetchActiveCharacters(),
);

/// Personagem individual para tela de detalhe.
final characterByIdProvider = FutureProvider.autoDispose.family<CharacterModel, String>(
  (_, id) => characterRepository.fetchCharacterById(id),
);

/// Personagem atual da trilha (para usar nas lições).
/// Recebe o character_id que vem do TrailModel.
final trailCharacterProvider = FutureProvider.autoDispose.family<CharacterModel?, String?>(
  (_, characterId) async {
    if (characterId == null) return null;
    return characterRepository.fetchCharacterById(characterId);
  },
);

/// Personagem padrão do app (primeiro da lista - Caleb).
/// Usado como companheiro na trilha e nas lições quando não há personagem específico.
final defaultCharacterProvider = FutureProvider<CharacterModel?>((ref) async {
  try {
    final characters = await characterRepository.fetchActiveCharacters();
    if (characters.isEmpty) return null;
    return characters.first; // Caleb (sort_order: 1)
  } catch (_) {
    return null;
  }
});
