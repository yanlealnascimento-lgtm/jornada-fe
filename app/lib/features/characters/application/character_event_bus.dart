import 'dart:async';

import '../domain/models/dialogue_event.dart';

/// A broadcast event that pairs a [DialogueEvent] with the target characterId.
class CharacterBusEvent {
  final String characterId;
  final DialogueEvent event;

  const CharacterBusEvent({
    required this.characterId,
    required this.event,
  });
}

/// Singleton event bus for broadcasting character-related events.
///
/// Lesson screens fire events via [fire], and character controllers
/// (or widgets) listen via [stream].
///
/// ```dart
/// // Fire from a lesson screen:
/// CharacterEventBus.instance.fire(
///   CharacterBusEvent(
///     characterId: 'moses',
///     event: DialogueEvent(type: 'correct'),
///   ),
/// );
///
/// // Listen in a widget or controller:
/// CharacterEventBus.instance.stream.listen((busEvent) { ... });
/// ```
class CharacterEventBus {
  CharacterEventBus._();

  static final CharacterEventBus instance = CharacterEventBus._();

  final _controller = StreamController<CharacterBusEvent>.broadcast();

  /// Stream of character bus events.
  Stream<CharacterBusEvent> get stream => _controller.stream;

  /// Fires a new event into the bus.
  void fire(CharacterBusEvent event) {
    _controller.add(event);
  }

  /// Convenience to fire using positional values.
  void fireEvent({
    required String characterId,
    required String type,
    String? text,
  }) {
    _controller.add(
      CharacterBusEvent(
        characterId: characterId,
        event: DialogueEvent(type: type, text: text),
      ),
    );
  }

  /// Disposes the internal stream controller.
  /// Typically only called during app teardown / tests.
  void dispose() {
    _controller.close();
  }
}
