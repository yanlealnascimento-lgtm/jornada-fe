class TrailModel {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final int orderIndex;
  final List<UnitModel> units;

  const TrailModel({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.orderIndex,
    required this.units,
  });

  factory TrailModel.fromJson(Map<String, dynamic> json) {
    return TrailModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      orderIndex: json['order_index'] ?? 0,
      units: (json['units'] as List<dynamic>? ?? [])
          .map((u) => UnitModel.fromJson(u))
          .toList(),
    );
  }
}

class UnitModel {
  final String id;
  final String title;
  final String description;
  final String? color;
  final int orderIndex;
  final List<LessonModel> lessons;

  const UnitModel({
    required this.id,
    required this.title,
    required this.description,
    this.color,
    required this.orderIndex,
    required this.lessons,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      color: json['color'],
      orderIndex: json['order_index'] ?? 0,
      lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((l) => LessonModel.fromJson(l))
          .toList(),
    );
  }
}

enum LessonStatus { completed, available, locked, current }

class LessonModel {
  final String id;
  final String title;
  final int orderIndex;
  final bool isReview;
  final LessonStatus status;
  final List<ExerciseModel> exercises;
  final int stagesCount;

  const LessonModel({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.isReview,
    required this.status,
    required this.exercises,
    this.stagesCount = 0,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json, {LessonStatus status = LessonStatus.locked}) {
    return LessonModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? json['order'] ?? 0,
      isReview: json['is_review'] ?? json['lesson_type'] == 'review' ?? false,
      status: status,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => ExerciseModel.fromJson(e))
          .toList(),
      stagesCount: (json['stages_count'] as num?)?.toInt() ?? 0,
    );
  }
}

enum ExerciseType {
  multipleChoice,
  fillBlank,
  wordOrder,
  association,
  trueFalse,
  emojiGuess,   // Adivinhe o personagem/livro pelos emojis
  audioRecite,  // Recite o versículo em voz alta
}

class ExerciseModel {
  final String id;
  final ExerciseType type;
  final String question;
  final String? imageUrl;
  final String? verseReference;
  final List<String> options;
  final dynamic correctAnswer;
  final String? explanation;
  final bool isPremium;      // Exercício exclusivo para assinantes
  final String? emojiHint;   // Emojis usados no tipo emojiGuess

  const ExerciseModel({
    required this.id,
    required this.type,
    required this.question,
    this.imageUrl,
    this.verseReference,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.isPremium = false,
    this.emojiHint,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    ExerciseType type;
    // Aceita tanto uppercase (legado) quanto lowercase (API atual)
    switch ((json['type'] as String? ?? '').toUpperCase()) {
      case 'FILL_BLANK':
        type = ExerciseType.fillBlank;
        break;
      case 'WORD_ORDER':
      case 'SORT_WORDS':
        type = ExerciseType.wordOrder;
        break;
      case 'ASSOCIATION':
      case 'PAIR_MATCH':
        type = ExerciseType.association;
        break;
      case 'TRUE_FALSE':
        type = ExerciseType.trueFalse;
        break;
      case 'EMOJI_GUESS':
        type = ExerciseType.emojiGuess;
        break;
      case 'AUDIO_RECITE':
        type = ExerciseType.audioRecite;
        break;
      default:
        type = ExerciseType.multipleChoice;
    }

    // Suporta tanto options_text (API standalone) quanto options (legado lista de strings)
    final rawOptions = json['options_text'] ?? json['options'] ?? [];
    final List<String> options;
    if (rawOptions is List) {
      options = rawOptions.whereType<String>().toList();
    } else {
      options = [];
    }

    return ExerciseModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: type,
      question: json['question'] ?? '',
      imageUrl: json['image_url'] ?? json['context_image_url'],
      verseReference: json['verse_reference'],
      options: options,
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      isPremium: json['is_premium'] ?? false,
      emojiHint: json['emoji_hint'],
    );
  }
}
