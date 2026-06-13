import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/exercise_provider.dart';
import '../../shared/models/lesson_model.dart';
import '../../shared/widgets/jf_button.dart';
import '../../shared/widgets/jf_progress_bar.dart';
// Hearts removed — using energy badge instead
import '../../shared/widgets/jf_pf_badge.dart';
import '../../shared/widgets/character_dialog.dart';
import '../../core/providers/trail_provider.dart';
import '../gamification/services/streak_service.dart';
import '../gamification/providers/gamification_providers.dart';
import '../characters/application/lesson_character_integration.dart';
import '../characters/presentation/overlays/lesson_character_overlay.dart';
import '../characters/providers/character_provider.dart';
import 'providers/lesson_progress_provider.dart';

// Estado da lição
enum LessonPhase { answering, feedbackCorrect, feedbackWrong, complete }

class LessonState {
  final List<ExerciseModel> exercises;
  final int currentIndex;
  final LessonPhase phase;
  final dynamic selectedAnswer;
  final int heartsLost;
  final int pfEarned;
  final int errorCount;

  const LessonState({
    required this.exercises,
    this.currentIndex = 0,
    this.phase = LessonPhase.answering,
    this.selectedAnswer,
    this.heartsLost = 0,
    this.pfEarned = 0,
    this.errorCount = 0,
  });

