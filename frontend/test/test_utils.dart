import 'package:tilezhan/shared/models/tile_model.dart';

/// Shared test utilities — keeps test files DRY.

TileModel makeTile(String id, TileSuit suit, [String label = '']) {
  return TileModel(
    id: id,
    suit: suit,
    character: id,
    seal: '',
    value: 1,
    label: label.isEmpty ? id : label,
    mnemonic: const MnemonicData(
      emoji: '🀄',
      name: '',
      slogan: '',
      desc: '',
      chinese: '',
      anchor: '',
    ),
    confusedWith: const [],
  );
}
