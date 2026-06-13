import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatsCardsRow extends StatelessWidget {
  final int streakDays;
  final int lessonsCompleted;
  final int achievementsCount;
  final VoidCallback? onStreakTap;
  final VoidCallback? onLessonsTap;
  final VoidCallback? onAchievementsTap;

  const StatsCardsRow({
    super.key,
    required this.streakDays,
    required this.lessonsCompleted,
    required this.achievementsCount,
    this.onStreakTap,
    this.onLessonsTap,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              emoji: '\u{1F525}',
              value: streakDays,
              label: 'Streak',
              color: isDark ? const Color(0xFF3D2A0F) : const Color(0xFFFFF7ED),
              borderColor: isDark ? const Color(0xFF6B4C1E) : const Color(0xFFFED7AA),
              isDark: isDark,
              onTap: onStreakTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              emoji: '\u{1F4D6}',
              value: lessonsCompleted,
              label: 'Licoes',
              color: isDark ? const Color(0xFF0F2A3F) : const Color(0xFFEFF6FF),
              borderColor: isDark ? const Color(0xFF1E4A6B) : const Color(0xFFBFDBFE),
              isDark: isDark,
              onTap: onLessonsTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              emoji: '\u{1F3C6}',
              value: achievementsCount,
              label: 'Conquistas',
              color: isDark ? const Color(0xFF3D3510) : const Color(0xFFFEF3C7),
              borderColor: isDark ? const Color(0xFF6B5D1E) : const Color(0xFFFDE68A),
              isDark: isDark,
              onTap: onAchievementsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final int value;
  final String label;
  final Color color;
  final Color borderColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            _AnimatedCount(
              value: value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 12,
                  color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280),
                )),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _AnimatedCount({required this.value, required this.style});

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = IntTween(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _anim = IntTween(begin: oldWidget.value, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text('${_anim.value}', style: widget.style),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
