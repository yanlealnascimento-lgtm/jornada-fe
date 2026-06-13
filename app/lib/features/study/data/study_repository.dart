import 'package:flutter/foundation.dart';
import '../../../shared/models/bible_study_model.dart';
import '../../../shared/services/http_client.dart';

class StudyRepository {
  /// Busca lista de estudos publicados com filtros opcionais.
  Future<List<BibleStudyModel>> fetchStudies({
    String? category,
    String? difficulty,
    String? search,
    bool? featured,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        '/studies',
        queryParams: {
          if (category != null) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
          if (search != null && search.isNotEmpty) 'search': search,
          if (featured != null) 'featured': featured.toString(),
        },
      );
      final data = response.data;
      final List list = (data is Map)
          ? (data['data']?['studies'] ?? data['studies'] ?? data['data'] ?? []) as List
          : (data is List ? data : []);
      return list
          .map((json) => BibleStudyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao buscar estudos: $e');
      rethrow;
    }
  }

  /// Busca detalhes completos de um estudo por slug (com lessons embarcados).
  Future<BibleStudyModel> fetchStudyDetail(String slug) async {
    try {
      final response = await HttpClient.instance.get('/studies/$slug');
      final data = response.data;
      final payload = (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return BibleStudyModel.fromJson(payload);
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao buscar estudo "$slug": $e');
      rethrow;
    }
  }

  /// Inicia/solicita acesso a um estudo. Retorna se o acesso foi concedido.
  Future<StudyAccessResult> startStudy(
    String slug,
    String userId,
    bool userIsPremium,
  ) async {
    try {
      final response = await HttpClient.instance.post(
        '/studies/$slug/start',
        data: {
          'user_id': userId,
          'is_premium': userIsPremium,
        },
      );
      final data = response.data;
      final payload = (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return StudyAccessResult.fromJson(payload);
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao iniciar estudo "$slug": $e');
      rethrow;
    }
  }

  /// Busca explicacao gerada por IA para uma licao especifica.
  Future<String> fetchAIExplanation(String slug, int lessonIndex) async {
    try {
      final response = await HttpClient.instance.get(
        '/studies/$slug/lessons/$lessonIndex/explanation',
      );
      final data = response.data;
      if (data is Map) {
        return (data['data']?['explanation'] ??
                data['explanation'] ??
                '') as String;
      }
      return data?.toString() ?? '';
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao buscar explicacao AI: $e');
      rethrow;
    }
  }

  /// Marca uma licao como completa e registra PF ganho.
  Future<void> completeLesson(
    String slug,
    int lessonIndex,
    String userId,
    int pfEarned,
  ) async {
    try {
      await HttpClient.instance.post(
        '/studies/$slug/lessons/$lessonIndex/complete',
        data: {
          'user_id': userId,
          'pf_earned': pfEarned,
        },
      );
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao completar licao: $e');
      rethrow;
    }
  }

  /// Busca progresso do usuario em um estudo especifico.
  Future<StudyProgress> fetchProgress(String slug, String userId) async {
    try {
      final response = await HttpClient.instance.get(
        '/studies/$slug/progress',
        queryParams: {'user_id': userId},
      );
      final data = response.data;
      final payload = (data is Map && data['data'] != null)
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return StudyProgress.fromJson(payload);
    } catch (e) {
      debugPrint('[StudyRepository] Erro ao buscar progresso: $e');
      rethrow;
    }
  }
}

final studyRepository = StudyRepository();
