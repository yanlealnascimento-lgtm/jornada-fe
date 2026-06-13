import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Voice settings for a character (pitch and speech rate).
class _VoiceSettings {
  final double pitch;
  final double rate;
  const _VoiceSettings(this.pitch, this.rate);
}

/// Character-specific voice configurations.
const _characterVoiceMap = <String, _VoiceSettings>{
  'moses': _VoiceSettings(0.85, 0.8), // grave, lento
  'david': _VoiceSettings(1.05, 0.9), // jovem, animado
  'esther': _VoiceSettings(1.1, 0.85), // feminino, suave
  'caleb': _VoiceSettings(0.95, 0.9), // corajoso, firme
};

const _defaultVoice = _VoiceSettings(1.0, 0.85);

/// Service that wraps [FlutterTts] and adjusts voice parameters per character.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _available = false;

  bool get isAvailable => _available;

  /// Initialises the TTS engine for pt-BR.
  Future<void> init() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setVolume(1.0);
      _available = true;
    } catch (_) {
      // Some devices/emulators don't support TTS — degrade gracefully.
      _available = false;
    }
  }

  /// Speaks [text] using voice settings mapped to [characterName].
  ///
  /// [characterName] is matched case-insensitively against known characters.
  /// Falls back to default settings when the character is unknown.
  Future<void> speak(String text, String characterName) async {
    if (!_available || text.isEmpty) return;

    final key = characterName.toLowerCase();
    final settings = _characterVoiceMap[key] ?? _defaultVoice;

    try {
      await _tts.setPitch(settings.pitch);
      await _tts.setSpeechRate(settings.rate);
      await _tts.speak(text);
    } catch (_) {
      // Silently ignore runtime TTS errors.
    }
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    if (!_available) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Releases TTS resources.
  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// Riverpod provider for [TtsService].
///
/// The service is created once and initialised eagerly.
/// Dispose is handled automatically when the provider is destroyed.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});
