import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/study_provider.dart';
import '../../../shared/models/bible_study_model.dart';

class StudyListScreen extends ConsumerStatefulWidget {
  const StudyListScreen({super.key});

  @override
  ConsumerState<StudyListScreen> createState() => _StudyListScreenState();
}

class _StudyListScreenState extends ConsumerState<StudyListScreen> {
  String? _selectedCategory;

  static const _categories = [
    null,
    'faith',
    'prayer',
    'wisdom',
    'love',
    'courage',
    'grace',
    'hope',
  ];

  static const _categoryLabels = {
    null: 'Todos',
    'faith': 'Fe',
    'prayer': 'Oracao',
    'wisdom': 'Sabedoria',
    'love': 'Amor',
    'courage': 'Coragem',
    'grace': 'Graca',
    'hope': 'Esperanca',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = StudyFilter(category: _selectedCategory);
    final studiesAsync = ref.watch(studiesProvider(filter));
    final featuredAsync = ref.watch(featuredStudiesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Estudos Biblicos', style: AppTypography.displayMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : null,
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Aprofunde-se na Palavra de Deus',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecond : null,
                ),
              ),
            ),

            // Category filter chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.navy
                            : (isDark ? AppColors.darkSurface : AppColors.surface),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.navy
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categoryLabels[cat] ?? 'Todos',
                          style: AppTypography.label.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecond : AppColors.textSecondary),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: studiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Erro ao carregar estudos',
                          style: TextStyle(fontSize: 16,
                            color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(studiesProvider(filter)),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
                data: (studies) {
                  if (studies.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('\u{1F4D6}', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum estudo disponivel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.navy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Novos estudos serao adicionados em breve.',
                              style: TextStyle(fontSize: 14,
                                color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      featuredAsync.when(
                        loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                        data: (featured) {
                          if (featured.isEmpty || _selectedCategory != null) {
                            return const SliverToBoxAdapter(child: SizedBox.shrink());
                          }
                          return SliverToBoxAdapter(
                            child: _FeaturedCarousel(studies: featured),
                          );
                        },
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _StudyCard(study: studies[index]),
                            childCount: studies.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Carousel ─────────────────────────────────────────────────────────

class _FeaturedCarousel extends StatelessWidget {
  final List<BibleStudyModel> studies;
  const _FeaturedCarousel({required this.studies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: studies.length,
        itemBuilder: (context, index) {
          final study = studies[index];
          return GestureDetector(
            onTap: () => context.push('/study/${study.slug}'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2E4A), Color(0xFF2C5F8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Em Destaque',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (study.isPremium)
                          const Text('\u{1F48E}', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      study.title,
                      style: AppTypography.headingLarge.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${study.totalLessons} licoes  \u{2022}  ${study.estimatedMinutes.round()} min',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Study Card ────────────────────────────────────────────────────────────────

class _StudyCard extends StatelessWidget {
  final BibleStudyModel study;
  const _StudyCard({required this.study});

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

  Color _difficultyBg(bool isDark) {
    switch (study.difficulty) {
      case 'intermediate':
        return isDark ? const Color(0xFF3D3510) : const Color(0xFFFEF3C7);
      case 'advanced':
        return isDark ? const Color(0xFF3D1010) : const Color(0xFFFEE2E2);
      default:
        return isDark ? const Color(0xFF0F3D1E) : const Color(0xFFDCFCE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/study/${study.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _difficultyBg(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      study.difficultyLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _difficultyColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (study.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3D3510) : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: const Text('\u{1F48E}', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),

              const Spacer(),

              if (study.character != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: study.character!.colorHex != null
                        ? Color(int.parse(study.character!.colorHex!.replaceFirst('#', '0xFF')))
                            .withValues(alpha: 0.15)
                        : (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      study.character!.name.isNotEmpty
                          ? study.character!.name[0].toUpperCase()
                          : '\u{2728}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: study.character!.colorHex != null
                            ? Color(int.parse(study.character!.colorHex!.replaceFirst('#', '0xFF')))
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              if (study.character != null) const SizedBox(height: 8),

              Text(
                study.title,
                style: AppTypography.label.copyWith(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Text(
                '${study.totalLessons} licoes \u{2022} ${study.estimatedMinutes.round()} min',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecond : null,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
