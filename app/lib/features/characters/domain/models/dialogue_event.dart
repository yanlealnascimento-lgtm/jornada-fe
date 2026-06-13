class DialogueEvent {
  /// Event type: correct, wrong, greeting, lesson_start, lesson_complete,
  /// streak_warning, streak_broken, level_up, narrating.
  final String type;

  /// Optional text override. When provided, this text is shown instead of
  /// picking a random dialogue from the character model.
  final String? text;

  const DialogueEvent({
    required this.type,
    this.text,
  });
}
