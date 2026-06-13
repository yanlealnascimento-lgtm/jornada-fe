/// Represents stage-level progress for a single lesson.
class LessonProgressModel {
  final String lessonId;
  final int stagesTotal; // 1-5 (default 1 for backward compat)
  final int stagesCompleted; // 0..stagesTotal
  final int currentStage; // next stage to do (0-indexed)
  final String status; // not_started | in_progress | completed
  final int pfEarned;
  final bool perfect;

  const LessonProgressModel({
    required this.lessonId,
    required this.stagesTotal,
    required this.stagesCompleted,
    required this.currentStage,
    required this.status,
    this.pfEarned = 0,
    this.perfect = false,
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isNotStarted => status == 'not_started';

  /// Fraction 0.0 - 1.0 for how many stages are done.
  double get progressFraction =>
      stagesTotal > 0 ? stagesCompleted / stagesTotal : 0.0;

  /// Creates an initial (no progress) model for a lesson.
  static LessonProgressModel initial(String lessonId, {int stagesTotal = 1}) {
    return LessonProgressModel(
      lessonId: lessonId,
      stagesTotal: stagesTotal,
      stagesCompleted: 0,
      currentStage: 0,
      status: 'not_started',
    );
  }

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) {
    final total = (json['stages_total'] as num?)?.toInt() ??
        (json['stagesTotal'] as num?)?.toInt() ??
        1;
    final completed = (json['stages_completed'] as num?)?.toInt() ??
        (json['stagesCompleted'] as num?)?.toInt() ??
        0;
    return LessonProgressModel(
      lessonId: (json['lesson_id'] ?? json['lessonId'] ?? '') as String,
      stagesTotal: total,
      stagesCompleted: completed,
      currentStage: (json['current_stage'] as num?)?.toInt() ??
          (json['currentStage'] as num?)?.toInt() ??
          completed,
      status: (json['status'] as String?) ?? 'not_started',
      pfEarned: (json['pf_earned'] as num?)?.toInt() ??
          (json['xp_earned'] as num?)?.toInt() ??
          0,
      perfect: (json['perfect'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'stages_total': stagesTotal,
        'stages_completed': stagesCompleted,
        'current_stage': currentStage,
        'status': status,
        'pf_earned': pfEarned,
        'perfect': perfect,
      };
}
