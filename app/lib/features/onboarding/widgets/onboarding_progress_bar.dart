import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingProgressBar extends StatelessWidget {
  /// Zero-indexed current step.
  final int current;
  final int total;
  final VoidCallback? onBack;

  const OnboardingProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (current + 1) / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFDDE3EA),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
