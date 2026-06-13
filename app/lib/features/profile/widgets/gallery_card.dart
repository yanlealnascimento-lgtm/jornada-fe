import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/gamification_model.dart';

class GalleryBiblicaCard extends StatelessWidget {
  final List<CharacterModel> unlockedCharacters;
  final int totalCharacters;
  final int unlockedCount;
  final VoidCallback onTap;

  const GalleryBiblicaCard({
    super.key,
    required this.unlockedCharacters,
    required this.totalCharacters,
    required this.unlockedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('\u2694\uFE0F', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galeria Biblica',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    'Conheca os personagens da Biblia',
                    style: TextStyle(fontSize: 12,
                      color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  if (unlockedCharacters.isNotEmpty)
                    Row(
                      children: [
                        SizedBox(
                          width: (unlockedCharacters.length * 22.0) + 4,
                          height: 28,
                          child: Stack(
                            children: unlockedCharacters
                                .asMap()
                                .entries
                                .map(
                                  (e) => Positioned(
                                    left: e.key * 18.0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppColors.darkSurface : Colors.white,
                                          width: 2,
                                        ),
                                        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEBF5FF),
                                      ),
                                      child: ClipOval(
                                        child: e.value.spriteUrl != null
                                            ? Image.network(
                                                e.value.spriteUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _charInitial(e.value.name),
                                              )
                                            : _charInitial(e.value.name),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$unlockedCount/$totalCharacters encontrados',
                          style: TextStyle(fontSize: 11,
                            color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _charInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A90E2),
        ),
      ),
    );
  }
}
