import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available sound effect types in the app.
enum SoundEffect {
  correct,
  wrong,
  streakFire,
  levelUp,
  lessonComplete,
}

/// Service responsible for playing short sound effects.
///
/// Currently a placeholder: it logs the requested effect and returns
/// immediately. Once audio assets are added, the implementation will
/// use `audioplayers` to play them.
class SoundEffectsService {
  double _volume = 1.0;

  /// Current playback volume (0.0 to 1.0).
  double get volume => _volume;

  /// Sets the playback volume. Clamped between 0.0 and 1.0.
  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  /// Plays the given [effect].
  ///
  /// For now this is a no-op placeholder that logs the intent.
  /// When audio files are available, replace the body with actual playback
  /// using `AudioPlayer` from `audioplayers`.
  Future<void> play(SoundEffect effect) async {
    dev.log(
      'SoundEffectsService.play(${effect.name}) — volume: $_volume [placeholder]',
      name: 'SoundFX',
    );

    // TODO: Wire actual audio files, e.g.:
    // final player = AudioPlayer();
    // await player.setVolume(_volume);
    // await player.play(AssetSource(_assetForEffect(effect)));
  }

  /// Releases any audio resources. Placeholder for future cleanup.
  void dispose() {
    // Nothing to dispose while in placeholder mode.
  }
}

/// Riverpod provider for [SoundEffectsService].
final soundEffectsServiceProvider = Provider<SoundEffectsService>((ref) {
  final service = SoundEffectsService();
  ref.onDispose(() => service.dispose());
  return service;
});
