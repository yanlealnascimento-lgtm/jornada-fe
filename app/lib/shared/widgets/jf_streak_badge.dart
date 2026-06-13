import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum StreakBadgeSize { small, large }

class JFStreakBadge extends StatelessWidget {
  final int streakCount;
  final StreakBadgeSize size;

  const JFStreakBadge({
    super.key,
    required this.streakCount,
    this.size = StreakBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    if (size == StreakBadgeSize.small) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: size == StreakBadgeSize.small ? 18 : 32)),
          const SizedBox(width: 2),
          Text(
            '$streakCount',
            style: AppTypography.streakNumber.copyWith(
              fontSize: size == StreakBadgeSize.small ? 17 : 28,
            ),
          ),
        ],
      );
    }

    // Large version
    return Column(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 4),
        Text(
          '$streakCount',
          style: AppTypography.displayLarge.copyWith(color: AppColors.streakColor),
        ),
        Text(
          streakCount == 1 ? 'dia seguido' : 'dias seguidos',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
