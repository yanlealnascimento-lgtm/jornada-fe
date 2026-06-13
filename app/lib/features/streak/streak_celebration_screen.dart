import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../gamification/services/streak_service.dart';

const _amber = Color(0xFFF5A623);
const _amberDark = Color(0xFFCC8800);

/// Duolingo-style streak celebration shown after completing a lesson.
/// Displays current streak count + day-of-week progress + CTA.
class StreakCelebrationScreen extends StatefulWidget {
  const StreakCelebrationScreen({super.key});

  @override
  State<StreakCelebrationScreen> createState() =>
      _StreakCelebrationScreenState();
}

class _StreakCelebrationScreenState extends State<StreakCelebrationScreen>
    with TickerProviderStateMixin {
  int _streak = 0;
  bool _loaded = false;

  late AnimationController _flameController;
  late Animation<double> _flameScale;
  late AnimationController _fadeController;
  late Animation<double> _fade;

  static const _weekDays = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flameScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.elasticOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final s = await StreakService.getCurrentStreak();
    if (!mounted) return;
    setState(() {
      _streak = s;
      _loaded = true;
    });
    _flameController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _flameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Returns a Set of weekday indices (0=Sunday..6=Saturday) that should be
  /// highlighted. Based on today's day and the current streak count.
  Set<int> _activeDays() {
    final today = DateTime.now().weekday % 7; // 0=Sunday, 1=Mon, ..., 6=Sat
    final active = <int>{};
    for (int i = 0; i < _streak && i < 7; i++) {
      final dayIdx = (today - i) % 7;
      active.add(dayIdx < 0 ? dayIdx + 7 : dayIdx);
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1B2E),
        body: SafeArea(
          child: Column(
            children: [
              // ── Amber header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Flame + streak number
                    AnimatedBuilder(
                      animation: _flameScale,
                      builder: (context, child) => Transform.scale(
                        scale: _flameScale.value,
                        child: child,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 96,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loaded ? '$_streak' : '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'dia(s) de ofensiva!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Days of week ──────────────────────────────────────────────
              if (_loaded)
                FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDaysRow(),
                  ),
                ),

              const Spacer(flex: 1),

              // ── Motivational text ─────────────────────────────────────────
              if (_loaded)
                FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _streak >= 7
                          ? 'Incrível! Você está em chamas. Continue sua jornada de fé!'
                          : 'Continue assim! Cada dia na Palavra fortalece sua fé.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB0B0C8),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 3),

              // ── CTA ────────────────────────────────────────────────────────
              if (_loaded)
                FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: Colors.white,
                          shadowColor: _amberDark,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'VOU ME DEDICAR',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysRow() {
    final activeDays = _activeDays();
    final today = DateTime.now().weekday % 7; // 0=Sun..6=Sat

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isActive = activeDays.contains(i);
        final isToday = i == today;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _amber : Colors.white12,
                border: isToday && !isActive
                    ? Border.all(color: _amber, width: 2)
                    : null,
              ),
              child: Center(
                child: isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _weekDays[i],
              style: TextStyle(
                color: isActive ? _amber : Colors.white38,
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}
