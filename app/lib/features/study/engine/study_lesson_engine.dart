import 'dart:math';
import '../../../shared/models/bible_study_model.dart';

/// Tipo de quiz suportado no estudo.
enum StudyQuizType { multipleChoice, fillBlank, wordOrder }

/// Tipo de step no fluxo de uma licao de estudo.
enum StudyStepType {
  dialogueDoveIntro,     // 01
  dialogueCharacter,     // 02
  verseCard,             // 03
  aiExplanation,         // 04
  dialogueReaction,      // 05
  quiz,                  // 06, 08
  dialogueDoveComment,   // 07
  dialogueApplication,   // 09
  dialogueDoveClose,     // 10
  completion,            // 11
}

/// Um step individual dentro da licao de estudo.
class StudyStep {
  final StudyStepType type;
  final String? speaker;      // 'dove' | characterName | null
  final String? text;
  final String? verseRef;
  final String? verseText;
  final StudyQuizType? quizType;
  final QuizMC? quizMC;
  final QuizFill? quizFill;
  final QuizOrder? quizOrder;
  final int pfReward;

  const StudyStep({
    required this.type,
    this.speaker,
    this.text,
    this.verseRef,
    this.verseText,
    this.quizType,
    this.quizMC,
    this.quizFill,
    this.quizOrder,
    this.pfReward = 0,
  });
}

/// Engine que gera os 11 steps de uma licao de estudo.
class StudyLessonEngine {
  final StudyLesson lesson;
  final String characterName;

  StudyLessonEngine({
    required this.lesson,
    required this.characterName,
  });

  /// Gera a lista de 11 steps para esta licao.
  /// Sorteia 2 dos 3 tipos de quiz disponiveis e os distribui nos slots 06 e 08.
  List<StudyStep> buildSteps() {
    final quizPair = _pickTwoQuizTypes();

    return [
      // Step 01 - Dove intro
      StudyStep(
        type: StudyStepType.dialogueDoveIntro,
        speaker: 'Pomba',
        text: lesson.doveIntro,
      ),

      // Step 02 - Character dialogue (contexto narrativo)
      StudyStep(
        type: StudyStepType.dialogueCharacter,
        speaker: characterName,
        text: lesson.characterDialogue,
      ),

      // Step 03 - Verse card
      StudyStep(
        type: StudyStepType.verseCard,
        verseRef: lesson.verseReference,
        verseText: lesson.verseText,
      ),

      // Step 04 - AI explanation
      StudyStep(
        type: StudyStepType.aiExplanation,
        text: lesson.contextNarrative,
      ),

      // Step 05 - Character reaction
      StudyStep(
        type: StudyStepType.dialogueReaction,
        speaker: characterName,
        text: lesson.characterReaction,
      ),

      // Step 06 - Quiz #1
      _buildQuizStep(quizPair[0]),

      // Step 07 - Dove comment
      StudyStep(
        type: StudyStepType.dialogueDoveComment,
        speaker: 'Pomba',
        text: lesson.doveComment,
      ),

      // Step 08 - Quiz #2 (tipo diferente)
      _buildQuizStep(quizPair[1]),

      // Step 09 - Character application
      StudyStep(
        type: StudyStepType.dialogueApplication,
        speaker: characterName,
        text: lesson.characterApplication,
      ),

      // Step 10 - Dove close
      StudyStep(
        type: StudyStepType.dialogueDoveClose,
        speaker: 'Pomba',
        text: lesson.doveClose,
      ),

      // Step 11 - Completion
      StudyStep(
        type: StudyStepType.completion,
        pfReward: lesson.pfReward,
      ),
    ];
  }

  /// Escolhe 2 dos 3 tipos de quiz aleatoriamente, garantindo tipos diferentes.
  /// Prioriza quizzes que existem (tem dados). Se nenhum existir, gera MC fallback.
  List<StudyQuizType> _pickTwoQuizTypes() {
    final rng = Random();
    final available = <StudyQuizType>[];

    if (lesson.quizMC != null) available.add(StudyQuizType.multipleChoice);
    if (lesson.quizFill != null) available.add(StudyQuizType.fillBlank);
    if (lesson.quizOrder != null) available.add(StudyQuizType.wordOrder);

    if (available.isEmpty) {
      // Fallback: sem quizzes definidos, usa MC placeholder em ambos
      return [StudyQuizType.multipleChoice, StudyQuizType.multipleChoice];
    }

    if (available.length == 1) {
      // So tem 1 tipo disponivel, usa ele nos dois slots
      return [available.first, available.first];
    }

    // Shuffle e pega 2 tipos distintos
    available.shuffle(rng);
    return [available[0], available[1]];
  }

  StudyStep _buildQuizStep(StudyQuizType quizType) {
    switch (quizType) {
      case StudyQuizType.multipleChoice:
        return StudyStep(
          type: StudyStepType.quiz,
          quizType: StudyQuizType.multipleChoice,
          quizMC: lesson.quizMC,
          pfReward: 5,
        );
      case StudyQuizType.fillBlank:
        return StudyStep(
          type: StudyStepType.quiz,
          quizType: StudyQuizType.fillBlank,
          quizFill: lesson.quizFill,
          pfReward: 5,
        );
      case StudyQuizType.wordOrder:
        return StudyStep(
          type: StudyStepType.quiz,
          quizType: StudyQuizType.wordOrder,
          quizOrder: lesson.quizOrder,
          pfReward: 5,
        );
    }
  }
}
