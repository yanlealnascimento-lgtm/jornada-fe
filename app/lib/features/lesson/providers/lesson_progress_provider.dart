import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/models/lesson_progress_model.dart';
import '../../home/data/trail_repository.dart';

/// Fetches progress for a single lesson (with user_id when logged in).
final lessonProgressProvider =
    FutureProvider.autoDispose.family<LessonProgressModel, String>(
  (ref, lessonId) async {
    final userId = ref.watch(currentUserProvider).valueOrNull?.id;
    return await trailRepository.fetchLessonProgress(lessonId, userId: userId);
  },
);

/// Fetches exercises for a specific stage of a lesson.
final stageExercisesProvider = FutureProvider.autoDispose
    .family<List<ExerciseModel>, StageExerciseParams>(
  (ref, params) async {
    return await trailRepository.fetchStageExercises(
      params.lessonId,
      params.stageIndex,
    );
  },
);

/// Fetches bulk progress for all lessons in a trail.
final bulkLessonProgressProvider =
    FutureProvider.autoDispose.family<Map<String, LessonProgressModel>, String>(
  (ref, trailId) async {
    final userId = ref.watch(currentUserProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return {};
    final list = await trailRepository.fetchBulkProgress(trailId, userId: userId);
    return {for (final p in list) p.lessonId: p};
  },
);

/// Fetches review exercises (random ~50% from all stages).
final reviewExercisesProvider = FutureProvider.autoDispose
    .family<List<ExerciseModel>, String>(
  (ref, lessonId) async {
    return await trailRepository.fetchReviewExercises(lessonId);
  },
);

/// Parameter class for stageExercisesProvider.
class StageExerciseParams {
  final String lessonId;
  final int stageIndex;

  const StageExerciseParams({
    required this.lessonId,
    required this.stageIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageExerciseParams &&
          other.lessonId == lessonId &&
          other.stageIndex == stageIndex;

  @override
  int get hashCode => Object.hash(lessonId, stageIndex);
}