  LessonState copyWith({
    List<ExerciseModel>? exercises,
    int? currentIndex,
    LessonPhase? phase,
    dynamic selectedAnswer = _sentinel,
    int? heartsLost,
    int? pfEarned,
    int? errorCount,
  }) {
    return LessonState(
      exercises: exercises ?? this.exercises,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      selectedAnswer: identical(selectedAnswer, _sentinel)
          ? this.selectedAnswer
          : selectedAnswer,
      heartsLost: heartsLost ?? this.heartsLost,
      pfEarned: pfEarned ?? this.pfEarned,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  static const _sentinel = Object();

  ExerciseModel? get currentExercise =>
      currentIndex < exercises.length ? exercises[currentIndex] : null;

  double get progressValue =>
      exercises.isEmpty ? 0 : currentIndex / exercises.length;
}

const int _exercisesPerLesson = 7;

List<ExerciseModel> _pickExercises(List<ExerciseModel> all) {
  if (all.isEmpty) return [];
  final rng = Random();
  final emojis = (all.where((e) => e.type == ExerciseType.emojiGuess).toList()..shuffle(rng)).take(1).toList();
  final rest = (all.where((e) => e.type != ExerciseType.emojiGuess).toList()..shuffle(rng))
      .take(_exercisesPerLesson - emojis.length)
      .toList();
  return ([...emojis, ...rest]..shuffle(rng));
}

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with TickerProviderStateMixin {
  LessonState _lessonState = const LessonState(exercises: []);
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  bool _showPFBadge = false;
  bool _initialized = false;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticOut),
    );
    // Activate character for this lesson (fetch default character)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final character = await ref.read(defaultCharacterProvider.future);
      if (character != null && mounted) {
        ref.read(activeCharacterIdProvider.notifier).state = character.id;
        LessonCharacterHelper.onLessonStart(ref);
      }
    });
  }

  void _initFromExercises(List<ExerciseModel> exercises) {
    if (_initialized || exercises.isEmpty) return;
    _initialized = true;
    setState(() {
      _lessonState = LessonState(exercises: _pickExercises(exercises));
    });
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    super.dispose();
  }

  void _selectAnswer(dynamic answer) {
    if (_lessonState.phase != LessonPhase.answering) return;
    setState(() {
      _lessonState = _lessonState.copyWith(selectedAnswer: answer);
    });
  }

  void _verifyAnswer() {
    final exercise = _lessonState.currentExercise;
    if (exercise == null || _lessonState.selectedAnswer == null) return;

    final isCorrect = _lessonState.selectedAnswer.toString().toLowerCase() ==
        exercise.correctAnswer.toString().toLowerCase();

    HapticFeedback.mediumImpact();

    if (isCorrect) {
      setState(() {
        _lessonState = _lessonState.copyWith(
          phase: LessonPhase.feedbackCorrect,
          pfEarned: _lessonState.pfEarned + 10,
        );
        _showPFBadge = true;
      });
      ref.read(currentUserProvider.notifier).gainPF(10);
      LessonCharacterHelper.onCorrectAnswer(ref);
    } else {
      _shakeController?.forward(from: 0);
      setState(() {
        _lessonState = _lessonState.copyWith(
          phase: LessonPhase.feedbackWrong,
          heartsLost: _lessonState.heartsLost + 1,
          errorCount: _lessonState.errorCount + 1,
        );
      });
      ref.read(currentUserProvider.notifier).consumeEnergy();
      LessonCharacterHelper.onWrongAnswer(ref);
    }
  }

  Future<void> _onLessonComplete() async {
    // Update streak when lesson is completed
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    try {
      await StreakService.onExerciseCompleted(userId: userId);
      ref.invalidate(streakProvider);
      ref.invalidate(completedTodayProvider);
    } catch (_) {}

    // Invalidate progress cache so home screen fetches fresh data
    ref.invalidate(lessonProgressProvider(widget.lessonId));
    ref.invalidate(trailListProvider);
  }

  void _nextExercise() {
    final nextIndex = _lessonState.currentIndex + 1;
    if (nextIndex >= _lessonState.exercises.length) {
      _onLessonComplete();
      _stopwatch.stop();
      final totalExercises = _lessonState.exercises.length;
      final correctCount = totalExercises - _lessonState.errorCount;
      final accuracyPercent = totalExercises > 0
          ? (correctCount / totalExercises * 100).round()
          : 100;
      context.go(
        '/lesson-complete'
        '?pf=${_lessonState.pfEarned}'
        '&errors=${_lessonState.errorCount}'
        '&lessonId=${widget.lessonId}'
        '&accuracy=$accuracyPercent'
        '&elapsed=${_stopwatch.elapsed.inSeconds}'
        '&isLastStage=1',
      );
      return;
    } else {
      setState(() {
        _lessonState = _lessonState.copyWith(
          currentIndex: nextIndex,
          phase: LessonPhase.answering,
          selectedAnswer: null,
        );
        _showPFBadge = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Carrega exercicios da API por licao
    final exercisesAsync = ref.watch(exercisesByLessonProvider(widget.lessonId));
    exercisesAsync.whenData((exercises) => _initFromExercises(exercises));

    // Complete state is now handled by navigation to /lesson-complete

    // ✅ FIX BUG 1: Mostrar skeleton durante loading, NAO empty state
    if (!_initialized) {
      return exercisesAsync.when(
        loading: () => const _LessonLoadingSkeleton(),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar a lição.', style: AppTypography.headingMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => ref.invalidate(exercisesByLessonProvider(widget.lessonId)),
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(onPressed: () => context.go('/home'), child: const Text('Voltar')),
                ],
              ),
            ),
          ),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😕', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('Nenhum exercício disponível para esta lição.', style: AppTypography.headingMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextButton(onPressed: () => context.go('/home'), child: const Text('Voltar')),
                    ],
                  ),
                ),
              ),
            );
          }
          // Exercises loaded but _initFromExercises not yet called - show skeleton briefly
          return const _LessonLoadingSkeleton();
        },
      );
    }

    final exercise = _lessonState.currentExercise;
    if (exercise == null) return const SizedBox.shrink();

    final userAsync = ref.watch(currentUserProvider);
    final hearts = userAsync.valueOrNull?.energy ?? 20;

    return AnimatedBuilder(
      animation: _shakeAnimation ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        final shake = _shakeAnimation?.value ?? 0;
        return Transform.translate(
          offset: Offset(shake * 8 * (1 - shake), 0),
          child: child,
        );
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showCloseDialog(context);
        },
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          title: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showCloseDialog(context),
                  child: const Icon(Icons.close, color: AppColors.textSecondary, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: JFProgressBar(
                    value: _lessonState.progressValue,
                    height: 18,
                  ),
                ),
                const SizedBox(width: 14),
                _LessonEnergyBadge(energy: hearts),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
          children: [
            // Área de conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: Reativar animacao do personagem posteriormente
                    // CharacterDialog(
                    //   characterName: 'Caleb',
                    //   message: _getInstruction(exercise.type),
                    // ),
                    // const SizedBox(height: 24),

                    // Questão
                    Text(
                      exercise.question,
                      style: AppTypography.headingMedium,
                    ),

                    if (exercise.verseReference != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.verseReference!,
                        style: AppTypography.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Área de resposta por tipo
                    _buildAnswerArea(exercise),

                    // PF Badge flutuante
                    if (_showPFBadge)
                      Align(
                        alignment: Alignment.center,
                        child: JFPFBadge(
                          pfAmount: 10,
                          onAnimationComplete: () {
                            setState(() => _showPFBadge = false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Feedback
            if (_lessonState.phase != LessonPhase.answering)
              _FeedbackBar(
                isCorrect: _lessonState.phase == LessonPhase.feedbackCorrect,
                correctAnswer: exercise.correctAnswer.toString(),
                explanation: exercise.explanation,
                onContinue: _nextExercise,
              ),

            // Botão verificar
            if (_lessonState.phase == LessonPhase.answering)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: JFButton(
                  label: 'Verificar',
                  onPressed: _lessonState.selectedAnswer != null ? _verifyAnswer : null,
                ),
              ),
          ],
        ),
            // TODO: reimplementar overlay do personagem posteriormente
            // Consumer(builder: (context, ref, _) {
            //   final charId = ref.watch(activeCharacterIdProvider);
            //   if (charId == null) return const SizedBox.shrink();
            //   return LessonCharacterOverlay(characterId: charId, onDismiss: () {});
            // }),
          ],
        ),
      ),
      ),  // PopScope
    );
  }

  Widget _buildAnswerArea(ExerciseModel exercise) {
    // Exercício premium — bloquear se usuário não for assinante
    if (exercise.isPremium) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final isPremiumUser = user?.leagueTier == 'diamond'; // simplificação MVP
      if (!isPremiumUser) {
        return _PremiumLockArea(onUnlock: () {
          // TODO: abrir fluxo de assinatura
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assine o JourneyFaith Premium para desbloquear! 💎')),
          );
        });
      }
    }

    switch (exercise.type) {
      case ExerciseType.multipleChoice:
        return _MultipleChoiceArea(
          options: exercise.options,
          selectedAnswer: _lessonState.selectedAnswer?.toString(),
          phase: _lessonState.phase,
          correctAnswer: exercise.correctAnswer.toString(),
          onSelect: _selectAnswer,
        );
      case ExerciseType.trueFalse:
        return _TrueFalseArea(
          selectedAnswer: _lessonState.selectedAnswer?.toString(),
          phase: _lessonState.phase,
          onSelect: _selectAnswer,
        );
      case ExerciseType.fillBlank:
        return _FillBlankArea(
          options: exercise.options,
          selectedAnswer: _lessonState.selectedAnswer?.toString(),
          onSelect: _selectAnswer,
        );
      case ExerciseType.emojiGuess:
        return _EmojiGuessArea(
          emojiHint: exercise.emojiHint ?? '❓',
          options: exercise.options,
          selectedAnswer: _lessonState.selectedAnswer?.toString(),
          phase: _lessonState.phase,
          correctAnswer: exercise.correctAnswer.toString(),
          onSelect: _selectAnswer,
        );
      case ExerciseType.audioRecite:
        return _AudioReciteArea(
          correctAnswer: exercise.correctAnswer.toString(),
          explanation: exercise.explanation ?? '',
          onRecognized: _selectAnswer,
          phase: _lessonState.phase,
        );
      default:
        return _MultipleChoiceArea(
          options: exercise.options,
          selectedAnswer: _lessonState.selectedAnswer?.toString(),
          phase: _lessonState.phase,
          correctAnswer: exercise.correctAnswer.toString(),
          onSelect: _selectAnswer,
        );
    }
  }

  String _getInstruction(ExerciseType type) {
    switch (type) {
      case ExerciseType.multipleChoice:
        return 'Escolha a resposta correta!';
      case ExerciseType.trueFalse:
        return 'Verdadeiro ou Falso?';
      case ExerciseType.fillBlank:
        return 'Complete o versículo!';
      case ExerciseType.wordOrder:
        return 'Coloque as palavras em ordem!';
      case ExerciseType.association:
        return 'Faça a associação correta!';
      case ExerciseType.emojiGuess:
        return 'O que estes emojis representam?';
      case ExerciseType.audioRecite:
        return 'Recite o versículo em voz alta!';
    }
  }

  Future<void> _showCloseDialog(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/dove_icon.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const Text(
              'Tem certeza que quer sair?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2E4A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todo o progresso dessa lição será perdido.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('CONTINUAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'SAIR DA LIÇÃO',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true && context.mounted) context.go('/home');
  }
}

