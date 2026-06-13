import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/lesson_model.dart';
import '../../shared/models/lesson_progress_model.dart';
import '../../shared/models/trail_model.dart';
import '../../features/home/data/trail_repository.dart';
import 'user_provider.dart';

// ── Catalogo de trilhas da API ──────────────────────────────────────────────
final trailCatalogProvider = FutureProvider.autoDispose<List<ApiTrailModel>>((ref) async {
  try {
    return await trailRepository.fetchPublishedTrails();
  } catch (e) {
    debugPrint('[trailCatalogProvider] API indisponivel, usando fallback: $e');
    return [];
  }
});

// Provider de trilha individual por ID
final trailByIdProvider = FutureProvider.autoDispose.family<ApiTrailModel, String>(
  (ref, id) async => trailRepository.fetchTrailById(id),
);

// ── Trilhas com unidades e licoes (integrado com API) ────────────────────────
// Busca trilhas publicadas, depois carrega units+lessons + progresso real.
final trailListProvider = FutureProvider<List<TrailModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final userId = user?.id;

  try {
    // 1. Buscar catalogo de trilhas publicadas (filtrar so as que tem units)
    final allTrails = await trailRepository.fetchPublishedTrails();
    final catalog = allTrails.where((t) => t.totalUnits > 0).toList();
    if (catalog.isEmpty) return [];

    // 2. Para cada trilha, buscar units + lessons + progresso real
    final trails = <TrailModel>[];
    for (final apiTrail in catalog) {
      try {
        final trail = await trailRepository.fetchTrailWithUnits(apiTrail.id);

        // 3. Buscar progresso real das lições do usuario
        Map<String, LessonProgressModel> progressMap = {};
        if (userId != null && userId.isNotEmpty) {
          final bulkProgress = await trailRepository.fetchBulkProgress(
            apiTrail.id,
            userId: userId,
          );
          for (final p in bulkProgress) {
            progressMap[p.lessonId] = p;
          }
        }

        // 4. Aplicar status baseado no progresso real
        final withProgress = _applyRealProgress(trail, progressMap);
        trails.add(withProgress);
      } catch (e) {
        debugPrint('[trailListProvider] Erro ao carregar trail ${apiTrail.id}: $e');
      }
    }

    // Filtrar trilhas sem unidades e ordenar
    trails.removeWhere((t) => t.units.isEmpty);
    trails.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return trails;
  } catch (e) {
    debugPrint('[trailListProvider] Erro geral: $e');
    return [];
  }
});

/// Busca o ID da primeira lição da primeira trilha publicada.
/// Usado para navegar direto para a primeira lição após o onboarding/registro.
/// Retorna null se nenhuma trilha/lição estiver disponível.
Future<String?> fetchFirstLessonId(WidgetRef ref) async {
  try {
    final trails = await ref.read(trailListProvider.future);
    for (final trail in trails) {
      for (final unit in trail.units) {
        for (final lesson in unit.lessons) {
          return lesson.id;
        }
      }
    }
  } catch (e) {
    debugPrint('[fetchFirstLessonId] Erro: $e');
  }
  return null;
}

// Provider para a proxima licao disponivel
final nextLessonProvider = Provider<LessonModel?>((ref) {
  final trails = ref.watch(trailListProvider).valueOrNull;
  if (trails == null) return null;

  for (final trail in trails) {
    for (final unit in trail.units) {
      for (final lesson in unit.lessons) {
        if (lesson.status == LessonStatus.current ||
            lesson.status == LessonStatus.available) {
          return lesson;
        }
      }
    }
  }
  return null;
});

/// Aplica status de progresso baseado no progresso REAL da API.
/// Uma lição é "completed" somente quando o backend confirma status=completed.
/// A primeira lição não-completed é "current", as demais são "locked".
TrailModel _applyRealProgress(
  TrailModel trail,
  Map<String, LessonProgressModel> progressMap,
) {
  bool foundCurrent = false;

  final updatedUnits = trail.units.map((unit) {
    final updatedLessons = unit.lessons.map((lesson) {
      final progress = progressMap[lesson.id];

      LessonStatus status;
      if (progress != null && progress.isCompleted) {
        status = LessonStatus.completed;
      } else if (!foundCurrent) {
        // First non-completed lesson is "current"
        status = LessonStatus.current;
        foundCurrent = true;
      } else {
        status = LessonStatus.locked;
      }

      return LessonModel(
        id: lesson.id,
        title: lesson.title,
        orderIndex: lesson.orderIndex,
        isReview: lesson.isReview,
        status: status,
        exercises: lesson.exercises,
        stagesCount: lesson.stagesCount,
      );
    }).toList();

    return UnitModel(
      id: unit.id,
      title: unit.title,
      description: unit.description,
      color: unit.color,
      orderIndex: unit.orderIndex,
      lessons: updatedLessons,
    );
  }).toList();

  return TrailModel(
    id: trail.id,
    title: trail.title,
    description: trail.description,
    thumbnailUrl: trail.thumbnailUrl,
    orderIndex: trail.orderIndex,
    units: updatedUnits,
  );
}
