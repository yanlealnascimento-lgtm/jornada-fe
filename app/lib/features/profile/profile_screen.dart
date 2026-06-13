import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/gamification_provider.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/stats_cards_row.dart';
import 'widgets/friend_streaks_section.dart';
import 'widgets/gallery_card.dart';
import 'widgets/medals_section.dart';
import 'widgets/achievements_section.dart';
import 'widgets/studies_section.dart';
import 'widgets/diary_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final charactersAsync = ref.watch(charactersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: userAsync.whenOrNull(
          data: (user) => Text(
            user?.name ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.navy,
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F614}', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('Nao foi possivel carregar o perfil',
                    style: AppTypography.headingMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Verifique sua conexao e tente novamente.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecond : null,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(child: Text('Entre na sua conta',
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null),
            ));
          }

          final unlockedAchievements = achievementsAsync.valueOrNull
                  ?.where((a) => a.isUnlocked)
                  .toList() ??
              [];

          final allCharacters = charactersAsync.valueOrNull ?? [];
          final unlockedChars =
              allCharacters.where((c) => c.isUnlocked).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(achievementsProvider);
              ref.invalidate(charactersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SizedBox(height: 16),
                _HeroSection(
                  user: user,
                  onAvatarChanged: (String path) {
                    ref.read(currentUserProvider.notifier).updateLocally(
                      user.copyWith(avatarUrl: path),
                    );
                  },
                ),
                const SizedBox(height: 20),
                StatsCardsRow(
                  streakDays: user.streakCurrent,
                  lessonsCompleted: user.pfTotal ~/ 15,
                  achievementsCount: unlockedAchievements.length,
                  onStreakTap: () => _showComingSoon(context, 'Streak'),
                  onLessonsTap: () => _showComingSoon(context, 'Licoes'),
                  onAchievementsTap: () =>
                      _showComingSoon(context, 'Conquistas'),
                ),
                const SizedBox(height: 16),
                // Adicionar Amigos button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showComingSoon(context, 'Adicionar amigos'),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Adicionar Amigos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FriendStreaksSection(
                  friends: const [],
                  onAddFriend: () =>
                      _showComingSoon(context, 'Adicionar amigos'),
                ),
                const SizedBox(height: 24),
                GalleryBiblicaCard(
                  unlockedCharacters: unlockedChars.take(3).toList(),
                  totalCharacters: allCharacters.length,
                  unlockedCount: unlockedChars.length,
                  onTap: () => context.push('/profile/characters'),
                ),
                const SizedBox(height: 24),
                MedalsSection(
                  medals: const [],
                  earned: 0,
                  total: 0,
                  onSeeAll: () => _showComingSoon(context, 'Medalhas'),
                ),
                const SizedBox(height: 24),
                AchievementsSection(
                  recent: achievementsAsync.valueOrNull
                          ?.where((a) => a.isUnlocked)
                          .toList() ??
                      [],
                  total: unlockedAchievements.length,
                  onSeeAll: () => _showComingSoon(context, 'Conquistas'),
                ),
                const SizedBox(height: 24),
                StudiesSection(
                  inProgress: const [],
                  completed: const [],
                  totalCompleted: 0,
                  onSeeAll: () => _showComingSoon(context, 'Estudos'),
                ),
                const SizedBox(height: 24),
                const DiarySection(entries: [], isPremium: false),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Em breve!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final dynamic user;
  final ValueChanged<String>? onAvatarChanged;
  const _HeroSection({required this.user, this.onAvatarChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Avatar
          ProfileAvatar(
            imageUrl: user.avatarUrl,
            displayName: user.name,
            leagueTier: user.leagueTier ?? 'bronze',
            isEditable: true,
            onCameraTap: () => _showAvatarPicker(context),
          ),
          const SizedBox(width: 16),
          // Right column: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.name.toLowerCase().replaceAll(' ', '')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nivel ${user.level} \u00b7 ${_levelName(user.level)}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showLevelDetail(context, user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: user.pfToNextLevel > 0
                              ? (user.pfTotal % user.pfToNextLevel) / user.pfToNextLevel.toDouble()
                              : 0.0,
                          backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                          color: AppColors.xpColor,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.pfTotal % user.pfToNextLevel}/${user.pfToNextLevel} PF para nivel ${user.level + 1}',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecond : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _levelName(int level) {
    if (level <= 2) return 'Aprendiz';
    if (level <= 5) return 'Estudante';
    if (level <= 10) return 'Devoto';
    if (level <= 20) return 'Sabio';
    if (level <= 35) return 'Mestre';
    return 'Iluminado';
  }

  Future<void> _pickAndSaveAvatar(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Copia para diretório persistente do app (o cache pode ser limpo)
    final appDir = Directory('${File(picked.path).parent.parent.path}/app_flutter');
    if (!appDir.existsSync()) appDir.createSync(recursive: true);
    final savedPath = '${appDir.path}/avatar_profile.jpg';
    await File(picked.path).copy(savedPath);

    onAvatarChanged?.call(savedPath);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada!')),
      );
    }
  }

  void _showAvatarPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto de Perfil',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4A90E2)),
              ),
              title: Text('Tirar foto', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveAvatar(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4A90E2)),
              ),
              title: Text('Escolher da galeria', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveAvatar(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF3F1515) : Colors.red.shade50,
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: Text('Remover foto',
                  style: TextStyle(color: isDark ? const Color(0xFFFF6B6B) : Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onAvatarChanged?.call('');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLevelDetail(BuildContext context, dynamic user) {
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
              Text(
                'Nivel ${user.level}',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                _levelName(user.level),
                style: const TextStyle(fontSize: 16, color: Color(0xFF4A90E2), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: user.pfToNextLevel > 0
                    ? (user.pfTotal % user.pfToNextLevel) / user.pfToNextLevel.toDouble()
                    : 0.0,
                backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                color: const Color(0xFFF59E0B),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text(
                '${user.pfTotal % user.pfToNextLevel}/${user.pfToNextLevel} PF para nivel ${user.level + 1}',
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ${user.pfTotal} Pontos de Fé',
                style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF5A7A8A) : const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
