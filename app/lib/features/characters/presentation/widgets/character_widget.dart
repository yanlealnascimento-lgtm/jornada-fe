import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/models/character_model.dart';
import '../../application/character_controller.dart';
import '../../domain/models/character_state.dart';
import '../../providers/character_provider.dart';
import 'character_avatar.dart';
import 'speech_bubble_widget.dart';

/// Composite widget that shows a [CharacterAvatar] together with an optional
/// [SpeechBubbleWidget] positioned above it.
///
/// It consumes the [characterControllerProvider] to drive animation state and
/// dialogue text, and [characterByIdProvider] to fetch the model.
class CharacterWidget extends ConsumerWidget {
  const CharacterWidget({
    super.key,
    required this.characterId,
    this.avatarSize = 120,
  });

  final String characterId;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayState = ref.watch(characterControllerProvider(characterId));
    final characterAsync = ref.watch(characterByIdProvider(characterId));

    return characterAsync.when(
      loading: () => SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (character) => _buildCharacter(character, displayState),
    );
  }

  Widget _buildCharacter(
    CharacterModel character,
    CharacterDisplayState displayState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Speech bubble (animated enter / exit) ──
        // TODO: reimplementar animação do personagem posteriormente
        // if (displayState.isSpeechBubbleVisible &&
        //     displayState.dialogueText != null)
        //   Padding(
        //     padding: const EdgeInsets.only(bottom: 8),
        //     child: SpeechBubbleWidget(
        //       text: displayState.dialogueText!,
        //       color: character.color,
        //     ),
        //   )
        //       .animate()
        //       .fadeIn(duration: 250.ms)
        //       .slideY(begin: 0.1, end: 0, duration: 250.ms),

        // ── Avatar ──
        CharacterAvatar(
          character: character,
          animationState: displayState.animation,
          size: avatarSize,
        ),
      ],
    );
  }
}
