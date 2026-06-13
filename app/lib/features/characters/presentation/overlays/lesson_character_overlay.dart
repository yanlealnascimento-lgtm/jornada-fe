import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/character_widget.dart';

/// A semi‑transparent overlay that shows the lesson's companion character in
/// the bottom‑left corner of the screen.
///
/// Tapping the character dismisses the overlay by calling [onDismiss].
class LessonCharacterOverlay extends StatelessWidget {
  const LessonCharacterOverlay({
    super.key,
    required this.characterId,
    required this.onDismiss,
  });

  final String characterId;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      bottom: 24,
      child: GestureDetector(
        onTap: onDismiss,
        child: Opacity(
          opacity: 0.92,
          child: CharacterWidget(
            characterId: characterId,
            avatarSize: 140,
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideX(begin: -0.5, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}