class _MultipleChoiceArea extends StatelessWidget {
  final List<String> options;
  final String? selectedAnswer;
  final LessonPhase phase;
  final String correctAnswer;
  final Function(String) onSelect;

  const _MultipleChoiceArea({
    required this.options,
    required this.selectedAnswer,
    required this.phase,
    required this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedAnswer == option;
        final isAnswered = phase != LessonPhase.answering;
        final isCorrect = option == correctAnswer;

        Color borderColor = AppColors.border;
        Color bgColor = AppColors.background;

        if (isAnswered) {
          if (isCorrect) {
            borderColor = AppColors.correct;
            bgColor = AppColors.correctLight;
          } else if (isSelected && !isCorrect) {
            borderColor = AppColors.incorrect;
            bgColor = AppColors.incorrectLight;
          }
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primaryLight;
        }

        return GestureDetector(
          onTap: isAnswered ? null : () => onSelect(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(option, style: AppTypography.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  )),
                ),
                if (isAnswered && isCorrect)
                  const Icon(Icons.check_circle, color: AppColors.correct),
                if (isAnswered && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: AppColors.incorrect),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TrueFalseArea extends StatelessWidget {
  final String? selectedAnswer;
  final LessonPhase phase;
  final Function(String) onSelect;

  const _TrueFalseArea({
    required this.selectedAnswer,
    required this.phase,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TFButton(
            label: '✓ VERDADEIRO',
            value: 'Verdadeiro',
            isSelected: selectedAnswer == 'Verdadeiro',
            isAnswered: phase != LessonPhase.answering,
            color: AppColors.correct,
            onTap: () => onSelect('Verdadeiro'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TFButton(
            label: '✗ FALSO',
            value: 'Falso',
            isSelected: selectedAnswer == 'Falso',
            isAnswered: phase != LessonPhase.answering,
            color: AppColors.incorrect,
            onTap: () => onSelect('Falso'),
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final bool isAnswered;
  final Color color;
  final VoidCallback onTap;

  const _TFButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.isAnswered,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.buttonMedium.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FillBlankArea extends StatelessWidget {
  final List<String> options;
  final String? selectedAnswer;
  final Function(String) onSelect;

  const _FillBlankArea({
    required this.options,
    required this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lacuna selecionada
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: selectedAnswer != null
              ? GestureDetector(
                  onTap: () => onSelect(''),
                  child: Text(
                    selectedAnswer!,
                    style: AppTypography.headingMedium.copyWith(color: AppColors.primary),
                  ),
                )
              : Text(
                  '___________',
                  style: AppTypography.headingMedium.copyWith(color: AppColors.textHint),
                ),
        ),
        const SizedBox(height: 20),
        Text('Banco de palavras:', style: AppTypography.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isUsed = selectedAnswer == opt;
            return GestureDetector(
              onTap: isUsed ? null : () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isUsed ? AppColors.border : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUsed ? AppColors.border : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isUsed ? AppColors.textHint : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Premium Lock ────────────────────────────────────────────────────────────

class _PremiumLockArea extends StatelessWidget {
  final VoidCallback onUnlock;

  const _PremiumLockArea({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Conteúdo Premium',
            style: AppTypography.headingMedium.copyWith(color: const Color(0xFF7B5800)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Este exercício é exclusivo para assinantes JourneyFaith Premium.',
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF9E6C00)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          JFButton(
            label: 'Desbloquear Premium 💎',
            onPressed: onUnlock,
          ),
        ],
      ),
    );
  }
}

// ─── Emoji Guess ─────────────────────────────────────────────────────────────

class _EmojiGuessArea extends StatelessWidget {
  final String emojiHint;
  final List<String> options;
  final String? selectedAnswer;
  final LessonPhase phase;
  final String correctAnswer;
  final Function(String) onSelect;

  const _EmojiGuessArea({
    required this.emojiHint,
    required this.options,
    required this.selectedAnswer,
    required this.phase,
    required this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emoji hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Text(
            emojiHint,
            style: const TextStyle(fontSize: 48, letterSpacing: 8),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Options (reutiliza lógica de múltipla escolha)
        ...options.map((option) {
          final isSelected = selectedAnswer == option;
          final isAnswered = phase != LessonPhase.answering;
          final isCorrect = option == correctAnswer;

          Color borderColor = AppColors.border;
          Color bgColor = AppColors.background;

          if (isAnswered) {
            if (isCorrect) {
              borderColor = AppColors.correct;
              bgColor = AppColors.correctLight;
            } else if (isSelected && !isCorrect) {
              borderColor = AppColors.incorrect;
              bgColor = AppColors.incorrectLight;
            }
          } else if (isSelected) {
            borderColor = AppColors.primary;
            bgColor = AppColors.primaryLight;
          }

          return GestureDetector(
            onTap: isAnswered ? null : () => onSelect(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(option, style: AppTypography.bodyLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ),
                  if (isAnswered && isCorrect)
                    const Icon(Icons.check_circle, color: AppColors.correct),
                  if (isAnswered && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: AppColors.incorrect),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Audio Recite ─────────────────────────────────────────────────────────────

class _AudioReciteArea extends StatefulWidget {
  final String correctAnswer;
  final String explanation;
  final Function(String) onRecognized;
  final LessonPhase phase;

  const _AudioReciteArea({
    required this.correctAnswer,
    required this.explanation,
    required this.onRecognized,
    required this.phase,
  });

  @override
  State<_AudioReciteArea> createState() => _AudioReciteAreaState();
}

class _AudioReciteAreaState extends State<_AudioReciteArea> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isAnswered = widget.phase != LessonPhase.answering;

    return Column(
      children: [
        // Instrução
        if (!isAnswered && !_revealed)
          Text(
            'Leia o versículo abaixo, cubra a tela e tente recitar de memória.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),

        // Versículo
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.neumorphBase,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.neumorphLight.withValues(alpha: 0.85),
                offset: const Offset(-5, -5),
                blurRadius: 12,
              ),
              BoxShadow(
                color: AppColors.neumorphDark.withValues(alpha: 0.55),
                offset: const Offset(5, 5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            widget.correctAnswer,
            style: AppTypography.bodyLarge.copyWith(
              fontStyle: FontStyle.italic,
              color: (_revealed || isAnswered)
                  ? AppColors.textPrimary
                  : Colors.transparent,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        if (!isAnswered && !_revealed) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _revealed = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neumorphBase,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neumorphLight.withValues(alpha: 0.85),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: AppColors.neumorphDark.withValues(alpha: 0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '👁  Revelar versículo',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],

        if (!isAnswered && _revealed) ...[
          const SizedBox(height: 28),
          Text(
            'Conseguiu recitar de memória?',
            style: AppTypography.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReciteChoiceButton(
                  label: '✅  Sim, consegui!',
                  color: AppColors.correct,
                  shadowColor: AppColors.buttonShadowGreen,
                  onTap: () => widget.onRecognized(widget.correctAnswer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReciteChoiceButton(
                  label: '🔄  Ainda não',
                  color: AppColors.incorrect,
                  shadowColor: AppColors.buttonShadowRed,
                  onTap: () => widget.onRecognized(''),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReciteChoiceButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ReciteChoiceButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_ReciteChoiceButton> createState() => _ReciteChoiceButtonState();
}

class _ReciteChoiceButtonState extends State<_ReciteChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: Offset(0, _pressed ? 0 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        child: Center(
          child: Text(
            widget.label,
            style: AppTypography.buttonMedium.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackBar extends StatefulWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;
  final VoidCallback onContinue;

  const _FeedbackBar({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.onContinue,
  });

  @override
  State<_FeedbackBar> createState() => _FeedbackBarState();
}

class _FeedbackBarState extends State<_FeedbackBar> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;
    final bgColor = isCorrect ? AppColors.correctLight : AppColors.incorrectLight;
    final borderColor = isCorrect ? AppColors.correct : AppColors.incorrect;
    final textColor = isCorrect ? AppColors.correctDark : AppColors.incorrectDark;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: borderColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect ? 'Correto! 🎉' : 'Quase lá!',
                    style: AppTypography.headingMedium.copyWith(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'A resposta correta é: ${widget.correctAnswer}',
                style: AppTypography.bodyLarge.copyWith(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (widget.explanation != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.explanation!,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor.withValues(alpha: 0.85),
                  fontSize: 15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            JFButton(
              label: 'Continuar',
              variant: isCorrect ? JFButtonVariant.primary : JFButtonVariant.secondary,
              onPressed: widget.onContinue,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Loading Skeleton (BUG 1 fix) ────────────────────────────────────────────

class _LessonLoadingSkeleton extends StatelessWidget {
  const _LessonLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fake progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 48),
              // 3 skeleton cards
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ShimmerCard(delay: i * 200),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final int delay;
  const _ShimmerCard({this.delay = 0});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    if (widget.delay > 0) {
      _ctrl.stop();
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: Color.lerp(Colors.grey.shade200, Colors.grey.shade100, _ctrl.value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _LessonEnergyBadge extends StatelessWidget {
  final int energy;
  const _LessonEnergyBadge({required this.energy});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (energy >= 15) {
      color = const Color(0xFF42A5F5); // blue when full/high
    } else if (energy >= 8) {
      color = const Color(0xFFFFD54F); // yellow medium
    } else if (energy >= 5) {
      color = const Color(0xFFFF9800); // orange low
    } else if (energy > 0) {
      color = const Color(0xFFEF5350); // red critical
    } else {
      color = Colors.grey;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: 1.5708,
          child: Icon(
            energy > 0 ? Icons.battery_charging_full_rounded : Icons.battery_0_bar_rounded,
            size: 30,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text('$energy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
