import 'dart:ui';

class CharacterDialogue {
  final String type;
  final String text;
  const CharacterDialogue({required this.type, required this.text});

  factory CharacterDialogue.fromJson(Map<String, dynamic> json) =>
      CharacterDialogue(
        type: (json['type'] ?? '') as String,
        text: (json['text'] ?? '') as String,
      );

  @override
  String toString() => text;
}

class CharacterModel {
  final String id;
  final String name;
  final String title;
  final String biblicalReference;
  final String biblicalStory;
  final String spriteUrl;
  final String? lottieIdleUrl;
  final String? lottieHappyUrl;
  final String? lottieSadUrl;
  final String colorHex;
  final String rarity;
  final bool isSacred;
  final bool isActive;
  final bool isUnlocked;
  final int sortOrder;
  final String? unlockCondition;
  final List<CharacterDialogue> dialogues;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.title,
    required this.biblicalReference,
    required this.biblicalStory,
    required this.spriteUrl,
    this.lottieIdleUrl,
    this.lottieHappyUrl,
    this.lottieSadUrl,
    required this.colorHex,
    required this.rarity,
    required this.isSacred,
    required this.isActive,
    this.isUnlocked = false,
    required this.sortOrder,
    this.unlockCondition,
    required this.dialogues,
  });

  /// Alias para compatibilidade — gallery screen usa `character.story`
  String get story => biblicalStory;

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    // unlock_condition pode ser Map { type, value } ou String
    String? unlockStr;
    final uc = json['unlock_condition'];
    if (uc is Map) {
      final type = uc['type']?.toString() ?? '';
      final value = uc['value']?.toString() ?? '';
      unlockStr = value.isNotEmpty ? '$type: $value' : type;
    } else if (uc is String) {
      unlockStr = uc;
    }

    // dialogues pode conter Maps ou Strings
    final List<CharacterDialogue> dialogues = [];
    final rawDialogues = json['dialogues'];
    if (rawDialogues is List) {
      for (final d in rawDialogues) {
        if (d is Map<String, dynamic>) {
          dialogues.add(CharacterDialogue.fromJson(d));
        } else if (d is String) {
          dialogues.add(CharacterDialogue(type: 'generic', text: d));
        }
      }
    }

    return CharacterModel(
      id:                (json['_id'] ?? json['id'] ?? '').toString(),
      name:              (json['name'] ?? '').toString(),
      title:             (json['title'] ?? '').toString(),
      biblicalReference: (json['biblical_reference'] ?? '').toString(),
      biblicalStory:     (json['biblical_story'] ?? '').toString(),
      spriteUrl:         (json['sprite_url'] ?? '').toString(),
      lottieIdleUrl:     json['lottie_idle_url']?.toString(),
      lottieHappyUrl:    json['lottie_happy_url']?.toString(),
      lottieSadUrl:      json['lottie_sad_url']?.toString(),
      colorHex:          (json['color_hex'] ?? '#4A90E2').toString(),
      rarity:            (json['rarity'] ?? 'common').toString(),
      isSacred:          json['is_sacred'] == true,
      isActive:          json['is_active'] != false,
      isUnlocked:        json['is_unlocked'] == true,
      sortOrder:         (json['sort_order'] is num) ? (json['sort_order'] as num).toInt() : 0,
      unlockCondition:   unlockStr,
      dialogues:         dialogues,
    );
  }

  /// Retorna diálogo por tipo (ex: 'correct', 'wrong', 'greeting').
  String? getDialogue(String type) {
    final match = dialogues.where((d) => d.type == type).toList();
    if (match.isEmpty) return null;
    match.shuffle();
    return match.first.text;
  }

  /// Cor como Flutter Color.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
