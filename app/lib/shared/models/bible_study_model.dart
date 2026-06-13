/// Models para Estudos Biblicos (Bible Studies).
/// Corresponde ao retorno de GET /api/v1/studies/:slug

class BibleStudyModel {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? thumbnailUrl;
  final String category;
  final String difficulty; // beginner, intermediate, advanced
  final bool isPremium;
  final bool isPublished;
  final bool isFeatured;
  final int totalLessons;
  final double estimatedMinutes;
  final StudyCharacter? character;
  final List<StudyLesson> lessons;
  final String? verseReference;
  final String? verseText;
  final int pfReward;
  final DateTime? createdAt;

  const BibleStudyModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnailUrl,
    required this.category,
    required this.difficulty,
    required this.isPremium,
    required this.isPublished,
    required this.isFeatured,
    required this.totalLessons,
    required this.estimatedMinutes,
    this.character,
    required this.lessons,
    this.verseReference,
    this.verseText,
    required this.pfReward,
    this.createdAt,
  });

  factory BibleStudyModel.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List? ?? [];
    return BibleStudyModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: (json['category'] ?? 'general') as String,
      difficulty: (json['difficulty'] ?? 'beginner') as String,
      isPremium: (json['is_premium'] ?? false) as bool,
      isPublished: (json['is_published'] ?? false) as bool,
      isFeatured: (json['is_featured'] ?? false) as bool,
      totalLessons: ((json['total_lessons'] ?? rawLessons.length) as num).toInt(),
      estimatedMinutes: ((json['estimated_minutes'] ?? 15) as num).toDouble(),
      character: json['character'] != null && json['character'] is Map
          ? StudyCharacter.fromJson(json['character'] as Map<String, dynamic>)
          : null,
      lessons: rawLessons
          .map((l) => StudyLesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      verseReference: json['verse_reference'] as String?,
      verseText: json['verse_text'] as String?,
      pfReward: ((json['pf_reward'] ?? json['xp_reward'] ?? 50) as num).toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'intermediate':
        return 'Intermediario';
      case 'advanced':
        return 'Avancado';
      default:
        return 'Iniciante';
    }
  }
}

class StudyCharacter {
  final String id;
  final String name;
  final String? spriteUrl;
  final String? colorHex;
  final String? bio;

  const StudyCharacter({
    required this.id,
    required this.name,
    this.spriteUrl,
    this.colorHex,
    this.bio,
  });

  factory StudyCharacter.fromJson(Map<String, dynamic> json) => StudyCharacter(
    id: (json['_id'] ?? json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    spriteUrl: json['sprite_url'] as String?,
    colorHex: json['color_hex'] as String?,
    bio: json['bio'] as String?,
  );
}

class StudyLesson {
  final int index;
  final String title;
  final String verseReference;
  final String verseText;
  final String contextNarrative;
  final String characterDialogue;
  final String characterReaction;
  final String characterApplication;
  final String doveIntro;
  final String doveComment;
  final String doveClose;
  final QuizMC? quizMC;
  final QuizFill? quizFill;
  final QuizOrder? quizOrder;
  final int pfReward;

  const StudyLesson({
    required this.index,
    required this.title,
    required this.verseReference,
    required this.verseText,
    required this.contextNarrative,
    required this.characterDialogue,
    required this.characterReaction,
    required this.characterApplication,
    required this.doveIntro,
    required this.doveComment,
    required this.doveClose,
    this.quizMC,
    this.quizFill,
    this.quizOrder,
    required this.pfReward,
  });

