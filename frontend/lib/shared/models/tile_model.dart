import 'package:flutter/material.dart';

enum TileSuit { man, pin, sou, wind, dragon }

class MnemonicData {
  final String emoji;
  final String name;
  final String slogan;
  final String desc;
  final String chinese;
  final String anchor;

  const MnemonicData({
    required this.emoji,
    required this.name,
    required this.slogan,
    required this.desc,
    required this.chinese,
    required this.anchor,
  });

  factory MnemonicData.fromJson(Map<String, dynamic> json) => MnemonicData(
    emoji: json['emoji'] ?? '',
    name: json['name'] ?? '',
    slogan: json['slogan'] ?? '',
    desc: json['desc'] ?? '',
    chinese: json['chinese'] ?? '',
    anchor: json['anchor'] ?? '',
  );
}

class TileModel {
  final String id;
  final TileSuit suit;
  final String character;
  final String seal;
  final dynamic value;
  final String label;
  final MnemonicData mnemonic;
  final List<String> confusedWith;

  const TileModel({
    required this.id,
    required this.suit,
    required this.character,
    required this.seal,
    required this.value,
    required this.label,
    required this.mnemonic,
    required this.confusedWith,
  });

  factory TileModel.fromJson(Map<String, dynamic> json) => TileModel(
    id: json['id'] as String,
    suit: TileSuit.values.firstWhere((s) => s.name == json['suit']),
    character: json['character'] ?? '',
    seal: json['seal'] ?? '',
    value: json['value'],
    label: json['label'] ?? '',
    mnemonic: MnemonicData.fromJson(json['mnemonic'] ?? {}),
    confusedWith: List<String>.from(json['confused_with'] ?? []),
  );

  Color get suitColor => switch (suit) {
    TileSuit.man => const Color(0xFFE74C3C),
    TileSuit.pin => const Color(0xFF3498DB),
    TileSuit.sou => const Color(0xFF2ECC71),
    TileSuit.wind => const Color(0xFFF39C12),
    TileSuit.dragon => const Color(0xFF9B59B6),
  };
}
