import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/character_model.dart';
import '../domain/models/character_state.dart';
import '../domain/models/dialogue_event.dart';

/// Maps a [DialogueEvent.type] string to the appropriate animation state.
CharacterAnimationState _animationForEventType(String type) {
  switch (type) {
    case 'correct':
      return CharacterAnimationState.happy;
    case 'wrong':
      return CharacterAnimationState.sad;
    case 'greeting':
      return CharacterAnimationState.greeting;
    case 'lesson_start':
      return CharacterAnimationState.talking;
    case 'lesson_complete':
      return CharacterAnimationState.celebrating;
    case 'streak_warning':
      return CharacterAnimationState.thinking;
    case 'streak_broken':
      return CharacterAnimationState.sad;
    case 'level_up':
      return CharacterAnimationState.celebrating;
    case 'narrating':
      return CharacterAnimationState.narrating;
    case 'farewell':
      return CharacterAnimationState.farewell;
    case 'surprised':
      return CharacterAnimationState.surprised;
    default:
      return CharacterAnimationState.talking;
  }
}

/// Computes a speech duration based on text length.
/// 50 ms per character, clamped between 2 s and 6 s.
Duration _speechDurationFor(String text) {
  final ms = text.length * 50;
  final clamped = ms.clamp(2000, 6000);
  return Duration(milliseconds: clamped);
}

class CharacterDisplayNotifier extends StateNotifier<CharacterDisplayState> {
  CharacterDisplayNotifier(String characterId)
      : super(
          CharacterDisplayState(
            characterId: characterId,
            animation: CharacterAnimationState.idle,
          ),
        );

  /// Reacts to a lesson / app event by showing the appropriate animation
  /// and dialogue, then returning to idle after the speech duration.
  Future<void> reactToLessonEvent(
    DialogueEvent event,
    CharacterModel character,
  ) async {
    final animation = _animationForEventType(event.type);
    final text = event.text ?? character.getDialogue(event.type);

    if (text == null) return;

    final duration = _speechDurationFor(text);

    state = state.copyWith(
      animation: animation,
      dialogueText: text,
      isSpeechBubbleVisible: true,
      speechDuration: duration,
    );

    await Future<void>.delayed(duration);

    // Only return to idle if the state hasn't been changed by another event
    // while we were waiting.
    if (state.dialogueText == text) {
      state = state.copyWith(
        animation: CharacterAnimationState.idle,
        dialogueText: null,
        isSpeechBubbleVisible: false,
      );
    }
  }

  /// Convenience helper to show a greeting dialogue.
  Future<void> showGreeting(CharacterModel character) {
    return reactToLessonEvent(
      const DialogueEvent(type: 'greeting'),
      character,
    );
  }

  /// Immediately hides the speech bubble and returns to idle.
  void dismiss() {
    state = state.copyWith(
      animation: CharacterAnimationState.idle,
      dialogueText: null,
      isSpeechBubbleVisible: false,
    );
  }
}

/// Provider family keyed by characterId.
/// Usage: `ref.watch(characterControllerProvider('char_123'))`
final characterControllerProvider = StateNotifierProvider.family<
    CharacterDisplayNotifier, CharacterDisplayState, String>(
  (ref, characterId) => CharacterDisplayNotifier(characterId),
);
