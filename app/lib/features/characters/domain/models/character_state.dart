enum CharacterAnimationState {
  idle,
  talking,
  happy,
  celebrating,
  sad,
  surprised,
  thinking,
  walking,
  greeting,
  farewell,
  narrating,
}

class CharacterDisplayState {
  final String characterId;
  final CharacterAnimationState animation;
  final String? dialogueText;
  final bool isSpeechBubbleVisible;
  final Duration speechDuration;

  const CharacterDisplayState({
    required this.characterId,
    required this.animation,
    this.dialogueText,
    this.isSpeechBubbleVisible = false,
    this.speechDuration = const Duration(seconds: 3),
  });

  CharacterDisplayState copyWith({
    String? characterId,
    CharacterAnimationState? animation,
    String? dialogueText,
    bool? isSpeechBubbleVisible,
    Duration? speechDuration,
  }) {
    return CharacterDisplayState(
      characterId: characterId ?? this.characterId,
      animation: animation ?? this.animation,
      dialogueText: dialogueText ?? this.dialogueText,
      isSpeechBubbleVisible:
          isSpeechBubbleVisible ?? this.isSpeechBubbleVisible,
      speechDuration: speechDuration ?? this.speechDuration,
    );
  }
}
