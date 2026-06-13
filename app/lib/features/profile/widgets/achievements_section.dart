import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/gamification_model.dart';

class AchievementsSection extends StatelessWidget {
  final List<AchievementModel> recent;
  final int total;
  final VoidCallback onSeeAll;

  const AchievementsSection({
    super.key,
    required this.recent,
    required this.total,
    required this.onSeeAll,
  });

  static const Map<String, Color> _rarityColors = {
    'common': Color(0xFF6B7280),
    'uncommon': Color(0xFF22C55E),
    'rare': Color(0xFF3B82F6),
    'epic': Color(0xFF8B5CF6),
    'legendary': Color(0xFFD4A017),
  };

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
                'CONQUISTAS  ($total)',
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
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final a = recent[i];
              final rarityColor = _rarityColors[a.rarity] ?? const Color(0xFF6B7280);
              final isNew = a.unlockedAt != null &&
                  DateTime.now().difference(a.unlockedAt!).inHours < 24;
              final emoji = _emojiForRarity(a.rarity);

              return GestureDetector(
                onTap: () => _showAchievementSheet(context, a),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? rarityColor.withValues(alpha: 0.15)
                            : rarityColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? rarityColor.withValues(alpha: 0.4)
                              : rarityColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 6),
                          Text(
                            a.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '+PF',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFD4A017),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNew)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NOVA',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
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

  String _emojiForRarity(String rarity) {
    switch (rarity) {
      case 'common': return '\u{1F3C5}';
      case 'uncommon': return '\u{2B50}';
      case 'rare': return '\u{1F48E}';
      case 'epic': return '\u{1F451}';
      case 'legendary': return '\u{1F31F}';
      default: return '\u{1F3C5}';
    }
  }

  void _showAchievementSheet(BuildContext context, AchievementModel a) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rarityColor = _rarityColors[a.rarity] ?? const Color(0xFF6B7280);

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
              Text(_emojiForRarity(a.rarity), style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                a.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                a.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                  color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
              ),
              if (a.verseReference != null) ...[
                const SizedBox(height: 8),
                Text(
                  a.verseReference!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: rarityColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3510) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${a.pfReward} PF',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4A017),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
