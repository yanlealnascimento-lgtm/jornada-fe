import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/trail_constants.dart';

/// Badge that shows the gem emoji + crystal count.
/// Blue when > 0, grey when 0. Dark mode aware.
class CrystalBadge extends StatelessWidget {
  final int count;

  const CrystalBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = count > 0 ? AppColors.mana : (isDark ? AppColors.darkTextSecond : AppColors.textHint);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\u{1F48E}',
          style: TextStyle(
            fontSize: TrailConstants.statEmojiSize,
            color: count > 0 ? null : (isDark ? AppColors.darkTextSecond : AppColors.textHint),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: TrailConstants.statFontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
