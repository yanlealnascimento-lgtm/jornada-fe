import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/models/character_model.dart';
import '../../domain/models/character_state.dart';
import 'character_avatar.dart';
import 'speech_bubble_widget.dart';

/// A small character that appears on the trail / home screen next to the
/// current lesson node.
///
/// It shows a compact avatar (size 56) with a gentle idle animation and
/// periodically pops a small greeting speech bubble to draw attention.
class TrailCharacterWidget extends ConsumerStatefulWidget {
  const TrailCharacterWidget({
    super.key,
    required this.character,
    this.greetingInterval = const Duration(seconds: 12),
  });

  final CharacterModel character;

  /// How often the character shows a random greeting bubble.
  final Duration greetingInterval;

  @override
  ConsumerState<TrailCharacterWidget> createState() =>
      _TrailCharacterWidgetState();
}

class _TrailCharacterWidgetState extends ConsumerState<TrailCharacterWidget> {
  Timer? _greetingTimer;
  String? _greetingText;
  bool _showBubble = false;

  static const _size = 56.0;

  @override
  void initState() {
    super.initState();
    _scheduleGreeting();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _scheduleGreeting() {
    _greetingTimer = Timer.periodic(widget.greetingInterval, (_) {
      _showRandomGreeting();
    });
  }

  void _showRandomGreeting() {
    final text = widget.character.getDialogue('greeting');
    if (text == null || !mounted) return;

    setState(() {
      _greetingText = text;
      _showBubble = true;
    });

    // Auto‑hide after a few seconds.
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showBubble = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Small greeting bubble ──
        if (_showBubble && _greetingText != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: SpeechBubbleWidget(
              text: _greetingText!,
              color: widget.character.color,
            ),
          ),

        const SizedBox(height: 4),

        // ── Compact avatar with subtle attention bounce ──
        CharacterAvatar(
          character: widget.character,
          animationState: CharacterAnimationState.idle,
          size: _size,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -3,
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
