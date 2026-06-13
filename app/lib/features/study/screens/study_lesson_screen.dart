import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/study_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/bible_study_model.dart';
import '../../../shared/widgets/jf_button.dart';
import '../../../shared/widgets/jf_progress_bar.dart';
import '../../../shared/widgets/jf_pf_badge.dart';
import '../engine/study_lesson_engine.dart';
import '../data/study_repository.dart';

const _kScaffoldBg = Color(0xFF1A2E4A);
const _kCardBg = Color(0xFF243B5C);
const _kDoveBubbleBg = Color(0xFF2E4A6E);
const _kCharacterBubbleBg = Color(0xFF1E3554);

class StudyLessonScreen extends ConsumerStatefulWidget {
  final String slug;
  final int lessonIndex;

  const StudyLessonScreen({super.key, required this.slug, required this.lessonIndex});

  @override
  ConsumerState<StudyLessonScreen> createState() => _StudyLessonScreenState();
}

class _StudyLessonScreenState extends ConsumerState<StudyLessonScreen>
    with TickerProviderStateMixin {
  List<StudyStep> _steps = [];
  int _currentStep = 0;
  bool _initialized = false;
  int _pfEarned = 0;
  bool _showPFBadge = false;

  // Quiz state
  dynamic _selectedAnswer;
  bool _quizAnswered = false;
  bool _quizCorrect = false;

  // Word order state
  List<String> _selectedWords = [];

  // AI explanation
  String? _aiExplanation;
  bool _aiLoading = false;

  // Typing animation
  String _displayedText = '';
  Timer? _typingTimer;
  bool _typingComplete = false;

  @override
  void initState() {
    super.initState();
    _prefetchAI();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _prefetchAI() {
    setState(() => _aiLoading = true);
    studyRepository
        .fetchAIExplanation(widget.slug, widget.lessonIndex)
        .then((explanation) {
      if (mounted) {
        setState(() {
          _aiExplanation = explanation;
          _aiLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _aiExplanation = null;
          _aiLoading = false;
        });
      }
    });
  }

  void _initSteps(BibleStudyModel study) {
    if (_initialized || study.lessons.isEmpty) return;
    if (widget.lessonIndex >= study.lessons.length) return;

    final lesson = study.lessons[widget.lessonIndex];
    final engine = StudyLessonEngine(
      lesson: lesson,
      characterName: study.character?.name ?? 'Personagem',
    );

    _initialized = true;
    _steps = engine.buildSteps();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _typingTimer?.cancel();
    _typingComplete = false;
    _displayedText = '';

    final step = _currentStep < _steps.length ? _steps[_currentStep] : null;
    if (step == null) return;

    final fullText = _getStepText(step);
    if (fullText.isEmpty) {
      _typingComplete = true;
      return;
    }

    int charIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex >= fullText.length) {
        timer.cancel();
        setState(() => _typingComplete = true);
        return;
      }
      charIndex++;
      setState(() => _displayedText = fullText.substring(0, charIndex));
    });
  }

  void _skipTyping() {
    _typingTimer?.cancel();
    final step = _currentStep < _steps.length ? _steps[_currentStep] : null;
    if (step == null) return;
    setState(() {
      _displayedText = _getStepText(step);
      _typingComplete = true;
    });
  }

  String _getStepText(StudyStep step) {
    switch (step.type) {
      case StudyStepType.dialogueDoveIntro:
      case StudyStepType.dialogueCharacter:
      case StudyStepType.dialogueReaction:
      case StudyStepType.dialogueDoveComment:
      case StudyStepType.dialogueApplication:
      case StudyStepType.dialogueDoveClose:
        return step.text ?? '';
      case StudyStepType.aiExplanation:
        return _aiExplanation ?? step.text ?? '';
      default:
        return '';
    }
  }

  void _goNext() {
    if (_currentStep >= _steps.length - 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep++;
      _selectedAnswer = null;
      _quizAnswered = false;
      _quizCorrect = false;
      _selectedWords = [];
      _showPFBadge = false;
    });
    _startTypingAnimation();
  }

  void _onQuizAnswer(bool correct, int pf) {
    HapticFeedback.mediumImpact();
    setState(() {
      _quizAnswered = true;
      _quizCorrect = correct;
      if (correct) {
        _pfEarned += pf;
        _showPFBadge = true;
        ref.read(currentUserProvider.notifier).gainPF(pf);
      }
    });
  }

  void _onComplete() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      studyRepository.completeLesson(
        widget.slug,
        widget.lessonIndex,
        user.id,
        _pfEarned,
      );
    }
  }

  double get _progressValue =>
      _steps.isEmpty ? 0 : (_currentStep + 1) / _steps.length;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(studyDetailProvider(widget.slug));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _kScaffoldBg,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _kScaffoldBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erro ao carregar', style: AppTypography.headingMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
      data: (study) {
        _initSteps(study);
        if (_steps.isEmpty) {
          return Scaffold(
            backgroundColor: _kScaffoldBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Licao nao disponivel',
                      style: AppTypography.headingMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Voltar', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          );
        }

        final step = _steps[_currentStep];
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _showExitDialog(context);
          },
          child: Scaffold(
            backgroundColor: _kScaffoldBg,
            body: SafeArea(
              child: Column(
                children: [
                  // Top bar: close + progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showExitDialog(context),
                          child: const Icon(Icons.close, color: Colors.white54, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: JFProgressBar(
                            value: _progressValue,
                            height: 14,
                            color: AppColors.correct,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '+$_pfEarned PF',
                          style: AppTypography.xpText.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Step content
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!_typingComplete) {
                          _skipTyping();
                        }
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: _buildStepContent(step, study),
                      ),
                    ),
                  ),

                  // PF Badge
                  if (_showPFBadge)
                    JFPFBadge(
                      pfAmount: 5,
                      onAnimationComplete: () {
                        if (mounted) setState(() => _showPFBadge = false);
                      },
                    ),

                  // Bottom action
                  _buildBottomAction(step),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(StudyStep step, BibleStudyModel study) {
    switch (step.type) {
      case StudyStepType.dialogueDoveIntro:
      case StudyStepType.dialogueDoveComment:
      case StudyStepType.dialogueDoveClose:
        return _DoveDialogueBubble(
          text: _displayedText,
          isComplete: _typingComplete,
        );

      case StudyStepType.dialogueCharacter:
      case StudyStepType.dialogueReaction:
      case StudyStepType.dialogueApplication:
        return _CharacterDialogueBubble(
          characterName: step.speaker ?? study.character?.name ?? 'Personagem',
          text: _displayedText,
          isComplete: _typingComplete,
          colorHex: study.character?.colorHex,
        );

      case StudyStepType.verseCard:
        return _VerseCard(
          verseRef: step.verseRef ?? '',
          verseText: step.verseText ?? '',
        );

      case StudyStepType.aiExplanation:
        return _AIExplanationCard(
          text: _aiLoading ? null : (_aiExplanation ?? _displayedText),
          isLoading: _aiLoading,
          displayedText: _displayedText,
          isTypingComplete: _typingComplete,
        );

      case StudyStepType.quiz:
        return _buildQuizWidget(step);

      case StudyStepType.completion:
        return _CompletionCard(
          pfEarned: _pfEarned,
          lessonTitle: study.lessons.length > widget.lessonIndex
              ? study.lessons[widget.lessonIndex].title
              : 'Licao',
        );
    }
  }

  Widget _buildQuizWidget(StudyStep step) {
    switch (step.quizType) {
      case StudyQuizType.multipleChoice:
        return _QuizMultipleChoice(
          quiz: step.quizMC,
          selectedAnswer: _selectedAnswer as String?,
          isAnswered: _quizAnswered,
          isCorrect: _quizCorrect,
          onSelect: (answer) {
            if (_quizAnswered) return;
            setState(() => _selectedAnswer = answer);
          },
          onVerify: () {
            if (_selectedAnswer == null || _quizAnswered) return;
            final correct = _selectedAnswer == step.quizMC?.correctAnswer;
            _onQuizAnswer(correct, step.pfReward);
          },
        );

      case StudyQuizType.fillBlank:
        return _QuizFillBlank(
          quiz: step.quizFill,
          selectedWord: _selectedAnswer as String?,
          isAnswered: _quizAnswered,
          isCorrect: _quizCorrect,
          onSelect: (word) {
            if (_quizAnswered) return;
            setState(() => _selectedAnswer = word);
          },
          onVerify: () {
            if (_selectedAnswer == null || _quizAnswered) return;
            final correct = _selectedAnswer == step.quizFill?.correctWord;
            _onQuizAnswer(correct, step.pfReward);
          },
        );

      case StudyQuizType.wordOrder:
        return _QuizWordOrder(
          quiz: step.quizOrder,
          selectedWords: _selectedWords,
          isAnswered: _quizAnswered,
          isCorrect: _quizCorrect,
          onToggle: (word) {
            if (_quizAnswered) return;
            setState(() {
              if (_selectedWords.contains(word)) {
                _selectedWords.remove(word);
              } else {
                _selectedWords.add(word);
              }
              _selectedAnswer = _selectedWords.join(' ');
            });
          },
          onVerify: () {
            if (_selectedWords.isEmpty || _quizAnswered) return;
            final correct = _selectedWords.join(' ') ==
                (step.quizOrder?.correctOrder.join(' ') ?? '');
            _onQuizAnswer(correct, step.pfReward);
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomAction(StudyStep step) {
    if (step.type == StudyStepType.completion) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: JFButton(
          label: 'Concluir',
          onPressed: () {
            _onComplete();
            context.pop();
          },
        ),
      );
    }

    if (step.type == StudyStepType.quiz) {
      if (!_quizAnswered) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: JFButton(
            label: 'Verificar',
            onPressed: _selectedAnswer != null ? () => _triggerVerify(step) : null,
          ),
        );
      }
      // After quiz answered, show continue
      return _QuizFeedbackBar(
        isCorrect: _quizCorrect,
        explanation: _getQuizExplanation(step),
        onContinue: _goNext,
      );
    }

    // Dialogue / verse / AI steps
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: JFButton(
        label: 'Continuar',
        onPressed: _typingComplete ? _goNext : null,
      ),
    );
  }

  void _triggerVerify(StudyStep step) {
    // Delegate to the quiz widget's verify callback
    switch (step.quizType) {
      case StudyQuizType.multipleChoice:
        if (_selectedAnswer == null || _quizAnswered) return;
        final correct = _selectedAnswer == step.quizMC?.correctAnswer;
        _onQuizAnswer(correct, step.pfReward);
        break;
      case StudyQuizType.fillBlank:
        if (_selectedAnswer == null || _quizAnswered) return;
        final correct = _selectedAnswer == step.quizFill?.correctWord;
        _onQuizAnswer(correct, step.pfReward);
        break;
      case StudyQuizType.wordOrder:
        if (_selectedWords.isEmpty || _quizAnswered) return;
        final correct = _selectedWords.join(' ') ==
            (step.quizOrder?.correctOrder.join(' ') ?? '');
        _onQuizAnswer(correct, step.pfReward);
        break;
      default:
        break;
    }
  }

  String? _getQuizExplanation(StudyStep step) {
    switch (step.quizType) {
      case StudyQuizType.multipleChoice:
        return step.quizMC?.explanation;
      case StudyQuizType.fillBlank:
        return step.quizFill?.explanation;
      case StudyQuizType.wordOrder:
        return step.quizOrder?.explanation;
      default:
        return null;
    }
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        title: Text('Sair do estudo?', style: AppTypography.headingMedium.copyWith(color: Colors.white)),
        content: Text(
          'Voce perdera o progresso desta licao.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar estudando', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sair', style: TextStyle(color: AppColors.incorrect)),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      context.pop();
    }
  }
}

// ── Dove Dialogue Bubble ─────────────────────────────────────────────────────

class _DoveDialogueBubble extends StatelessWidget {
  final String text;
  final bool isComplete;
  const _DoveDialogueBubble({required this.text, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dove avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: const Center(child: Text('\u{1F54A}', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          // Bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kDoveBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pomba',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.mana,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  if (!isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _TypingDots(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Character Dialogue Bubble ────────────────────────────────────────────────

class _CharacterDialogueBubble extends StatelessWidget {
  final String characterName;
  final String text;
  final bool isComplete;
  final String? colorHex;

  const _CharacterDialogueBubble({
    required this.characterName,
    required this.text,
    required this.isComplete,
    this.colorHex,
  });

  Color get _charColor {
    if (colorHex != null) {
      return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
    }
    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCharacterBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    characterName,
                    style: AppTypography.caption.copyWith(
                      color: _charColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (!isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _TypingDots(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Character avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _charColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _charColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                characterName.isNotEmpty ? characterName[0].toUpperCase() : '\u{2728}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _charColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verse Card ───────────────────────────────────────────────────────────────

class _VerseCard extends StatelessWidget {
  final String verseRef;
  final String verseText;
  const _VerseCard({required this.verseRef, required this.verseText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('\u{1F4D6}', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 16),
            Text(
              '"$verseText"',
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 18,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                verseRef,
                style: AppTypography.label.copyWith(
                  color: AppColors.gold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Explanation Card ──────────────────────────────────────────────────────

class _AIExplanationCard extends StatelessWidget {
  final String? text;
  final bool isLoading;
  final String displayedText;
  final bool isTypingComplete;

  const _AIExplanationCard({
    required this.text,
    required this.isLoading,
    required this.displayedText,
    required this.isTypingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mana.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.mana, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Explicacao',
                  style: AppTypography.label.copyWith(color: AppColors.mana),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              Column(
                children: [
                  _TypingDots(),
                  const SizedBox(height: 8),
                  Text(
                    'Gerando explicacao...',
                    style: AppTypography.caption.copyWith(color: Colors.white54),
                  ),
                ],
              )
            else
              Text(
                displayedText,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
            if (!isLoading && !isTypingComplete)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TypingDots(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz Multiple Choice ─────────────────────────────────────────────────────

class _QuizMultipleChoice extends StatelessWidget {
  final QuizMC? quiz;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final Function(String) onSelect;
  final VoidCallback onVerify;

  const _QuizMultipleChoice({
    required this.quiz,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.onSelect,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    if (quiz == null) {
      return Center(
        child: Text('Quiz indisponivel',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz!.question,
            style: AppTypography.headingMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ...quiz!.options.map((option) {
            final isSelected = selectedAnswer == option;
            final isCorrectOption = option == quiz!.correctAnswer;

            Color borderColor = Colors.white.withValues(alpha: 0.15);
            Color bgColor = _kCardBg;

            if (isAnswered) {
              if (isCorrectOption) {
                borderColor = AppColors.correct;
                bgColor = AppColors.correct.withValues(alpha: 0.15);
              } else if (isSelected && !isCorrectOption) {
                borderColor = AppColors.incorrect;
                bgColor = AppColors.incorrect.withValues(alpha: 0.15);
              }
            } else if (isSelected) {
              borderColor = AppColors.mana;
              bgColor = AppColors.mana.withValues(alpha: 0.1);
            }

            return GestureDetector(
              onTap: isAnswered ? null : () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
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
                      child: Text(
                        option,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isAnswered && isCorrectOption)
                      const Icon(Icons.check_circle, color: AppColors.correct, size: 24),
                    if (isAnswered && isSelected && !isCorrectOption)
                      const Icon(Icons.cancel, color: AppColors.incorrect, size: 24),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Quiz Fill Blank ──────────────────────────────────────────────────────────

class _QuizFillBlank extends StatelessWidget {
  final QuizFill? quiz;
  final String? selectedWord;
  final bool isAnswered;
  final bool isCorrect;
  final Function(String) onSelect;
  final VoidCallback onVerify;

  const _QuizFillBlank({
    required this.quiz,
    required this.selectedWord,
    required this.isAnswered,
    required this.isCorrect,
    required this.onSelect,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    if (quiz == null) {
      return Center(
        child: Text('Quiz indisponivel',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54)),
      );
    }

    // Replace blank placeholder in sentence
    final displaySentence = quiz!.sentence.replaceAll('___', selectedWord ?? '___');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete a frase:',
            style: AppTypography.label.copyWith(color: AppColors.mana),
          ),
          const SizedBox(height: 16),
          // Sentence with blank
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              displaySentence,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Escolha a palavra:',
            style: AppTypography.caption.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quiz!.options.map((word) {
              final isSelected = selectedWord == word;
              final isCorrectWord = word == quiz!.correctWord;

              Color borderColor = Colors.white.withValues(alpha: 0.2);
              Color bgColor = Colors.transparent;

              if (isAnswered) {
                if (isCorrectWord) {
                  borderColor = AppColors.correct;
                  bgColor = AppColors.correct.withValues(alpha: 0.15);
                } else if (isSelected && !isCorrectWord) {
                  borderColor = AppColors.incorrect;
                  bgColor = AppColors.incorrect.withValues(alpha: 0.15);
                }
              } else if (isSelected) {
                borderColor = AppColors.mana;
                bgColor = AppColors.mana.withValues(alpha: 0.1);
              }

              return GestureDetector(
                onTap: isAnswered ? null : () => onSelect(word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Text(
                    word,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Quiz Word Order ──────────────────────────────────────────────────────────

class _QuizWordOrder extends StatelessWidget {
  final QuizOrder? quiz;
  final List<String> selectedWords;
  final bool isAnswered;
  final bool isCorrect;
  final Function(String) onToggle;
  final VoidCallback onVerify;

  const _QuizWordOrder({
    required this.quiz,
    required this.selectedWords,
    required this.isAnswered,
    required this.isCorrect,
    required this.onToggle,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    if (quiz == null) {
      return Center(
        child: Text('Quiz indisponivel',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white54)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz!.instruction.isNotEmpty
                ? quiz!.instruction
                : 'Coloque as palavras na ordem correta:',
            style: AppTypography.headingMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),

          // Selected words area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAnswered
                    ? (isCorrect ? AppColors.correct : AppColors.incorrect)
                    : Colors.white.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: selectedWords.isEmpty
                ? Text(
                    'Toque nas palavras abaixo...',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white38),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedWords.map((word) {
                      return GestureDetector(
                        onTap: isAnswered ? null : () => onToggle(word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mana.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.mana.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            word,
                            style: AppTypography.label.copyWith(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // Word bank
          Text(
            'Banco de palavras:',
            style: AppTypography.caption.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quiz!.scrambledWords.map((word) {
              final isUsed = selectedWords.contains(word);
              return GestureDetector(
                onTap: (isAnswered || isUsed) ? null : () => onToggle(word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUsed
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    word,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isUsed ? Colors.white24 : Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Completion Card ──────────────────────────────────────────────────────────

class _CompletionCard extends StatefulWidget {
  final int pfEarned;
  final String lessonTitle;
  const _CompletionCard({required this.pfEarned, required this.lessonTitle});

  @override
  State<_CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<_CompletionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Licao Concluida!',
              style: AppTypography.displayMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.lessonTitle,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // PF earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.xpColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.xpColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u{2728}', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    '+${widget.pfEarned} PF',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.xpColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Continue estudando para aprofundar sua fe!',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz Feedback Bar ────────────────────────────────────────────────────────

class _QuizFeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback onContinue;

  const _QuizFeedbackBar({
    required this.isCorrect,
    this.explanation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect
        ? AppColors.correct.withValues(alpha: 0.15)
        : AppColors.incorrect.withValues(alpha: 0.15);
    final accentColor = isCorrect ? AppColors.correct : AppColors.incorrect;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: accentColor, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: accentColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isCorrect ? 'Correto!' : 'Quase la!',
                style: AppTypography.headingMedium.copyWith(
                  color: accentColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation!,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          JFButton(
            label: 'Continuar',
            variant: isCorrect ? JFButtonVariant.primary : JFButtonVariant.secondary,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

// ── Typing Dots Animation ────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final opacity = ((t - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * opacity;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: opacity * 0.6 + 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
