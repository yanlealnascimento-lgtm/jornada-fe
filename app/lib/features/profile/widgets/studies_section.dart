import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class UserStudyProgressSummary {
  final String studyId;
  final String studyTitle;
  final String status;
  final int sectionsCompleted;
  final int durationMin;
  final int pfEarned;

  const UserStudyProgressSummary({
    required this.studyId,
    required this.studyTitle,
    required this.status,
    required this.sectionsCompleted,
    required this.durationMin,
    required this.pfEarned,
  });
}

class StudiesSection extends StatelessWidget {
  final List<UserStudyProgressSummary> inProgress;
  final List<UserStudyProgressSummary> completed;
  final int totalCompleted;
  final VoidCallback onSeeAll;

  const StudiesSection({
    super.key,
    required this.inProgress,
    required this.completed,
    required this.totalCompleted,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = [...inProgress, ...completed].take(3).toList();
    if (all.isEmpty) return _EmptyStudiesCard(isDark: isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTUDOS BIBLICOS ($totalCompleted concluidos)',
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
                    Text('Ver todos',
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
        ...all.map((s) => _StudyProgressCard(study: s, isDark: isDark)),
      ],
    );
  }
}

class _StudyProgressCard extends StatelessWidget {
  final UserStudyProgressSummary study;
  final bool isDark;

  const _StudyProgressCard({required this.study, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCompleted = study.status == 'completed';
    final progressPct = study.sectionsCompleted / 4.0;

    return GestureDetector(
      onTap: () => context.push('/studies/${study.studyId}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isDark ? const Color(0xFF0F3D1E) : const Color(0xFFDCFCE7))
                    : (isDark ? const Color(0xFF0F2A3F) : const Color(0xFFEFF6FF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isCompleted ? '\u2705' : '\u{1F4D6}',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    study.studyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isCompleted) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPct,
                        minHeight: 5,
                        backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF4A90E2)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${study.sectionsCompleted}/4 secoes \u00b7 ${study.durationMin} min',
                      style: TextStyle(fontSize: 10,
                        color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
                    ),
                  ] else ...[
                    Text(
                      'Concluido \u00b7 +${study.pfEarned} PF',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : (isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStudiesCard extends StatelessWidget {
  final bool isDark;
  const _EmptyStudiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/studies'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E4A6B) : const Color(0xFFBFDBFE),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('\u{1F4D6}', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estudos Biblicos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    'Mergulhe fundo em um tema biblico',
                    style: TextStyle(fontSize: 12,
                      color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
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
}