  factory StudyLesson.fromJson(Map<String, dynamic> json) => StudyLesson(
    index: ((json['index'] ?? json['order'] ?? 0) as num).toInt(),
    title: (json['title'] ?? '') as String,
    verseReference: (json['verse_reference'] ?? '') as String,
    verseText: (json['verse_text'] ?? '') as String,
    contextNarrative: (json['context_narrative'] ?? '') as String,
    characterDialogue: (json['character_dialogue'] ?? '') as String,
    characterReaction: (json['character_reaction'] ?? '') as String,
    characterApplication: (json['character_application'] ?? '') as String,
    doveIntro: (json['dove_intro'] ?? '') as String,
    doveComment: (json['dove_comment'] ?? '') as String,
    doveClose: (json['dove_close'] ?? '') as String,
    quizMC: json['quiz_mc'] != null && json['quiz_mc'] is Map
        ? QuizMC.fromJson(json['quiz_mc'] as Map<String, dynamic>)
        : null,
    quizFill: json['quiz_fill'] != null && json['quiz_fill'] is Map
        ? QuizFill.fromJson(json['quiz_fill'] as Map<String, dynamic>)
        : null,
    quizOrder: json['quiz_order'] != null && json['quiz_order'] is Map
        ? QuizOrder.fromJson(json['quiz_order'] as Map<String, dynamic>)
        : null,
    pfReward: ((json['pf_reward'] ?? json['xp_reward'] ?? 15) as num).toInt(),
  );
}

class QuizMC {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;

  const QuizMC({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuizMC.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? [];
    final List<String> options = rawOptions is List
        ? rawOptions.whereType<String>().toList()
        : [];
    return QuizMC(
      question: (json['question'] ?? '') as String,
      options: options,
      correctAnswer: (json['correct_answer'] ?? '') as String,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizFill {
  final String sentence;
  final String correctWord;
  final List<String> options;
  final String? explanation;

  const QuizFill({
    required this.sentence,
    required this.correctWord,
    required this.options,
    this.explanation,
  });

  factory QuizFill.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? [];
    final List<String> options = rawOptions is List
        ? rawOptions.whereType<String>().toList()
        : [];
    return QuizFill(
      sentence: (json['sentence'] ?? '') as String,
      correctWord: (json['correct_word'] ?? '') as String,
      options: options,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizOrder {
  final String instruction;
  final List<String> scrambledWords;
  final List<String> correctOrder;
  final String? explanation;

  const QuizOrder({
    required this.instruction,
    required this.scrambledWords,
    required this.correctOrder,
    this.explanation,
  });

  factory QuizOrder.fromJson(Map<String, dynamic> json) {
    final rawScrambled = json['scrambled_words'] ?? [];
    final rawCorrect = json['correct_order'] ?? [];
    return QuizOrder(
      instruction: (json['instruction'] ?? '') as String,
      scrambledWords: rawScrambled is List
          ? rawScrambled.whereType<String>().toList()
          : [],
      correctOrder: rawCorrect is List
          ? rawCorrect.whereType<String>().toList()
          : [],
      explanation: json['explanation'] as String?,
    );
  }
}

/// Resposta de acesso/start do estudo
class StudyAccessResult {
  final bool granted;
  final String? reason;
  final int currentLesson;

  const StudyAccessResult({
    required this.granted,
    this.reason,
    required this.currentLesson,
  });

  factory StudyAccessResult.fromJson(Map<String, dynamic> json) => StudyAccessResult(
    granted: (json['granted'] ?? json['access'] ?? false) as bool,
    reason: json['reason'] as String?,
    currentLesson: ((json['current_lesson'] ?? 0) as num).toInt(),
  );
}

/// Progresso do usuario no estudo
class StudyProgress {
  final String studyId;
  final String userId;
  final int completedLessons;
  final int totalLessons;
  final int pfEarned;
  final bool isCompleted;

  const StudyProgress({
    required this.studyId,
    required this.userId,
    required this.completedLessons,
    required this.totalLessons,
    required this.pfEarned,
    required this.isCompleted,
  });

  factory StudyProgress.fromJson(Map<String, dynamic> json) => StudyProgress(
    studyId: (json['study_id'] ?? json['studyId'] ?? '') as String,
    userId: (json['user_id'] ?? json['userId'] ?? '') as String,
    completedLessons: ((json['completed_lessons'] ?? 0) as num).toInt(),
    totalLessons: ((json['total_lessons'] ?? 0) as num).toInt(),
    pfEarned: ((json['pf_earned'] ?? json['xp_earned'] ?? 0) as num).toInt(),
    isCompleted: (json['is_completed'] ?? false) as bool,
  );

  double get progressPercent =>
      totalLessons > 0 ? (completedLessons / totalLessons).clamp(0.0, 1.0) : 0.0;
}
