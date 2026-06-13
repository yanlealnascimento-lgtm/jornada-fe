import 'package:flutter/material.dart';

class CharacterDialog extends StatelessWidget {
  final String characterName;
  final String message;
  final String? characterImageAsset;

  const CharacterDialog({
    super.key,
    required this.characterName,
    required this.message,
    this.characterImageAsset,
  });

  @override
  Widget build(BuildContext context) {
    // Simple instruction text without character avatar
    return Text(
      message,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: Color(0xFF131F24),
        fontFamily: 'Nunito',
      ),
    );
  }
}
