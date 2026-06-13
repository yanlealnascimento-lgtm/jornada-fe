import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'character_controller.dart';
import 'tts_service.dart';
import 'sound_effects_service.dart';
import '../domain/models/dialogue_event.dart';
import '../providers/character_provider.dart';

/// Provider that holds the active character ID for the current lesson.
///
/// Set this before navigating to the lesson screen so that the character
/// layer knows which character to animate / voice.
final activeCharacterIdProvider = StateProvider<String?>((ref) => null);

/// Stateless helper that lesson screens call to fire character events,
/// play sound effects, and trigger TTS.
///
/// All methods are static and require a [WidgetRef] so they can read
/// providers without holding any state themselves.
class LessonCharacterHelper {
  LessonCharacterHelper._(); // non-instantiable

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Call when the user answers correctly.
  static void onCorrectAnswer(WidgetRef ref) {
    _fireEvent(ref, 'correct');
    ref.read(soundEffectsServiceProvider).play(SoundEffect.correct);
  }

  /// Call when the user answers incorrectly.
  static void onWrongAnswer(WidgetRef ref) {
    _fireEvent(ref, 'wrong');
    ref.read(soundEffectsServiceProvider).play(SoundEffect.wrong);
  }

  /// Call when the lesson screen finishes loading and is ready.
  static void onLessonStart(WidgetRef ref) {
    _fireEvent(ref, 'lesson_start');
  }

  /// Call when the user completes all exercises in the lesson.
  static void onLessonComplete(WidgetRef ref) {
    _fireEvent(ref, 'lesson_complete');
    ref.read(soundEffectsServiceProvider).play(SoundEffect.lessonComplete);
  }

  /// Call when the user reaches a notable streak count.
  static void onStreakReached(WidgetRef ref, int count) {
    _fireEvent(ref, 'correct', text: 'Sequencia de $count acertos! Continue assim!');
    ref.read(soundEffectsServiceProvider).play(SoundEffect.streakFire);
  }

  /// Triggers a greeting from the active character (used at lesson start).
  static Future<void> showGreeting(WidgetRef ref) async {
    final characterId = ref.read(activeCharacterIdProvider);
    if (characterId == null) return;

    final character = await ref.read(characterByIdProvider(characterId).future);
    ref
        .read(characterControllerProvider(characterId).notifier)
        .showGreeting(character);

    // Also speak the greeting via TTS
    final greeting = character.getDialogue('greeting');
    if (greeting != null) {
      ref.read(ttsServiceProvider).speak(greeting, character.name);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Fires an event directly to the character controller.
  // TODO: reativar TTS e animações do personagem posteriormente
  static Future<void> _fireEvent(WidgetRef ref, String type, {String? text}) async {
    // final characterId = ref.read(activeCharacterIdProvider);
    // if (characterId == null) return;
    // try {
    //   final character = await ref.read(characterByIdProvider(characterId).future);
    //   final event = DialogueEvent(type: type, text: text);
    //   ref.read(characterControllerProvider(characterId).notifier)
    //       .reactToLessonEvent(event, character);
    //   final dialogue = text ?? character.getDialogue(type);
    //   if (dialogue != null) {
    //     ref.read(ttsServiceProvider).speak(dialogue, character.name);
    //   }
    // } catch (_) {}
  }
}
