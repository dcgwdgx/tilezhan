import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/tile_model.dart';
import '../../shared/data/tile_repository.dart';

final tileRepositoryProvider = Provider<TileRepository>((ref) => TileRepository());

final tileDataProvider = FutureProvider<List<TileModel>>((ref) async {
  return ref.read(tileRepositoryProvider).loadAllTiles();
});
