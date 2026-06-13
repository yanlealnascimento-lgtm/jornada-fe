import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DiaryEntryPreview {
  final String studyTitle;
  final String questionText;
  final String answerPreview;
  final String formattedDate;

  const DiaryEntryPreview({
    required this.studyTitle,
    required this.questionText,
    required this.answerPreview,
    required this.formattedDate,
  });
}

class DiarySection extends StatelessWidget {
  final List<DiaryEntryPreview> entries;
  final bool isPremium;

  const DiarySection({
    super.key,
    required this.entries,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isPremium) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3D3510) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF6B5D1E) : const Color(0xFFFDE68A),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('\u{1F4D3}', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diario Espiritual',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    'Salve suas reflexoes biblicas',
                    style: TextStyle(fontSize: 12,
                      color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.push('/premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Desbloquear com JF Plus',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIARIO ESPIRITUAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile/diary'),
                child: const Row(
                  children: [
                    Text('Ver tudo',
                        style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2))),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Color(0xFF4A90E2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...entries.take(2).map(
              (e) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3510) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF6B5D1E) : const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.studyTitle,
                      style: TextStyle(fontSize: 10,
                        color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.questionText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.answerPreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.formattedDate,
                      style: TextStyle(fontSize: 9,
                        color: isDark ? const Color(0xFF4A5A64) : const Color(0xFFD1D5DB)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
