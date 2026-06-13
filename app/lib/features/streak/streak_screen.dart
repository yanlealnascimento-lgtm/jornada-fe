import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../gamification/providers/gamification_providers.dart';
import '../gamification/services/streak_service.dart';

const _amber = Color(0xFFF5A623);
const _darkCard = Color(0xFF1E1E2E);

const _monthNamesPtBR = [
  'janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String _formatDatePtBR(DateTime date) {
  return '${date.day} de ${_monthNamesPtBR[date.month - 1]}';
}

String _formatMonthYearPtBR(DateTime date) {
  final name = _monthNamesPtBR[date.month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} ${date.year}';
}

class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _completedDates = {};

  static const _milestones = [3, 7, 14, 30, 50, 100];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCompletedDates();
  }

  Future<void> _loadCompletedDates() async {
    final lastDate = await StreakService.getLastCompletedDate();
    if (lastDate.isNotEmpty) {
      // Build a set of completed dates backwards from lastDate based on streak
      final streak = await StreakService.getCurrentStreak();
      final last = DateTime.parse(lastDate);
      final dates = <String>{};
      for (int i = 0; i < streak; i++) {
        final d = last.subtract(Duration(days: i));
        dates.add(d.toIso8601String().substring(0, 10));
      }
      if (mounted) {
        setState(() => _completedDates = dates);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _cardBg => _isDark ? _darkCard : AppColors.surface;
  Color get _textPrimary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _textSecondary =>
      _isDark ? AppColors.darkTextSecond : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPessoalTab(),
                _buildAmigosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _amber,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Ofensiva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
              tabs: const [
                Tab(text: 'PESSOAL'),
                Tab(text: 'AMIGOS'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PESSOAL TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPessoalTab() {
    final streakAsync = ref.watch(streakProvider);
    final completedAsync = ref.watch(completedTodayProvider);

    return streakAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (streak) {
        final completedToday = completedAsync.valueOrNull ?? false;
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(streak, completedToday),
              const SizedBox(height: 24),
              _buildCalendarSection(),
              const SizedBox(height: 24),
              _buildMilestonesSection(streak),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHeroSection(int streak, bool completedToday) {
    final nextMilestone =
        _milestones.firstWhere((m) => m > streak, orElse: () => streak + 50);
    final now = DateTime.now();
    final daysUntil = nextMilestone - streak;
    final targetDate = now.add(Duration(days: daysUntil));
    final dateStr = _formatDatePtBR(targetDate);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _amber,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            // Streak number + flame
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'dias de ofensiva!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.local_fire_department,
                  size: 80,
                  color: completedToday
                      ? Colors.white
                      : const Color(0x80FFFFFF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Next milestone card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Voce vai atingir a sua proxima meta de ofensiva de $nextMilestone dias em $dateStr!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calendar Section ──────────────────────────────────────────────────────
  Widget _buildCalendarSection() {
    final now = DateTime.now();
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun
    final monthName = _formatMonthYearPtBR(_calendarMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendario da ofensiva',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: _textPrimary),
                      onPressed: () {
                        setState(() {
                          _calendarMonth = DateTime(
                            month == 1 ? year - 1 : year,
                            month == 1 ? 12 : month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      monthName,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: _textPrimary),
                      onPressed: () {
                        setState(() {
                          _calendarMonth = DateTime(
                            month == 12 ? year + 1 : year,
                            month == 12 ? 1 : month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Weekday headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']
                      .map(
                        (d) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Day grid
                ..._buildCalendarWeeks(
                    year, month, daysInMonth, firstWeekday, now),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarWeeks(
    int year,
    int month,
    int daysInMonth,
    int firstWeekday,
    DateTime now,
  ) {
    final weeks = <Widget>[];
    // firstWeekday: 1=Monday, we want column 0=Monday
    int dayCounter = 1;
    int startCol = firstWeekday - 1; // 0-indexed

    // Number of rows needed
    final totalSlots = startCol + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();

    for (int row = 0; row < rowCount; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final idx = row * 7 + col;
        if (idx < startCol || dayCounter > daysInMonth) {
          cells.add(const SizedBox(width: 36, height: 36));
        } else {
          final day = dayCounter;
          dayCounter++;
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final isToday = now.year == year &&
              now.month == month &&
              now.day == day;
          final isCompleted = _completedDates.contains(dateStr);

          cells.add(
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? _amber : Colors.transparent,
                    border: isToday && !isCompleted
                        ? Border.all(color: _amber, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.white
                            : isToday
                                ? _amber
                                : _textPrimary,
                        fontSize: 13,
                        fontWeight: isToday || isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: cells,
          ),
        ),
      );
    }
    return weeks;
  }

  // ── Milestones Section ────────────────────────────────────────────────────
  Widget _buildMilestonesSection(int streak) {
    final nextIdx =
        _milestones.indexWhere((m) => m > streak);
    final nextMilestone = nextIdx >= 0 ? _milestones[nextIdx] : streak + 50;
    final prevMilestone = nextIdx > 0 ? _milestones[nextIdx - 1] : 0;
    final progress = (streak - prevMilestone) / (nextMilestone - prevMilestone);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metas de Ofensiva',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar to next milestone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: _amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Proxima meta: $nextMilestone dias',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor:
                        _isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_amber),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak / $nextMilestone dias',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Milestone chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _milestones.map((m) {
              final achieved = streak >= m;
              return Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: achieved
                      ? _amber
                      : (_isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                  border: !achieved
                      ? Border.all(
                          color: _isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      achieved ? Icons.local_fire_department : Icons.flag,
                      color: achieved
                          ? Colors.white
                          : _textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$m',
                      style: TextStyle(
                        color: achieved ? Colors.white : _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'dias',
                      style: TextStyle(
                        color: achieved
                            ? Colors.white70
                            : _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AMIGOS TAB
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAmigosTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0x1AF5A623),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 80,
                    color: _amber,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Acompanhe a ofensiva\ndos seus amigos!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantenham-se motivados juntos na jornada de fe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title + edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ofensivas dos amigos',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'EDITAR',
                    style: TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mock friends
            _buildFriendTile(
              name: 'Maria Silva',
              streak: 12,
              avatarColor: Colors.pink.shade200,
              initials: 'MS',
            ),
            _buildFriendTile(
              name: 'Joao Pedro',
              streak: 7,
              avatarColor: Colors.blue.shade200,
              initials: 'JP',
            ),
            _buildFriendTile(
              name: 'Ana Costa',
              streak: 0,
              avatarColor: Colors.green.shade200,
              initials: 'AC',
              isPending: true,
            ),
            // Empty invite slots
            _buildInviteSlot(),
            _buildInviteSlot(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile({
    required String name,
    required int streak,
    required Color avatarColor,
    required String initials,
    bool isPending = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (isPending)
            Text(
              'Convite pendente',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: _amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInviteSlot() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isDark ? Colors.white24 : Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.add,
                color: _textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '+ Convidar amigo',
              style: TextStyle(
                color: _amber,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
