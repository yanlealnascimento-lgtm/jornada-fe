import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/widgets/jf_button.dart';
import '../../../shared/widgets/jf_progress_bar.dart';
import '../../../shared/widgets/jf_pf_badge.dart';
import '../../../shared/widgets/character_dialog.dart';
import '../../../core/providers/trail_provider.dart';
import '../../gamification/services/streak_service.dart';
import '../../gamification/services/lives_service.dart';
import '../../gamification/services/crystal_service.dart'; // used in energy depleted modal
import '../../gamification/providers/gamification_providers.dart';
import '../../../shared/services/http_client.dart';
import '../../home/data/trail_repository.dart';
import '../../leagues/providers/league_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../providers/lesson_progress_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum _Phase { answering, feedbackCorrect, feedbackWrong }

class _StageState {
  final List<ExerciseModel> exercises;
  final int currentIndex;
  final _Phase phase;
  final dynamic selectedAnswer;
  final int heartsLost;
  final int pfEarned;
  final int errorCount;

  const _StageState({
    required this.exercises,
    this.currentIndex = 0,
    this.phase = _Phase.answering,
    this.selectedAnswer,
    this.heartsLost = 0,
    this.pfEarned = 0,
    this.errorCount = 0,
  });

  _StageState copyWith({
    List<ExerciseModel>? exercises,
    int? currentIndex,
    _Phase? phase,
    dynamic selectedAnswer = _sentinel,
    int? heartsLost,
    int? pfEarned,
    int? errorCount,
  }) {
    return _StageState(
      exercises: exercises ?? this.exercises,
      currentIndex: currentIndex ?? this.currentIndex,
      phase: phase ?? this.phase,
      selectedAnswer:
          identical(selectedAnswer, _sentinel) ? this.selectedAnswer : selectedAnswer,
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class LessonStageScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final int stageIndex;
  final int stagesTotal;
  final bool isReview;

  const LessonStageScreen({
    super.key,
    required this.lessonId,
    required this.stageIndex,
    this.stagesTotal = 1,
    this.isReview = false,
  });

  @override
  ConsumerState<LessonStageScreen> createState() => _LessonStageScreenState();
}

class _LessonStageScreenState extends ConsumerState<LessonStageScreen>
    with TickerProviderStateMixin {
  _StageState _state = const _StageState(exercises: []);
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  bool _showPFBadge = false;
  bool _initialized = false;
  bool _completing = false;
  int _consecutiveCorrect = 0;
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
    // Start lesson on first stage to create progress record in backend
    if (widget.stageIndex == 0) {
      _startLessonOnBackend();
    }
  }

  Future<void> _startLessonOnBackend() async {
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      await trailRepository.startLesson(widget.lessonId, userId: userId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    super.dispose();
  }

  void _initExercises(List<ExerciseModel> exercises) {
    if (_initialized || exercises.isEmpty) return;
    _initialized = true;
    final rng = Random();
    final picked = List<ExerciseModel>.from(exercises)..shuffle(rng);
    setState(() => _state = _StageState(exercises: picked));
  }

  void _selectAnswer(dynamic answer) {
    if (_state.phase != _Phase.answering) return;
    setState(() => _state = _state.copyWith(selectedAnswer: answer));
  }

  /// For audioRecite: set answer and immediately verify.
  void _selectAndVerify(dynamic answer) {
    if (_state.phase != _Phase.answering) return;
    setState(() => _state = _state.copyWith(selectedAnswer: answer));
    _verifyAnswer();
  }

  void _verifyAnswer() {
    final exercise = _state.currentExercise;
    if (exercise == null || _state.selectedAnswer == null) return;

    final isCorrect = _state.selectedAnswer.toString().trim().toLowerCase() ==
        exercise.correctAnswer.toString().trim().toLowerCase();

    HapticFeedback.mediumImpact();

    // Consume 1 energy on every interaction (correct or wrong)
    LivesService.consumeLife().then((_) {
      ref.invalidate(livesProvider);
    });

    if (isCorrect) {
      _consecutiveCorrect++;
      setState(() {
        _state = _state.copyWith(
          phase: _Phase.feedbackCorrect,
          pfEarned: _state.pfEarned + 10,
        );
        _showPFBadge = true;
      });
      ref.read(currentUserProvider.notifier).gainPF(10);
    } else {
      _consecutiveCorrect = 0;
      _shakeController?.forward(from: 0);
      setState(() {
        _state = _state.copyWith(
          phase: _Phase.feedbackWrong,
          heartsLost: _state.heartsLost + 1,
          errorCount: _state.errorCount + 1,
        );
      });
    }
  }

  void _nextExercise() {
    if (_consecutiveCorrect > 0 && _consecutiveCorrect % 4 == 0) {
      _showEnergyBonusModal();
    } else {
      _advanceToNextExercise();
    }
  }

  void _advanceToNextExercise() {
    final nextIndex = _state.currentIndex + 1;
    if (nextIndex >= _state.exercises.length) {
      _completeStage();
    } else {
      setState(() {
        _state = _state.copyWith(
          currentIndex: nextIndex,
          phase: _Phase.answering,
          selectedAnswer: null,
        );
        _showPFBadge = false;
      });
    }
  }

  void _showEnergyBonusModal() {
    LivesService.grantLives(4).then((_) {
      ref.invalidate(livesProvider);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1A2E),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                '+4 Energia!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você está mandando super bem, e ganhou +4 de energia, continue assim!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB0B0C8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _advanceToNextExercise();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeStage() async {
    if (_completing) return;
    _completing = true;
    _stopwatch.stop();

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final totalExercises = _state.exercises.length;
    final correctCount = totalExercises - _state.errorCount;
    final accuracyPercent = totalExercises > 0
        ? (correctCount / totalExercises * 100).round()
        : 100;
    final isLastStage = widget.stageIndex >= widget.stagesTotal - 1;

    final userId = ref.read(currentUserProvider).valueOrNull?.id ?? '';
    try {
      await trailRepository.completeStage(
        widget.lessonId,
        widget.stageIndex,
        _state.pfEarned,
        _state.errorCount > 0,
        userId: userId,
      );
    } catch (_) {
      // Best-effort; continue even on network error
    }

    // Add PF to league directly (separate from stage completion)
    if (_state.pfEarned > 0 && userId.isNotEmpty) {
      try {
        await HttpClient.instance.post('/leagues/pf', data: {
          'user_id': userId,
          'pf_amount': _state.pfEarned,
        });
      } catch (_) {}
    }

    // Update streak (once per day, idempotent)
    try {
      await StreakService.onExerciseCompleted(userId: userId);
    } catch (_) {}

    if (!mounted) return;

    // Refresh user from backend to get persisted pf_total
    await ref.read(currentUserProvider.notifier).refreshFromBackend();

    if (!mounted) return;

    // Invalidate progress and gamification cache
    ref.invalidate(lessonProgressProvider(widget.lessonId));
    ref.invalidate(trailListProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(completedTodayProvider);
    ref.invalidate(leagueLeaderboardProvider);
    ref.invalidate(achievementsProvider);

    // Always navigate to celebration screen (never auto-advance)
    context.go(
      '/lesson-complete'
      '?pf=${_state.pfEarned}'
      '&errors=${_state.errorCount}'
      '&lessonId=${widget.lessonId}'
      '&accuracy=$accuracyPercent'
      '&elapsed=$elapsedSeconds'
      '&isLastStage=${isLastStage ? 1 : 0}',
    );
  }

  void _showEnergyDepletedModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sua energia acabou!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              // 3 options row
              Row(
                children: [
                  // Super
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/store');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)]),
                          border: Border.all(color: const Color(0xFFE040FB), width: 2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 32),
                            SizedBox(height: 8),
                            Text('Sem\nlimites', textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('VIRAR\nSUPER', textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFE040FB), fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Recarregar
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final crystals = await CrystalService.getCrystals();
                        if (crystals >= 350) {
                          await CrystalService.consumeCrystals(350);
                          await LivesService.rechargeAll();
                          ref.invalidate(livesProvider);
                          ref.invalidate(crystalProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cristais insuficientes')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3A3A4E), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Transform.rotate(
                              angle: 1.5708,
                              child: const Icon(Icons.battery_charging_full_rounded, color: Color(0xFFF48FB1), size: 32),
                            ),
                            const SizedBox(height: 8),
                            const Text('Recarregar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('\u{1F48E}', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 3),
                                Text('350', style: TextStyle(color: AppColors.mana, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Widget +15
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Em breve!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3A3A4E), width: 1.5),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.widgets_rounded, color: Color(0xFFF48FB1), size: 32),
                            SizedBox(height: 8),
                            Text('+15\nenergias', textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('ADICIONAR\nWIDGET', textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.mana, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Teste 1 semana
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/store');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('TESTE 1 SEMANA GRATIS',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              // Perder PF / Sair
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: const Text('PERDER PF',
                  style: TextStyle(color: Color(0xFFF48FB1), fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCloseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da etapa?'),
        content: const Text('Seu progresso nesta etapa sera perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.incorrect)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ExerciseModel>> exercisesAsync;
    if (widget.isReview) {
      exercisesAsync = ref.watch(reviewExercisesProvider(widget.lessonId));
    } else {
      final params = StageExerciseParams(
        lessonId: widget.lessonId,
        stageIndex: widget.stageIndex,
      );
      exercisesAsync = ref.watch(stageExercisesProvider(params));
    }
    exercisesAsync.whenData((exercises) => _initExercises(exercises));

    final livesAsync = ref.watch(livesProvider);
    final energy = livesAsync.valueOrNull?.current ?? 20;

    // Check if energy ran out
    if (_initialized && energy <= 0 && _state.phase == _Phase.answering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEnergyDepletedModal();
      });
    }

    if (!_initialized) {
      return exercisesAsync.when(
        loading: () => const _StageLoadingSkeleton(),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.incorrect),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar a etapa.',
                      style: AppTypography.headingMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      if (widget.isReview) {
                        ref.invalidate(reviewExercisesProvider(widget.lessonId));
                      } else {
                        ref.invalidate(stageExercisesProvider(StageExerciseParams(
                          lessonId: widget.lessonId,
                          stageIndex: widget.stageIndex,
                        )));
                      }
                    },
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Voltar'),
                  ),
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
                      const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('Nenhum exercicio disponivel para esta etapa.',
                          style: AppTypography.headingMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const _StageLoadingSkeleton();
        },
      );
    }

    final exercise = _state.currentExercise;
    if (exercise == null) return const SizedBox.shrink();

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
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: JFProgressBar(
                      value: _state.progressValue,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ExerciseEnergyBadge(energy: energy),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
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
                      Text(exercise.question, style: AppTypography.headingMedium),
                      // Hide verse reference for emojiGuess (it gives away the answer)
                      if (exercise.verseReference != null &&
                          exercise.type != ExerciseType.emojiGuess) ...[
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
                      _buildAnswerArea(exercise),
                      if (_showPFBadge)
                        Align(
                          alignment: Alignment.center,
                          child: JFPFBadge(
                            pfAmount: 10,
                            onAnimationComplete: () =>
                                setState(() => _showPFBadge = false),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_state.phase != _Phase.answering)
                _FeedbackBar(
                  isCorrect: _state.phase == _Phase.feedbackCorrect,
                  correctAnswer: exercise.correctAnswer.toString(),
                  explanation: exercise.explanation,
                  onContinue: _nextExercise,
                ),
              if (_state.phase == _Phase.answering && exercise.type != ExerciseType.audioRecite)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: JFButton(
                    label: 'Verificar',
                    onPressed:
                        _state.selectedAnswer != null ? _verifyAnswer : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerArea(ExerciseModel exercise) {
    switch (exercise.type) {
      case ExerciseType.emojiGuess:
        return _EmojiGuessArea(
          exercise: exercise,
          selectedAnswer: _state.selectedAnswer,
          phase: _state.phase,
          onSelect: _selectAnswer,
        );
      case ExerciseType.audioRecite:
        return _AudioReciteArea(
          correctAnswer: exercise.correctAnswer?.toString() ?? '',
          phase: _state.phase,
          onResult: _selectAndVerify,
          onSkip: _nextExercise,
        );
      case ExerciseType.multipleChoice:
      case ExerciseType.trueFalse:
        return _MultipleChoiceArea(
          exercise: exercise,
          selectedAnswer: _state.selectedAnswer,
          phase: _state.phase,
          onSelect: _selectAnswer,
        );
      case ExerciseType.fillBlank:
        return _FillBlankArea(
          exercise: exercise,
          selectedAnswer: _state.selectedAnswer as String?,
          onChanged: _selectAnswer,
        );
      default:
        return _MultipleChoiceArea(
          exercise: exercise,
          selectedAnswer: _state.selectedAnswer,
          phase: _state.phase,
          onSelect: _selectAnswer,
        );
    }
  }

  String _getInstruction(ExerciseType type) {
    return switch (type) {
      ExerciseType.multipleChoice => 'Escolha a resposta correta:',
      ExerciseType.fillBlank => 'Complete a frase:',
      ExerciseType.wordOrder => 'Ordene as palavras:',
      ExerciseType.association => 'Conecte os pares:',
      ExerciseType.trueFalse => 'Verdadeiro ou falso?',
      ExerciseType.emojiGuess => 'Adivinhe pelo emoji!',
      ExerciseType.audioRecite => 'Recite em voz alta:',
    };
  }
}

// ─── Multiple Choice ─────────────────────────────────────────────────────────

class _MultipleChoiceArea extends StatelessWidget {
  final ExerciseModel exercise;
  final dynamic selectedAnswer;
  final _Phase phase;
  final ValueChanged<dynamic> onSelect;

  const _MultipleChoiceArea({
    required this.exercise,
    required this.selectedAnswer,
    required this.phase,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: exercise.options.map((option) {
        final isSelected = selectedAnswer == option;
        final isAnswering = phase == _Phase.answering;
        final isCorrectOption =
            option.toLowerCase() == exercise.correctAnswer.toString().toLowerCase();

        Color borderColor = AppColors.border;
        Color bgColor = Colors.white;

        if (!isAnswering && isSelected) {
          if (phase == _Phase.feedbackCorrect) {
            borderColor = AppColors.correct;
            bgColor = AppColors.correctLight;
          } else {
            borderColor = AppColors.incorrect;
            bgColor = AppColors.incorrectLight;
          }
        } else if (!isAnswering && isCorrectOption) {
          borderColor = AppColors.correct;
          bgColor = AppColors.correctLight;
        } else if (isSelected) {
          borderColor = AppColors.primary;
          bgColor = AppColors.primaryLight;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: isAnswering ? () => onSelect(option) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: isSelected
                    ? [BoxShadow(color: borderColor.withValues(alpha: 0.2), blurRadius: 8)]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!isAnswering && isCorrectOption)
                    const Icon(Icons.check_circle, color: AppColors.correct, size: 24),
                  if (!isAnswering && isSelected && !isCorrectOption)
                    const Icon(Icons.cancel, color: AppColors.incorrect, size: 24),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Fill Blank ──────────────────────────────────────────────────────────────

class _FillBlankArea extends StatelessWidget {
  final ExerciseModel exercise;
  final String? selectedAnswer;
  final ValueChanged<dynamic> onChanged;

  const _FillBlankArea({
    required this.exercise,
    required this.selectedAnswer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      autocorrect: false,
      style: const TextStyle(
        color: Color(0xFF1F2937),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Digite sua resposta...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ─── Feedback Bar ────────────────────────────────────────────────────────────

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String? explanation;
  final VoidCallback onContinue;

  const _FeedbackBar({
    required this.isCorrect,
    required this.correctAnswer,
    this.explanation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.correct : AppColors.incorrect;
    final bgColor = isCorrect ? AppColors.correctLight : AppColors.incorrectLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isCorrect ? 'Correto!' : 'Incorreto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isCorrect ? const Color(0xFF58CC02) : color,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Resposta correta: $correctAnswer',
              style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
            ),
          ],
          if (explanation != null) ...[
            const SizedBox(height: 6),
            Text(
              explanation!,
              style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? const Color(0xFF58CC02) : AppColors.incorrect,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Skeleton ────────────────────────────────────────────────────────

class _StageLoadingSkeleton extends StatelessWidget {
  const _StageLoadingSkeleton();

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
              const SizedBox(height: 20),
              // Progress bar placeholder
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 40),
              // Character placeholder
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Question placeholder
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 32),
              // Options placeholders
              for (int i = 0; i < 4; i++) ...[
                Container(
                  height: 56,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ],
              const Spacer(),
              Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Emoji Guess Area ─────────────────────────────────────────────────────────

class _EmojiGuessArea extends StatelessWidget {
  final ExerciseModel exercise;
  final dynamic selectedAnswer;
  final _Phase phase;
  final ValueChanged<dynamic> onSelect;

  const _EmojiGuessArea({
    required this.exercise,
    required this.selectedAnswer,
    required this.phase,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emoji hint display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Text(
            exercise.emojiHint ?? '❓',
            style: const TextStyle(fontSize: 48, letterSpacing: 8),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Options (reuse multiple choice layout)
        _MultipleChoiceArea(
          exercise: exercise,
          selectedAnswer: selectedAnswer,
          phase: phase,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

// ─── Exercise Energy Badge (replaces hearts) ─────────────────────────────────

class _ExerciseEnergyBadge extends StatelessWidget {
  final int energy;
  const _ExerciseEnergyBadge({required this.energy});

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
        Text(
          '$energy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Audio Recite Area (Self-Assessment with Mic UI) ─────────────────────────

enum _ReciteStep { initial, listening, confirm }

class _AudioReciteArea extends StatefulWidget {
  final String correctAnswer;
  final _Phase phase;
  final ValueChanged<dynamic> onResult;
  final VoidCallback onSkip;

  const _AudioReciteArea({
    required this.correctAnswer,
    required this.phase,
    required this.onResult,
    required this.onSkip,
  });

  @override
  State<_AudioReciteArea> createState() => _AudioReciteAreaState();
}

class _AudioReciteAreaState extends State<_AudioReciteArea>
    with TickerProviderStateMixin {
  _ReciteStep _step = _ReciteStep.initial;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startListening() {
    HapticFeedback.mediumImpact();
    setState(() => _step = _ReciteStep.listening);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // After 5 seconds of "listening", ask for self-assessment
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _step == _ReciteStep.listening) {
        _pulseController.stop();
        _pulseController.value = 0;
        _waveController.stop();
        _waveController.value = 0;
        setState(() => _step = _ReciteStep.confirm);
      }
    });
  }

  void _stopEarly() {
    _pulseController.stop();
    _pulseController.value = 0;
    _waveController.stop();
    _waveController.value = 0;
    setState(() => _step = _ReciteStep.confirm);
  }

  void _retryRecite() {
    setState(() => _step = _ReciteStep.initial);
  }

  @override
  Widget build(BuildContext context) {
    final isAnswered = widget.phase != _Phase.answering;

    return Column(
      children: [
        // Verse text card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Text(
            widget.correctAnswer,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),

        if (!isAnswered) ...[
          if (_step == _ReciteStep.initial) ...[
            // Mic button — tap to start
            GestureDetector(
              onTap: _startListening,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.mic_rounded, size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'TOQUE PARA FALAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_step == _ReciteStep.listening) ...[
            // Listening with wave animation
            GestureDetector(
              onTap: _stopEarly,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02).withValues(
                        alpha: 0.05 + _pulseController.value * 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF58CC02),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mic_rounded, size: 40, color: Color(0xFF58CC02)),
                        const SizedBox(height: 12),
                        // Audio wave bars
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(7, (i) {
                                final phase = (i * 0.15 + _waveController.value) % 1.0;
                                final height = 8.0 + 20.0 * (0.5 + 0.5 * (phase * 3.14159 * 2).abs().clamp(0.0, 1.0));
                                return Container(
                                  width: 4,
                                  height: height,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF58CC02),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'OUVINDO...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF58CC02),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Recite o versiculo em voz alta',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toque para parar',
                          style: TextStyle(fontSize: 11, color: Color(0xFF58CC02)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Confirm step — self-assessment
            const Text(
              'Voce conseguiu recitar?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131F24),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onResult(widget.correctAnswer),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58CC02),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF46A302),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SIM, CONSEGUI!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _retryRecite,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.incorrect,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFCC3B3B),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'TENTAR DE NOVO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          // Skip button — styled with border
          GestureDetector(
            onTap: widget.onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Text(
                'NAO POSSO FALAR AGORA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],

        if (isAnswered) ...[
          const SizedBox(height: 16),
          Icon(
            widget.phase == _Phase.feedbackCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 64,
            color: widget.phase == _Phase.feedbackCorrect
                ? const Color(0xFF58CC02)
                : AppColors.incorrect,
          ),
        ],
      ],
    );
  }
}
