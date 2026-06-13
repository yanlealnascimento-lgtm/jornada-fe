import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/bible_study_model.dart';
import '../../features/study/data/study_repository.dart';
import 'user_provider.dart';

// ── Lista de estudos publicados ─────────────────────────────────────────────

final studiesProvider = FutureProvider.autoDispose
    .family<List<BibleStudyModel>, StudyFilter>((ref, filter) async {
  try {
    return await studyRepository.fetchStudies(
      category: filter.category,
      difficulty: filter.difficulty,
      search: filter.search,
      featured: filter.featured,
    );
  } catch (e) {
    debugPrint('[studiesProvider] Erro ao buscar estudos: $e');
    return [];
  }
});

/// Busca todos os estudos sem filtro (atalho).
final allStudiesProvider = FutureProvider.autoDispose<List<BibleStudyModel>>((ref) async {
  try {
    return await studyRepository.fetchStudies();
  } catch (e) {
    debugPrint('[allStudiesProvider] Erro: $e');
    return [];
  }
});

/// Estudos em destaque.
final featuredStudiesProvider = FutureProvider.autoDispose<List<BibleStudyModel>>((ref) async {
  try {
    return await studyRepository.fetchStudies(featured: true);
  } catch (e) {
    debugPrint('[featuredStudiesProvider] Erro: $e');
    return [];
  }
});

// ── Detalhe de um estudo por slug ───────────────────────────────────────────

final studyDetailProvider = FutureProvider.autoDispose
    .family<BibleStudyModel, String>((ref, slug) async {
  return await studyRepository.fetchStudyDetail(slug);
});

// ── Acesso / start de um estudo ─────────────────────────────────────────────

final studyAccessProvider = FutureProvider.autoDispose
    .family<StudyAccessResult, String>((ref, slug) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final userId = user?.id ?? '';
  final isPremium = user?.leagueTier == 'diamond'; // simplificacao MVP
  return await studyRepository.startStudy(slug, userId, isPremium);
});

// ── Progresso do usuario em um estudo ───────────────────────────────────────

final studyProgressProvider = FutureProvider.autoDispose
    .family<StudyProgress, String>((ref, slug) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return const StudyProgress(
      studyId: '',
      userId: '',
      completedLessons: 0,
      totalLessons: 0,
      pfEarned: 0,
      isCompleted: false,
    );
  }
  try {
    return await studyRepository.fetchProgress(slug, user.id);
  } catch (e) {
    debugPrint('[studyProgressProvider] Erro: $e');
    return StudyProgress(
      studyId: slug,
      userId: user.id,
      completedLessons: 0,
      totalLessons: 0,
      pfEarned: 0,
      isCompleted: false,
    );
  }
});

// ── Explicacao IA para uma licao ────────────────────────────────────────────

final aiExplanationProvider = FutureProvider.autoDispose
    .family<String, AIExplanationParams>((ref, params) async {
  try {
    return await studyRepository.fetchAIExplanation(params.slug, params.lessonIndex);
  } catch (e) {
    debugPrint('[aiExplanationProvider] Erro: $e');
    return 'Nao foi possivel carregar a explicacao. Tente novamente.';
  }
});

// ── Filtro de estudos ───────────────────────────────────────────────────────

class StudyFilter {
  final String? category;
  final String? difficulty;
  final String? search;
  final bool? featured;

  const StudyFilter({this.category, this.difficulty, this.search, this.featured});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          difficulty == other.difficulty &&
          search == other.search &&
          featured == other.featured;

  @override
  int get hashCode => Object.hash(category, difficulty, search, featured);
}

class AIExplanationParams {
  final String slug;
  final int lessonIndex;

  const AIExplanationParams({required this.slug, required this.lessonIndex});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIExplanationParams &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          lessonIndex == other.lessonIndex;

  @override
  int get hashCode => Object.hash(slug, lessonIndex);
}
