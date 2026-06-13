import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/models/character_model.dart';
import '../../domain/models/character_state.dart';

/// Animated circular avatar for a [CharacterModel].
///
/// Renders the character's `spriteUrl` as a [NetworkImage] inside a bordered
/// circle. When no sprite is available it falls back to the first letter of the
/// character's name plus a small emoji.
///
/// The widget continuously animates according to the current
/// [CharacterAnimationState] using `flutter_animate`.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    required this.animationState,
    this.size = 120,
  });

  final CharacterModel character;
  final CharacterAnimationState animationState;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = character.color;
    final hasSprite = character.spriteUrl.isNotEmpty;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          // Subtle glow ring in the character's color.
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: size * 0.2,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: hasSprite
            ? Image.network(
                character.spriteUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(color),
              )
            : _fallback(color),
      ),
    );

    // Apply animation based on current state.
    avatar = _applyAnimation(avatar);

    return avatar;
  }

  // ----- Fallback when no sprite is available -----

  Widget _fallback(Color color) {
    final letter =
        character.name.isNotEmpty ? character.name[0].toUpperCase() : '?';
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        '$letter ✨',
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ----- Animation helpers -----

  Widget _applyAnimation(Widget child) {
    switch (animationState) {
      case CharacterAnimationState.idle:
        // Subtle breathing / scale pulse.
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 1800.ms)
            .then()
            .scaleXY(begin: 1.04, end: 1.0, duration: 1800.ms);

      case CharacterAnimationState.happy:
      case CharacterAnimationState.greeting:
        // Gentle bounce.
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -10, duration: 400.ms, curve: Curves.easeOut)
            .then()
            .moveY(begin: -10, end: 0, duration: 400.ms, curve: Curves.easeIn);

      case CharacterAnimationState.sad:
      case CharacterAnimationState.farewell:
        // Slight droop downward.
        return child
            .animate()
            .moveY(begin: 0, end: 6, duration: 600.ms, curve: Curves.easeOut)
            .scaleXY(begin: 1.0, end: 0.95, duration: 600.ms);

      case CharacterAnimationState.celebrating:
        // Jump + subtle rotation.
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -18, duration: 350.ms, curve: Curves.easeOut)
            .rotate(begin: 0, end: 0.03, duration: 350.ms)
            .then()
            .moveY(begin: -18, end: 0, duration: 350.ms, curve: Curves.easeIn)
            .rotate(begin: 0.03, end: 0, duration: 350.ms);

      case CharacterAnimationState.surprised:
        // Quick scale pop.
        return child
            .animate()
            .scaleXY(begin: 1.0, end: 1.2, duration: 200.ms, curve: Curves.easeOut)
            .then()
            .scaleXY(begin: 1.2, end: 1.0, duration: 300.ms, curve: Curves.elasticOut);

      case CharacterAnimationState.thinking:
      case CharacterAnimationState.narrating:
        // Slow tilt side to side.
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(begin: 0, end: 0.04, duration: 1200.ms, curve: Curves.easeInOut)
            .then()
            .rotate(begin: 0.04, end: -0.04, duration: 1200.ms, curve: Curves.easeInOut);

      case CharacterAnimationState.talking:
      case CharacterAnimationState.walking:
        // Small rapid nod.
        return child
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 300.ms, curve: Curves.easeInOut);
    }
  }
}
