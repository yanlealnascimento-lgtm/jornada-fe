import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MedalModel {
  final String key;
  final String name;
  final String shortName;
  final String description;
  final String emoji;
  final Color bgColor;
  final Color borderColor;
  final bool isEarned;
  final DateTime? earnedAt;

  const MedalModel({
    required this.key,
    required this.name,
    required this.shortName,
    required this.description,
    required this.emoji,
    required this.bgColor,
    required this.borderColor,
    required this.isEarned,
    this.earnedAt,
  });
}

class MedalsSection extends StatelessWidget {
  final List<MedalModel> medals;
  final int earned;
  final int total;
  final VoidCallback onSeeAll;

  const MedalsSection({
    super.key,
    required this.medals,
    required this.earned,
    required this.total,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MEDALHAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF),
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Row(
                  children: [
                    Text('Ver todas',
                        style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2))),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Color(0xFF4A90E2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: medals.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final medal = medals[i];
              return GestureDetector(
                onTap: () => _showMedalSheet(context, medal),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: medal.isEarned
                            ? medal.bgColor
                            : (isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6)),
                        border: Border.all(
                          color: medal.isEarned
                              ? medal.borderColor
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                          width: 2,
                        ),
                      ),
                      child: medal.isEarned
                          ? Center(child: Text(medal.emoji, style: const TextStyle(fontSize: 28)))
                          : Icon(Icons.lock_rounded,
                              color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFFD1D5DB),
                              size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medal.shortName,
                      style: TextStyle(
                        fontSize: 9,
                        color: medal.isEarned
                            ? (isDark ? AppColors.darkTextSecond : const Color(0xFF4B5563))
                            : (isDark ? const Color(0xFF5A7A8A) : const Color(0xFFD1D5DB)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMedalSheet(BuildContext context, MedalModel medal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal.isEarned
                      ? medal.bgColor
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6)),
                  border: Border.all(
                    color: medal.isEarned
                        ? medal.borderColor
                        : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                    width: 3,
                  ),
                ),
                child: medal.isEarned
                    ? Center(child: Text(medal.emoji, style: const TextStyle(fontSize: 40)))
                    : Icon(Icons.lock_rounded,
                        color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFFD1D5DB),
                        size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                medal.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                medal.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                  color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
              ),
              if (medal.isEarned && medal.earnedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Conquistada em ${medal.earnedAt!.day}/${medal.earnedAt!.month}/${medal.earnedAt!.year}',
                  style: TextStyle(fontSize: 12,
                    color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
