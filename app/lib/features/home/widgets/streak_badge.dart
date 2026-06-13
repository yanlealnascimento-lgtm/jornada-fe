import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/trail_constants.dart';

/// Badge that shows the fire emoji + streak count.
/// Orange when completed today, grey when not.
/// Pulses briefly when the streak increments.
class StreakBadge extends StatefulWidget {
  final int count;
  final bool completedToday;

  const StreakBadge({
    super.key,
    required this.count,
    required this.completedToday,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > _previousCount) {
      _pulseController.forward(from: 0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.completedToday ? AppColors.streak : (isDark ? AppColors.darkTextSecond : AppColors.textHint);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\u{1F525}',
              style: TextStyle(
                fontSize: TrailConstants.statEmojiSize,
                color: widget.completedToday ? null : (isDark ? AppColors.darkTextSecond : AppColors.textHint),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.count}',
              style: TextStyle(
                fontSize: TrailConstants.statFontSize,
                fontWeight: FontWeight.w800,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
