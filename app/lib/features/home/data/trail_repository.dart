import 'package:flutter/foundation.dart';
import '../../../shared/models/trail_model.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/models/lesson_progress_model.dart';
import '../../../shared/services/http_client.dart';

class TrailRepository {
  /// Busca todas as trilhas publicadas da API.
  Future<List<ApiTrailModel>> fetchPublishedTrails({String? companyId}) async {
    try {
      final response = await HttpClient.instance.get(
        '/trails',
        queryParams: {
          if (companyId != null) 'company_id': companyId,
        },
      );
      final data = response.data;
      final List trails = (data is Map)
          ? (data['data']?['trails'] ?? data['trails'] ?? []) as List
          : [];
      return trails
          .map((json) => ApiTrailModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TrailRepository] Erro ao buscar trilhas: $e');
      rethrow;
    }
  }

  /// Busca trilha por ID.
  Future<ApiTrailModel> fetchTrailById(String id) async {
    final response = await HttpClient.instance.get('/trails/$id');
    final data = response.data;
    final trail = (data is Map && data['data'] != null) ? data['data'] : data;
    return ApiTrailModel.fromJson(trail as Map<String, dynamic>);
  }

  /// Busca units + lessons de uma trilha (endpoint novo).
  Future<TrailModel> fetchTrailWithUnits(String trailId) async {
    final response = await HttpClient.instance.get('/trails/$trailId/units');
    final data = response.data;
    final payload = (data is Map && data['data'] != null)
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;

    final trailJson = payload['trail'] as Map<String, dynamic>? ?? {};
    final unitsList = payload['units'] as List? ?? [];

    final units = unitsList.map((u) {
      final unitMap = u as Map<String, dynamic>;
      return UnitModel(
        id: unitMap['_id']?.toString() ?? unitMap['id']?.toString() ?? '',
        title: unitMap['title'] ?? '',
        description: unitMap['description'] ?? '',
        color: unitMap['color_hex'],
        orderIndex: (unitMap['order'] as num?)?.toInt() ?? 0,
        lessons: (unitMap['lessons'] as List? ?? []).map((l) {
          final lm = l as Map<String, dynamic>;
          return LessonModel(
            id: lm['_id']?.toString() ?? lm['id']?.toString() ?? '',
            title: lm['title'] ?? '',
            orderIndex: (lm['order'] as num?)?.toInt() ?? 0,
            isReview: lm['lesson_type'] == 'review',
            status: LessonStatus.locked,
            exercises: [],
            stagesCount: (lm['stages_count'] as num?)?.toInt() ?? 0,
          );
        }).toList(),
      );
    }).toList();

    return TrailModel(
      id: trailJson['_id']?.toString() ?? trailJson['id']?.toString() ?? trailId,
      title: trailJson['title'] ?? '',
      description: trailJson['description'] ?? '',
      thumbnailUrl: trailJson['thumbnail_url'],
      orderIndex: (trailJson['order'] as num?)?.toInt() ?? 0,
      units: units,
    );
  }

  /// Busca exercicios de uma licao especifica.
  Future<List<ExerciseModel>> fetchExercisesForLesson(String lessonId) async {
    final response = await HttpClient.instance.get('/exercises/lesson/$lessonId');
    final data = response.data;
    final list = (data is Map && data['data'] != null)
        ? data['data'] as List
        : (data is List ? data : []);
    return list
        .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Stage-based methods ──────────────────────────────────────────────────

  /// Fetches progress for a single lesson (stages info).
  Future<LessonProgressModel> fetchLessonProgress(String lessonId, {String? userId}) async {
    try {
      final response = await HttpClient.instance.get(
        '/lessons/$lessonId/progress',
        queryParams: {if (userId != null) 'user_id': userId},
      );
      final data = response.data;
      final payload = (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : (data is Map ? data as Map<String, dynamic> : <String, dynamic>{});
      return LessonProgressModel.fromJson({...payload, 'lesson_id': lessonId});
    } catch (e) {
      debugPrint('[TrailRepository] fetchLessonProgress error: $e');
      return LessonProgressModel.initial(lessonId);
    }
  }

  /// Fetches bulk progress for all lessons in a trail.
  Future<List<LessonProgressModel>> fetchBulkProgress(
    String trailId, {
    required String userId,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/lessons/progress/bulk',
        queryParams: {'user_id': userId, 'trail_id': trailId},
      );
      final data = response.data;
      final list = (data is Map && data['data'] != null)
          ? data['data'] as List
          : (data is List ? data : []);
      return list
          .map((e) => LessonProgressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TrailRepository] fetchBulkProgress error: $e');
      return [];
    }
  }

  /// Starts a lesson and returns the first stage exercises.
  Future<Map<String, dynamic>> startLesson(String lessonId, {required String userId}) async {
    try {
      final response = await HttpClient.instance.post(
        '/lessons/$lessonId/start',
        data: {'user_id': userId},
      );
      final data = response.data;
      return (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : (data is Map ? data as Map<String, dynamic> : <String, dynamic>{});
    } catch (e) {
      debugPrint('[TrailRepository] startLesson error: $e');
      return {};
    }
  }

  /// Completes a stage and returns the result.
  Future<Map<String, dynamic>> completeStage(
    String lessonId,
    int stageIndex,
    int pfEarned,
    bool hadError, {
    required String userId,
  }) async {
    try {
      final response = await HttpClient.instance.post(
        '/lessons/$lessonId/stages/$stageIndex/complete',
        data: {
          'user_id': userId,
          'pf_earned': pfEarned,
          'had_error': hadError,
        },
      );
      final data = response.data;
      return (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : (data is Map ? data as Map<String, dynamic> : <String, dynamic>{});
    } catch (e) {
      debugPrint('[TrailRepository] completeStage error: $e');
      return {};
    }
  }

  /// Fetches exercises for a specific stage of a lesson.
  /// Falls back to fetching all lesson exercises if stage endpoint fails.
  Future<List<ExerciseModel>> fetchStageExercises(
    String lessonId,
    int stageIndex,
  ) async {
    try {
      final response = await HttpClient.instance.get(
        '/lessons/$lessonId/stages/$stageIndex/exercises',
      );
      final data = response.data;
      final list = (data is Map && data['data'] != null)
          ? data['data'] as List
          : (data is List ? data : []);
      return list
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TrailRepository] fetchStageExercises error, falling back to lesson exercises: $e');
      // Fallback: fetch all exercises for the lesson
      return fetchExercisesForLesson(lessonId);
    }
  }
  /// Fetches random review exercises (~50%) from all stages of a lesson.
  Future<List<ExerciseModel>> fetchReviewExercises(String lessonId) async {
    try {
      final response = await HttpClient.instance.get(
        '/lessons/$lessonId/review-exercises',
      );
      final data = response.data;
      final list = (data is Map && data['data'] != null)
          ? data['data'] as List
          : (data is List ? data : []);
      return list
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TrailRepository] fetchReviewExercises error: $e');
      return fetchExercisesForLesson(lessonId);
    }
  }
}

final trailRepository = TrailRepository();
