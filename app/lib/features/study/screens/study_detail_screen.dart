import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/study_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/bible_study_model.dart';
import '../../../shared/widgets/jf_button.dart';
import '../../../shared/widgets/jf_progress_bar.dart';

class StudyDetailScreen extends ConsumerWidget {
  final String slug;
  const StudyDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(studyDetailProvider(slug));
    final progressAsync = ref.watch(studyProgressProvider(slug));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F614}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('Erro ao carregar estudo', style: AppTypography.headingMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(studyDetailProvider(slug)),
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (study) {
        final progress = progressAsync.valueOrNull;
        return _StudyDetailBody(
          study: study,
          progress: progress,
          slug: slug,
        );
      },
    );
  }
}

class _StudyDetailBody extends ConsumerWidget {
  final BibleStudyModel study;
  final StudyProgress? progress;
  final String slug;

  const _StudyDetailBody({
    required this.study,
    required this.progress,
    required this.slug,
  });

  Color get _characterColor {
    if (study.character?.colorHex != null) {
      return Color(int.parse(study.character!.colorHex!.replaceFirst('#', '0xFF')));
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isPremiumUser = user?.leagueTier == 'diamond';
    final completedLessons = progress?.completedLessons ?? 0;
    final canContinue = !study.isPremium || isPremiumUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2E4A), Color(0xFF2C5F8A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Badges
                        Row(
                          children: [
                            _Badge(
                              label: study.difficultyLabel,
                              color: _difficultyColor,
                              bgColor: _difficultyColor.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: '${study.totalLessons} licoes',
                              color: Colors.white.withValues(alpha: 0.9),
                              bgColor: Colors.white.withValues(alpha: 0.15),
                            ),
                            if (study.isPremium) ...[
                              const SizedBox(width: 8),
                              _Badge(
                                label: '\u{1F48E} Premium',
                                color: AppColors.gold,
                                bgColor: AppColors.gold.withValues(alpha: 0.2),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        Text(
                          study.title,
                          style: AppTypography.displayMedium.copyWith(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${study.estimatedMinutes.round()} min \u{2022} +${study.pfReward} PF',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character card
                  if (study.character != null) ...[
                    _CharacterCard(character: study.character!, color: _characterColor),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  Text(study.description, style: AppTypography.bodyLarge),

                  // Verse
                  if (study.verseReference != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          if (study.verseText != null)
                            Text(
                              '"${study.verseText!}"',
                              style: AppTypography.bodyLarge.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 6),
                          Text(
                            study.verseReference!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Progress
                  const SizedBox(height: 24),
                  if (progress != null && progress!.totalLessons > 0) ...[
                    Row(
                      children: [
                        Text('Progresso', style: AppTypography.label),
                        const Spacer(),
                        Text(
                          '$completedLessons / ${study.totalLessons}',
                          style: AppTypography.label.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    JFProgressBar(
                      value: progress!.progressPercent,
                      height: 12,
                      color: AppColors.correct,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Lesson list header
                  Text('Licoes', style: AppTypography.headingMedium),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Lesson list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lesson = study.lessons[index];
                  final isCompleted = index < completedLessons;
                  final isCurrent = index == completedLessons;
                  final isLocked = index > completedLessons;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LessonTile(
                      index: index,
                      title: lesson.title,
                      verseRef: lesson.verseReference,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLocked: isLocked,
                      onTap: (isLocked || !canContinue)
                          ? null
                          : () {
                              context.push('/study/$slug/lesson/$index');
                            },
                    ),
                  );
                },
                childCount: study.lessons.length,
              ),
            ),
          ),

          // Premium paywall
          if (study.isPremium && !isPremiumUser)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _PremiumPaywall(),
              ),
            ),

          // Bottom action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: JFButton(
                label: completedLessons > 0 ? 'Continuar Estudo' : 'Comecar Estudo',
                onPressed: canContinue
                    ? () {
                        final nextLesson = completedLessons < study.totalLessons
                            ? completedLessons
                            : 0;
                        context.push('/study/$slug/lesson/$nextLesson');
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _difficultyColor {
    switch (study.difficulty) {
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

// ── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Character Card ───────────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final StudyCharacter character;
  final Color color;
  const _CharacterCard({required this.character, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                character.name.isNotEmpty ? character.name[0].toUpperCase() : '\u{2728}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: AppTypography.headingMedium.copyWith(color: color),
                ),
                if (character.bio != null)
                  Text(
                    character.bio!,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lesson Tile ──────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final int index;
  final String title;
  final String verseRef;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  const _LessonTile({
    required this.index,
    required this.title,
    required this.verseRef,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg;
    final Color iconColor;
    final IconData icon;

    if (isCompleted) {
      iconBg = AppColors.correct;
      iconColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      iconBg = AppColors.primary;
      iconColor = Colors.white;
      icon = Icons.play_arrow_rounded;
    } else {
      iconBg = AppColors.border;
      iconColor = AppColors.textHint;
      icon = Icons.lock_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licao ${index + 1}',
                    style: AppTypography.caption.copyWith(
                      color: isLocked ? AppColors.textHint : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: isLocked ? AppColors.textHint : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (verseRef.isNotEmpty)
                    Text(
                      verseRef,
                      style: AppTypography.caption.copyWith(
                        color: isLocked ? AppColors.textHint : AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isCurrent)
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Premium Paywall ──────────────────────────────────────────────────────────

class _PremiumPaywall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
      ),
      child: Column(
        children: [
          const Text('\u{1F48E}', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Conteudo Premium',
            style: AppTypography.headingMedium.copyWith(color: const Color(0xFF7B5800)),
          ),
          const SizedBox(height: 8),
          Text(
            'Este estudo e exclusivo para assinantes JourneyFaith Premium.',
            style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF9E6C00)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          JFButton(
            label: 'Desbloquear Premium',
            size: JFButtonSize.medium,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve: assinatura Premium')),
              );
            },
          ),
        ],
      ),
    );
  }
}
