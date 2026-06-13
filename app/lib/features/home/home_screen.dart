import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/trail_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/trail_provider.dart';
import '../../shared/models/lesson_model.dart';
import '../../shared/models/lesson_progress_model.dart';
import '../../shared/widgets/jf_button.dart';
import '../gamification/providers/gamification_providers.dart';
import '../lesson/providers/lesson_progress_provider.dart';
import 'widgets/streak_badge.dart';
import 'widgets/crystal_badge.dart';
import 'widgets/lesson_node.dart';
import '../characters/presentation/widgets/trail_character_widget.dart';
import '../characters/providers/character_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final trailsAsync = ref.watch(trailListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
        ),
        error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(currentUserProvider)),
        data: (user) {
          return Column(
            children: [
              _StickyHeader(user: user),
              if (user == null) _GuestBanner(),
              Expanded(
                child: trailsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Erro ao carregar trilhas',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  data: (trails) {
                    if (trails.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma trilha disponível',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return _TrailScrollView(trails: trails);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sticky Header ───────────────────────────────────────────────────────────

class _StickyHeader extends ConsumerWidget {
  final dynamic user;
  const _StickyHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final completedAsync = ref.watch(completedTodayProvider);
    final crystalAsync = ref.watch(crystalProvider);
    final livesAsync = ref.watch(livesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final streakCount = streakAsync.valueOrNull ?? (user?.streakCurrent ?? 0) as int;
    final completedToday = completedAsync.valueOrNull ?? false;
    final crystals = crystalAsync.valueOrNull ?? (user?.manas ?? 0) as int;
    final hearts = livesAsync.valueOrNull?.current ?? (user?.energy ?? 20) as int;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Dove logo (fixed left)
              Container(
                width: TrailConstants.topBarIconSize,
                height: TrailConstants.topBarIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/dove_icon.png',
                    width: TrailConstants.topBarIconSize,
                    height: TrailConstants.topBarIconSize,
                  ),
                ),
              ),
              // PF, Streak, Crystal, Energy — centered and evenly spaced
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // PF (Pontos na Fé) counter
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user?.pfTotal ?? 0}',
                          style: TextStyle(
                            fontSize: TrailConstants.statFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    // Streak badge → taps to Ofensiva screen
                    GestureDetector(
                      onTap: () => context.push('/streak'),
                      child: StreakBadge(count: streakCount, completedToday: completedToday),
                    ),
                    // Crystal badge → taps to Loja screen
                    GestureDetector(
                      onTap: () => context.push('/store'),
                      child: CrystalBadge(count: crystals),
                    ),
                    // Energy indicator → taps to Energy screen
                    GestureDetector(
                      onTap: () => context.push('/energy'),
                      child: _EnergyBadge(current: hearts, isDark: isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Energy Badge (battery-style for header) ────────────────────────────────

class _EnergyBadge extends StatelessWidget {
  final int current;
  final bool isDark;

  const _EnergyBadge({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    if (current >= 15) {
      barColor = const Color(0xFF42A5F5); // blue when full/high
    } else if (current >= 8) {
      barColor = const Color(0xFFFFD54F); // yellow medium
    } else if (current >= 5) {
      barColor = const Color(0xFFFF9800); // orange low
    } else if (current > 0) {
      barColor = const Color(0xFFEF5350); // red critical
    } else {
      barColor = isDark ? AppColors.darkTextSecond : AppColors.textHint;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: 1.5708, // 90 degrees — lay battery on its side
          child: Icon(
            current > 0 ? Icons.battery_charging_full_rounded : Icons.battery_0_bar_rounded,
            size: TrailConstants.statEmojiSize,
            color: barColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$current',
          style: TextStyle(
            fontSize: TrailConstants.statFontSize,
            fontWeight: FontWeight.w800,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

// ─── Guest Banner ────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Crie uma conta para salvar seu progresso',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextPrimary : AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/onboarding/create-account'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Criar',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trail Scroll View ───────────────────────────────────────────────────────

class _TrailScrollView extends StatefulWidget {
  final List<TrailModel> trails;
  const _TrailScrollView({required this.trails});

  @override
  State<_TrailScrollView> createState() => _TrailScrollViewState();
}

class _TrailScrollViewState extends State<_TrailScrollView> {
  final ScrollController _scrollController = ScrollController();
  int _currentUnitIndex = 0;

  late List<UnitModel> _allUnits;
  late List<TrailModel> _unitToTrail;
  late List<GlobalKey> _unitKeys;

  @override
  void initState() {
    super.initState();
    _allUnits = [];
    _unitToTrail = [];
    for (final trail in widget.trails) {
      for (final unit in trail.units) {
        _allUnits.add(unit);
        _unitToTrail.add(trail);
      }
    }
    _unitKeys = List.generate(_allUnits.length, (_) => GlobalKey());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    int bestIndex = 0;
    for (int i = 0; i < _unitKeys.length; i++) {
      final keyContext = _unitKeys[i].currentContext;
      if (keyContext == null) continue;
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero).dy;
      if (position < 200) bestIndex = i;
    }
    if (bestIndex != _currentUnitIndex) {
      setState(() => _currentUnitIndex = bestIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_allUnits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F4DA}', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Nenhuma unidade disponivel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'As unidades e licoes serao carregadas quando cadastradas no admin.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _UnitHeaderCard(
          unit: _allUnits[_currentUnitIndex],
          trail: _unitToTrail[_currentUnitIndex],
          allUnits: _allUnits.where((u) => _unitToTrail[_allUnits.indexOf(u)].id == _unitToTrail[_currentUnitIndex].id).toList(),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 60),
            itemCount: _allUnits.length,
            itemBuilder: (context, index) {
              return Column(
                key: _unitKeys[index],
                children: [
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _UnitSeparator(unit: _allUnits[index]),
                    ),
                  _DuolingoPath(unit: _allUnits[index]),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Unit Header Card (sticky) ──────────────────────────────────────────────

class _UnitHeaderCard extends StatelessWidget {
  final UnitModel unit;
  final TrailModel trail;
  final List<UnitModel> allUnits;
  const _UnitHeaderCard({required this.unit, required this.trail, required this.allUnits});

  int get _completedCount =>
      unit.lessons.where((l) => l.status == LessonStatus.completed).length;
  double get _progressPercent =>
      unit.lessons.isEmpty ? 0 : _completedCount / unit.lessons.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = unit.color != null
        ? Color(int.parse(unit.color!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(unit.id),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.4 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.title,
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unit.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13, fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTrailModal(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progressPercent,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      color: Colors.white,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_progressPercent * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTrailModal(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1B2838) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A2E4A);
    final textSecondary = isDark ? const Color(0xFF8BA3B8) : const Color(0xFF6B7280);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Trail title
              Text(
                trail.title,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trail.description,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 20),
              // Sessions/Units
              ...allUnits.asMap().entries.map((entry) {
                final idx = entry.key;
                final u = entry.value;
                final uColor = u.color != null
                    ? Color(int.parse(u.color!.replaceFirst('#', '0xFF')))
                    : AppColors.primary;
                final completedLessons = u.lessons.where((l) => l.status == LessonStatus.completed).length;
                final totalLessons = u.lessons.length;
                final isCurrent = u.id == unit.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? uColor.withValues(alpha: isDark ? 0.15 : 0.08)
                        : (isDark ? const Color(0xFF253545) : const Color(0xFFF5F7FA)),
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrent
                        ? Border.all(color: uColor.withValues(alpha: 0.5), width: 2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: uColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.title,
                                  style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '$completedLessons/$totalLessons concluidas',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: uColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ATUAL',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                      // Lessons list
                      const SizedBox(height: 10),
                      ...u.lessons.map((lesson) {
                        final isCompleted = lesson.status == LessonStatus.completed;
                        final isAvailable = lesson.status == LessonStatus.current || lesson.status == LessonStatus.available;
                        return Padding(
                          padding: const EdgeInsets.only(left: 44, top: 4, bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : isAvailable
                                        ? Icons.radio_button_unchecked
                                        : Icons.lock_rounded,
                                size: 18,
                                color: isCompleted
                                    ? const Color(0xFF58CC02)
                                    : isAvailable
                                        ? uColor
                                        : textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lesson.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isCompleted || isAvailable ? textPrimary : textSecondary,
                                    fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Unit Separator ──────────────────────────────────────────────────────────

class _UnitSeparator extends StatelessWidget {
  final UnitModel unit;
  const _UnitSeparator({required this.unit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = unit.color != null
        ? Color(int.parse(unit.color!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unit.title,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? color.withValues(alpha: 0.9) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Duolingo-style Path (CENTERED, zigzag, organic) ─────────────────────────

class _DuolingoPath extends ConsumerStatefulWidget {
  final UnitModel unit;
  const _DuolingoPath({required this.unit});

  @override
  ConsumerState<_DuolingoPath> createState() => _DuolingoPathState();
}

class _DuolingoPathState extends ConsumerState<_DuolingoPath> {
  OverlayEntry? _tooltipEntry;
  final Map<int, GlobalKey> _nodeKeys = {};

  GlobalKey _keyForIndex(int index) =>
      _nodeKeys.putIfAbsent(index, () => GlobalKey());

  // TODO: Reativar animacao do personagem na trilha posteriormente
  Widget _buildTrailCharacter() {
    return const SizedBox.shrink();
    // final charAsync = ref.watch(defaultCharacterProvider);
    // return charAsync.when(
    //   data: (character) => character != null
    //       ? TrailCharacterWidget(character: character)
    //       : const SizedBox.shrink(),
    //   loading: () => const SizedBox.shrink(),
    //   error: (_, __) => const SizedBox.shrink(),
    // );
  }

  /// Calculate a smooth zigzag X offset for node at index i.
  /// Returns value from -1.0 to 1.0 (fraction of amplitude).
  double _zigzagFraction(int i) {
    // Pattern: 0, 1, 0, -1, 0, 1, 0, -1, ...
    // Using sin for smooth interpolation
    return sin(i * pi / 2);
  }

  void _showTooltip(BuildContext nodeContext, LessonModel lesson,
      LessonProgressModel? progress, Color unitColor) {
    _dismissTooltip();

    final renderBox = nodeContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final nodeRenderSize = renderBox.size;
    final pfReward = (progress?.stagesTotal ?? 1) * 10;
    final isCompleted = progress?.isCompleted ?? false;
    final isInProgress = progress?.isInProgress ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;

    // Center tooltip horizontally relative to the node
    const tooltipW = 260.0;
    double tooltipLeft = position.dx + nodeRenderSize.width / 2 - tooltipW / 2;
    tooltipLeft = tooltipLeft.clamp(16.0, screenW - tooltipW - 16);

    _tooltipEntry = OverlayEntry(builder: (_) => Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: _dismissTooltip,
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
      Positioned(
        top: position.dy + nodeRenderSize.height + 12,
        left: tooltipLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: tooltipW,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                ),
              ),
              if (progress != null && progress.stagesTotal > 1) ...[
                const SizedBox(height: 10),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.progressFraction,
                    backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                    color: unitColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Etapa ${progress.stagesCompleted}/${progress.stagesTotal}',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Action button with Duolingo 3D shadow style
              _Duo3DButton(
                label: isCompleted
                    ? 'REVISAR'
                    : isInProgress
                        ? 'CONTINUAR'
                        : 'COMEÇAR  +$pfReward PF',
                color: isCompleted ? AppColors.correct : unitColor,
                onTap: () {
                  _dismissTooltip();
                  final stagesTotal = progress?.stagesTotal ??
                      (lesson.stagesCount > 0 ? lesson.stagesCount : 1);
                  final currentStage = progress?.currentStage ?? 0;

                  if (isCompleted) {
                    // Review mode: start at stage 0 with review flag
                    GoRouter.of(context).push(
                      '/lesson/${lesson.id}/stage/0?stagesTotal=$stagesTotal&review=1',
                    );
                  } else {
                    // Sempre usa LessonStageScreen para garantir sync correto
                    // com backend (PF, liga e avanço na trilha)
                    final total = stagesTotal < 1 ? 1 : stagesTotal;
                    GoRouter.of(context).push(
                      '/lesson/${lesson.id}/stage/$currentStage?stagesTotal=$total',
                    );
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    ]));

    Overlay.of(nodeContext).insert(_tooltipEntry!);
  }

  void _dismissTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  void dispose() {
    _dismissTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.unit.lessons;
    if (lessons.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final amplitude = screenWidth * TrailConstants.zigzagAmplitude;
    final unitColor = widget.unit.color != null
        ? Color(int.parse(widget.unit.color!.replaceFirst('#', '0xFF')))
        : AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build progress map
    final progressMap = <String, LessonProgressModel>{};
    for (final lesson in lessons) {
      final progressAsync = ref.watch(lessonProgressProvider(lesson.id));
      final progress = progressAsync.valueOrNull;
      if (progress != null) progressMap[lesson.id] = progress;
    }

    // Total height for the path area
    const nodeH = TrailConstants.nodeSize + 40; // node + stage dots + padding
    final totalHeight = lessons.length * TrailConstants.nodeVerticalSpacing;

    return SizedBox(
      width: screenWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: _TrailPathPainter(
          lessonCount: lessons.length,
          amplitude: amplitude,
          screenWidth: screenWidth,
          lessonStatuses: lessons.map((l) => l.status).toList(),
          isDark: isDark,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(lessons.length, (i) {
            final lesson = lessons[i];
            final progress = progressMap[lesson.id];
            final nodeKey = _keyForIndex(i);
            final offsetX = _zigzagFraction(i) * amplitude;
            final centerY = i * TrailConstants.nodeVerticalSpacing +
                TrailConstants.nodeVerticalSpacing / 2 -
                nodeH / 2;

            final isCurrent = lesson.status == LessonStatus.current;

            return Positioned(
              top: centerY,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(offsetX, 0),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LessonNode(
                        key: nodeKey,
                        lesson: lesson,
                        progress: progress,
                        unitColor: unitColor,
                        onTap: () {
                          if (lesson.status == LessonStatus.locked) return;
                          final keyContext = nodeKey.currentContext;
                          if (keyContext != null) {
                            _showTooltip(keyContext, lesson, progress, unitColor);
                          }
                        },
                      ),
                      // Character companion next to current lesson
                      if (isCurrent)
                        Positioned(
                          right: -60,
                          top: -8,
                          child: _buildTrailCharacter(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Trail Path Painter ──────────────────────────────────────────────────────

class _TrailPathPainter extends CustomPainter {
  final int lessonCount;
  final double amplitude;
  final double screenWidth;
  final List<LessonStatus> lessonStatuses;
  final bool isDark;

  _TrailPathPainter({
    required this.lessonCount,
    required this.amplitude,
    required this.screenWidth,
    required this.lessonStatuses,
    required this.isDark,
  });

  double _nodeX(int i) {
    return screenWidth / 2 + sin(i * pi / 2) * amplitude;
  }

  double _nodeY(int i) {
    return i * TrailConstants.nodeVerticalSpacing +
        TrailConstants.nodeVerticalSpacing / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonCount < 2) return;

    for (int i = 0; i < lessonCount - 1; i++) {
      final x1 = _nodeX(i);
      final y1 = _nodeY(i);
      final x2 = _nodeX(i + 1);
      final y2 = _nodeY(i + 1);

      final done = lessonStatuses[i] == LessonStatus.completed;
      final nextAvailable = lessonStatuses[i + 1] != LessonStatus.locked;
      final bothLocked = !done && !nextAvailable;

      Color lineColor;
      if (done && nextAvailable) {
        lineColor = AppColors.nodeCompleted;
      } else if (done) {
        lineColor = AppColors.nodeCompleted.withValues(alpha: 0.6);
      } else {
        lineColor = isDark ? const Color(0xFF3A4A54) : const Color(0xFFD1D5DB);
      }

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = TrailConstants.pathStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Smooth S-curve between nodes
      final midY = (y1 + y2) / 2;
      final path = Path()
        ..moveTo(x1, y1 + TrailConstants.nodeSize * 0.55)
        ..cubicTo(
          x1, midY,
          x2, midY,
          x2, y2 - TrailConstants.nodeSize * 0.55,
        );

      if (bothLocked) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final end = (d + TrailConstants.dashLength).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, end), paint);
        d += TrailConstants.dashLength + TrailConstants.gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPathPainter old) =>
      lessonCount != old.lessonCount ||
      amplitude != old.amplitude ||
      lessonStatuses != old.lessonStatuses ||
      isDark != old.isDark;
}

// ─── Duolingo 3D Button ──────────────────────────────────────────────────────

class _Duo3DButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Duo3DButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_Duo3DButton> createState() => _Duo3DButtonState();
}

class _Duo3DButtonState extends State<_Duo3DButton> {
  bool _pressed = false;

  Color get _shadowColor {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

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
        width: double.infinity,
        padding: EdgeInsets.only(bottom: _pressed ? 0 : 4),
        decoration: BoxDecoration(
          color: _shadowColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/dove_icon.png',
              width: 72, height: 72,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Não foi possível carregar',
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            JFButton(label: 'Tentar novamente', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
