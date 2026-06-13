import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/lesson_model.dart';
import '../../features/home/data/trail_repository.dart';

/// Provider que retorna exercicios de uma licao especifica via API.
/// ✅ FIX BUG 1: Nao engolir erros — deixar o .when() do consumer tratar
final exercisesByLessonProvider =
    FutureProvider.autoDispose.family<List<ExerciseModel>, String>(
  (ref, lessonId) async {
    debugPrint('[exercisesByLessonProvider] Buscando exercicios para: $lessonId');
    return await trailRepository.fetchExercisesForLesson(lessonId);
  },
);
