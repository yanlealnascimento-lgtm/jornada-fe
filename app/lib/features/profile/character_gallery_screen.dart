import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/gamification_provider.dart';
import '../../shared/models/gamification_model.dart';

class CharacterGalleryScreen extends ConsumerWidget {
  const CharacterGalleryScreen({super.key});

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'mascot': return AppColors.gold;
      case 'common': return AppColors.correct;
      case 'uncommon': return AppColors.manaColor;
      case 'rare': return AppColors.sapphire;
      case 'epic': return Colors.purple;
      case 'legendary': return AppColors.goldLeague;
      default: return AppColors.border;
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity) {
      case 'mascot': return 'Mascote';
      case 'common': return 'Comum';
      case 'uncommon': return 'Incomum';
      case 'rare': return 'Raro';
      case 'epic': return 'Épico';
      case 'legendary': return 'Lendário';
      default: return rarity;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final charactersAsync = ref.watch(charactersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Galeria Bíblica'),
        centerTitle: true,
      ),
      body: charactersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null))),
        data: (characters) {
          final unlocked = characters.where((c) => c.isUnlocked).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$unlocked/${characters.length} personagens encontrados',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final char = characters[index];
                    return GestureDetector(
                      onTap: () => _showCharacterDetail(context, char),
                      child: _CharacterCard(
                        character: char,
                        rarityColor: _rarityColor(char.rarity),
                        rarityLabel: _rarityLabel(char.rarity),
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCharacterDetail(BuildContext context, CharacterModel character) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CharacterDetailSheet(character: character),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final Color rarityColor;
  final String rarityLabel;
  final bool isDark;

  const _CharacterCard({
    required this.character,
    required this.rarityColor,
    required this.rarityLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !character.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark ? AppColors.darkSurface : AppColors.surface)
            : (isDark ? AppColors.darkBackground : AppColors.background),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? (isDark ? AppColors.darkBorder : AppColors.border)
              : rarityColor,
          width: isLocked ? 1.5 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLocked
                  ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.3))
                  : rarityColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ColorFiltered(
                colorFilter: isLocked
                    ? const ColorFilter.matrix([
                        0.2, 0.2, 0.2, 0, 0,
                        0.2, 0.2, 0.2, 0, 0,
                        0.2, 0.2, 0.2, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: Text(
                  isLocked ? '❓' : '⚔️',
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLocked ? '???' : character.name,
            style: AppTypography.label.copyWith(
              color: isLocked
                  ? (isDark ? const Color(0xFF5A7A8A) : AppColors.textHint)
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            isLocked ? '???' : character.title,
            style: AppTypography.caption.copyWith(
              color: isDark ? const Color(0xFF5A7A8A) : AppColors.textHint,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isLocked
                  ? (isDark ? AppColors.darkBorder : AppColors.border)
                  : rarityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLocked ? 'Misterioso' : rarityLabel,
              style: AppTypography.caption.copyWith(
                color: isLocked
                    ? (isDark ? const Color(0xFF5A7A8A) : AppColors.textHint)
                    : rarityColor,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterDetailSheet extends StatelessWidget {
  final CharacterModel character;

  const _CharacterDetailSheet({required this.character});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: character.isUnlocked
                  ? _UnlockedContent(character: character, isDark: isDark)
                  : _LockedContent(character: character, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedContent extends StatelessWidget {
  final CharacterModel character;
  final bool isDark;
  const _UnlockedContent({required this.character, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('⚔️', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 8),
        Text(character.name, style: AppTypography.displayMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        )),
        Text(character.title, style: AppTypography.bodyLarge.copyWith(
          color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
        )),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {},
          child: Text(character.biblicalReference, style: const TextStyle(color: AppColors.primary)),
        ),
        const SizedBox(height: 12),
        Text(character.story, style: AppTypography.bodyLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        )),
        const SizedBox(height: 20),
        if (character.dialogues.isNotEmpty) ...[
          Text('Palavras de ${character.name}:', style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          )),
          const SizedBox(height: 10),
          ...character.dialogues.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text('"$d"', style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextPrimary : null,
            )),
          )),
        ],
      ],
    );
  }
}

class _LockedContent extends StatelessWidget {
  final CharacterModel character;
  final bool isDark;
  const _LockedContent({required this.character, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🔒', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text('Personagem Bloqueado', style: AppTypography.headingLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        )),
        const SizedBox(height: 8),
        if (character.unlockCondition != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Para desbloquear:', style: AppTypography.label.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : null,
                      )),
                      Text(character.unlockCondition!, style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecond : null,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
