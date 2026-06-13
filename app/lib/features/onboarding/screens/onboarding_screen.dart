import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/trail_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/jf_button.dart';
import '../models/onboarding_data.dart';
import '../widgets/dove_dialogue_bubble.dart';
import '../widgets/onboarding_option_card.dart';
import '../widgets/onboarding_progress_bar.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  int _currentPage = 0;

  // Step state
  String? _wantsToLearn;
  String? _heardFrom;
  String? _tradition;
  List<String> _motivation = [];
  String? _bibleLevel;
  int _dailyGoalMinutes = 10;

  static const _bgColor = Color(0xFFF0F7FF);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _next() => _goToPage(_currentPage + 1);
  void _back() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  // Whether the continue button should be enabled for the current step
  bool get _canContinue {
    switch (_currentPage) {
      case 0:
      case 1:
        return true;
      case 2:
        return _wantsToLearn != null;
      case 3:
        return _heardFrom != null;
      case 4:
        return _tradition != null;
      case 5:
        return _motivation.isNotEmpty;
      case 6:
        return _bibleLevel != null;
      case 7:
        return true; // daily goal always has a default
      default:
        return true;
    }
  }

  // Save all data to provider before transitioning to post-onboarding
  void _saveData() {
    final notifier = ref.read(onboardingDataProvider.notifier);
    if (_wantsToLearn != null) notifier.setWantsToLearn(_wantsToLearn!);
    if (_heardFrom != null) notifier.setHeardFrom(_heardFrom!);
    if (_tradition != null) notifier.setTradition(_tradition!);
    notifier.setMotivation(_motivation);
    if (_bibleLevel != null) notifier.setBibleLevel(_bibleLevel!);
    notifier.setDailyGoal(_dailyGoalMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          children: [
            _buildStep0Intro(),
            _buildStep1Intro2(),
            _buildStep2WantsToLearn(),
            _buildStep3HeardFrom(),
            _buildStep4Tradition(),
            _buildStep5Motivation(),
            _buildStep6BibleLevel(),
            _buildStep7DailyGoal(),
            _buildStep8Transition(),
            _buildStep9Preview(),
            _buildStep10Placement(),
          ],
        ),
      ),
    );
  }

  // ─── STEP 0: Intro ──────────────────────────────────────────────────────────

  Widget _buildStep0Intro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              );
            },
            child: const DoveDialogueBubble(
              text: 'Olá! Eu sou o Dove! \uD83D\uDC4B',
            ),
          ),
          const Spacer(flex: 3),
          JFButton(
            label: 'CONTINUAR',
            onPressed: _next,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── STEP 1: Intro 2 ────────────────────────────────────────────────────────

  Widget _buildStep1Intro2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const DoveDialogueBubble(
            text:
                'Vou te fazer 6 perguntas rápidas para personalizar sua jornada \uD83D\uDE4F',
          ),
          const Spacer(flex: 3),
          JFButton(
            label: 'VAMOS LÁ!',
            onPressed: _next,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── STEP 2 (Q1): O que gostaria de aprender? ─────────────────────────────

  Widget _buildStep2WantsToLearn() {
    const options = [
      {'emoji': '\uD83D\uDCD6', 'label': 'Histórias da Bíblia'},
      {'emoji': '\uD83D\uDE4F', 'label': 'Oração e Devoção'},
      {'emoji': '\u2708\uFE0F', 'label': 'Teologia básica'},
      {'emoji': '\uD83D\uDCAA', 'label': 'Crescimento espiritual'},
      {'emoji': '\uD83C\uDFB5', 'label': 'Louvor e Adoração'},
      {'emoji': '\u2753', 'label': 'Um pouco de tudo'},
    ];

    return _buildQuestionStep(
      questionIndex: 0,
      questionTotal: 6,
      question: 'O que você gostaria de aprender?',
      child: _buildSingleSelectList(
        options: options,
        selected: _wantsToLearn,
        onSelect: (v) => setState(() => _wantsToLearn = v),
      ),
    );
  }

  // ─── STEP 3 (Q2): Como soube do JourneyFaith? ─────────────────────────────

  Widget _buildStep3HeardFrom() {
    const options = [
      {'emoji': '\uD83D\uDCF1', 'label': 'TikTok'},
      {'emoji': '\uD83D\uDCF8', 'label': 'Instagram'},
      {'emoji': '\uD83D\uDCFA', 'label': 'YouTube'},
      {'emoji': '\uD83D\uDC65', 'label': 'Amigo ou familiar'},
      {'emoji': '\u26EA', 'label': 'Igreja'},
      {'emoji': '\uD83C\uDF10', 'label': 'Google / Pesquisa'},
      {'emoji': '\uD83D\uDCE2', 'label': 'Anúncio'},
      {'emoji': '\uD83C\uDFAE', 'label': 'App Store / Play Store'},
      {'emoji': '\uD83E\uDD37', 'label': 'Outro'},
    ];

    return _buildQuestionStep(
      questionIndex: 1,
      questionTotal: 6,
      question: 'Como você soube do JourneyFaith?',
      child: _buildSingleSelectList(
        options: options,
        selected: _heardFrom,
        onSelect: (v) => setState(() => _heardFrom = v),
      ),
    );
  }

  // ─── STEP 4 (Q3): Tradição cristã ─────────────────────────────────────────

  Widget _buildStep4Tradition() {
    const options = [
      {'emoji': '\u2720\uFE0F', 'label': 'Evangélico'},
      {'emoji': '\u271D\uFE0F', 'label': 'Católico'},
      {'emoji': '\uD83D\uDD4A\uFE0F', 'label': 'Protestante'},
      {'emoji': '\uD83C\uDF1F', 'label': 'Pentecostal'},
      {'emoji': '\u2721\uFE0F', 'label': 'Adventista'},
      {'emoji': '\uD83C\uDF3F', 'label': 'Outra tradição'},
      {'emoji': '\u2753', 'label': 'Prefiro não dizer'},
    ];

    return _buildQuestionStep(
      questionIndex: 2,
      questionTotal: 6,
      question: 'Qual é a sua tradição cristã?',
      note: 'Respeitamos todas as tradições. O conteúdo é baseado nas Escrituras.',
      child: _buildSingleSelectList(
        options: options,
        selected: _tradition,
        onSelect: (v) => setState(() => _tradition = v),
      ),
    );
  }

  // ─── STEP 5 (Q4): Motivação (multi select) ────────────────────────────────

  Widget _buildStep5Motivation() {
    const options = [
      {'emoji': '\uD83D\uDCD6', 'label': 'Conhecer a Bíblia'},
      {'emoji': '\uD83D\uDE4F', 'label': 'Fortalecer minha fé'},
      {'emoji': '\uD83D\uDCAA', 'label': 'Criar um hábito diário'},
      {'emoji': '\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67', 'label': 'Ensinar minha família'},
      {'emoji': '\uD83E\uDDD0', 'label': 'Curiosidade intelectual'},
      {'emoji': '\u26EA', 'label': 'Me preparar para a igreja'},
      {'emoji': '\u2764\uFE0F', 'label': 'Encontrar paz interior'},
    ];

    return _buildQuestionStep(
      questionIndex: 3,
      questionTotal: 6,
      question: 'Por que você quer aprender mais sobre a Bíblia?',
      note: 'Escolha até 3 opções',
      child: _buildMultiSelectList(
        options: options,
        selected: _motivation,
        maxSelections: 3,
        onToggle: (v) {
          setState(() {
            if (_motivation.contains(v)) {
              _motivation = List.from(_motivation)..remove(v);
            } else if (_motivation.length < 3) {
              _motivation = List.from(_motivation)..add(v);
            }
          });
        },
      ),
    );
  }

  // ─── STEP 6 (Q5): Nível bíblico ──────────────────────────────────────────

  Widget _buildStep6BibleLevel() {
    final options = [
      {
        'emoji': '\uD83C\uDF31',
        'label': 'Iniciante',
        'sublabel': 'Sei pouco ou nada',
      },
      {
        'emoji': '\uD83D\uDCD7',
        'label': 'Básico',
        'sublabel': 'Conheço algumas histórias',
      },
      {
        'emoji': '\uD83D\uDCDA',
        'label': 'Intermediário',
        'sublabel': 'Leio a Bíblia com frequência',
      },
      {
        'emoji': '\uD83C\uDFC6',
        'label': 'Avançado',
        'sublabel': 'Estudo a Bíblia há anos',
      },
    ];

    String? doveReaction;
    if (_bibleLevel == 'Iniciante') {
      doveReaction = 'Perfeito! Vamos começar do zero juntos! \uD83D\uDE0A';
    } else if (_bibleLevel == 'Básico') {
      doveReaction = 'Boa! Vamos expandir seu conhecimento! \uD83D\uDCAA';
    } else if (_bibleLevel == 'Intermediário') {
      doveReaction = 'Incrível! Vamos aprofundar ainda mais! \uD83D\uDD25';
    } else if (_bibleLevel == 'Avançado') {
      doveReaction = 'Impressionante! Vai ser um desafio! \uD83C\uDFC6';
    }

    return _buildQuestionStep(
      questionIndex: 4,
      questionTotal: 6,
      question: 'Quanto você conhece da Bíblia?',
      doveReaction: doveReaction,
      child: Column(
        children: options.map((o) {
          final label = o['label']!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OnboardingOptionCard(
              emoji: o['emoji']!,
              label: label,
              sublabel: o['sublabel'],
              isSelected: _bibleLevel == label,
              onTap: () => setState(() => _bibleLevel = label),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 7 (Q6): Meta diária ─────────────────────────────────────────────

  Widget _buildStep7DailyGoal() {
    final options = [
      {'emoji': '\uD83D\uDE0A', 'label': '5 min', 'sublabel': 'Relaxado', 'minutes': 5},
      {
        'emoji': '\uD83C\uDF1F',
        'label': '10 min',
        'sublabel': 'Regular',
        'minutes': 10,
        'recommended': true,
      },
      {'emoji': '\uD83D\uDCAA', 'label': '15 min', 'sublabel': 'Dedicado', 'minutes': 15},
      {'emoji': '\uD83D\uDD25', 'label': '20 min', 'sublabel': 'Intenso', 'minutes': 20},
    ];

    return _buildQuestionStep(
      questionIndex: 5,
      questionTotal: 6,
      question: 'Qual será sua meta diária?',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: options.map((o) {
          final minutes = o['minutes'] as int;
          final isSelected = _dailyGoalMinutes == minutes;
          final isRecommended = o['recommended'] == true;
          return GestureDetector(
            onTap: () => setState(() => _dailyGoalMinutes = minutes),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEBF3FD) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFDDE3EA),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(o['emoji'] as String,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    o['label'] as String,
                    style: AppTypography.headingMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    o['sublabel'] as String,
                    style: AppTypography.caption,
                  ),
                  if (isRecommended) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.xpColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\u2B50 Recomendado',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 8: Transition ───────────────────────────────────────────────────

  Widget _buildStep8Transition() {
    // Data is read locally — provider is saved only on navigation
    final data = OnboardingData(
      wantsToLearn: _wantsToLearn,
      heardFrom: _heardFrom,
      tradition: _tradition,
      motivation: _motivation,
      bibleLevel: _bibleLevel,
      dailyGoalMinutes: _dailyGoalMinutes,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const DoveDialogueBubble(
            text: 'Sua jornada foi personalizada! \uD83C\uDF89',
          ),
          const SizedBox(height: 24),
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('\uD83D\uDCD6', 'Foco',
                    data.wantsToLearn ?? 'Geral'),
                const SizedBox(height: 8),
                _summaryRow('\u26EA', 'Tradição',
                    data.tradition ?? 'Não informado'),
                const SizedBox(height: 8),
                _summaryRow('\uD83C\uDFAF', 'Nível',
                    data.bibleLevel ?? 'Iniciante'),
                const SizedBox(height: 8),
                _summaryRow('\u23F0', 'Meta diária',
                    '${data.dailyGoalMinutes} min/dia'),
              ],
            ),
          ),
          const Spacer(flex: 3),
          JFButton(
            label: 'CONTINUAR',
            onPressed: _next,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text('$label: ',
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w700)),
        Flexible(
          child: Text(value, style: AppTypography.bodyMedium),
        ),
      ],
    );
  }

  // ─── STEP 9: Preview ─────────────────────────────────────────────────────

  Widget _buildStep9Preview() {
    final benefits = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Domine as Escrituras',
        'desc': 'Aprenda as histórias e ensinamentos essenciais',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Hábito de Devoção',
        'desc': 'Construa uma prática espiritual consistente',
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Cresça na fé',
        'desc': 'Aprofunde seu relacionamento com Deus',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          const DoveDialogueBubble(
            text: 'Veja o que vai conseguir em 30 dias',
          ),
          const SizedBox(height: 24),
          ...benefits.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + i * 200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(b['icon'] as IconData,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['title'] as String,
                              style: AppTypography.headingMedium
                                  .copyWith(fontSize: 15)),
                          Text(b['desc'] as String,
                              style: AppTypography.bodyMedium
                                  .copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(flex: 2),
          JFButton(
            label: 'CONTINUAR',
            onPressed: _next,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── STEP 10: Placement ───────────────────────────────────────────────────

  Widget _buildStep10Placement() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const DoveDialogueBubble(
            text: 'Como deseja começar?',
          ),
          const SizedBox(height: 24),
          OnboardingOptionCard(
            emoji: '\uD83C\uDF31',
            label: 'Começar do zero',
            sublabel: 'Ideal para quem está começando',
            isSelected: false,
            onTap: () async {
              _saveData();
              ref.read(onboardingDataProvider.notifier).setExperienced(false);
              final nav = GoRouter.of(context);
              // Mark onboarding as completed
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_completed', true);
              // Start first lesson directly
              final lessonId = await fetchFirstLessonId(ref);
              nav.go(lessonId != null ? '/lesson/$lessonId' : '/home');
            },
          ),
          const SizedBox(height: 12),
          OnboardingOptionCard(
            emoji: '\uD83D\uDCDA',
            label: 'Já sei um pouco',
            sublabel: 'Teste de nível (em breve)',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Em breve!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildQuestionStep({
    required int questionIndex,
    required int questionTotal,
    required String question,
    String? note,
    String? doveReaction,
    required Widget child,
  }) {
    return Column(
      children: [
        OnboardingProgressBar(
          current: questionIndex,
          total: questionTotal,
          onBack: _back,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                DoveDialogueBubble(
                  text: question,
                  subtextBelowDove: doveReaction,
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: AppTypography.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: JFButton(
            label: 'CONTINUAR',
            onPressed: _canContinue ? _next : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleSelectList({
    required List<Map<String, String>> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      children: options.map((o) {
        final label = o['label']!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OnboardingOptionCard(
            emoji: o['emoji']!,
            label: label,
            isSelected: selected == label,
            onTap: () => onSelect(label),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectList({
    required List<Map<String, String>> options,
    required List<String> selected,
    required int maxSelections,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      children: options.map((o) {
        final label = o['label']!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OnboardingOptionCard(
            emoji: o['emoji']!,
            label: label,
            isSelected: selected.contains(label),
            onTap: () => onToggle(label),
          ),
        );
      }).toList(),
    );
  }
}
