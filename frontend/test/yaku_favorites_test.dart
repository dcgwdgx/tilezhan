import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/features/yaku_detail/domain/yaku_favorites_provider.dart';

void main() {
  Hive.init('./test/hive_yaku_fav');

  setUp(() async {
    await Hive.openBox('yaku_favorites');
    // Clear any existing data before each test
    final box = Hive.box('yaku_favorites');
    await box.clear();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('YakuFavoritesNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with empty favorites', () {
      final favs = container.read(yakuFavoritesProvider);
      expect(favs, isEmpty);
    });

    test('toggle adds a yaku ID', () {
      final notifier = container.read(yakuFavoritesProvider.notifier);
      notifier.toggle('riichi');
      expect(container.read(yakuFavoritesProvider), {'riichi'});
    });

    test('toggle removes a yaku ID when already present', () {
      final notifier = container.read(yakuFavoritesProvider.notifier);
      notifier.toggle('riichi');
      notifier.toggle('riichi');
      expect(container.read(yakuFavoritesProvider), isEmpty);
    });

    test('isFavorite returns correct values', () {
      final notifier = container.read(yakuFavoritesProvider.notifier);
      expect(notifier.isFavorite('riichi'), false);
      notifier.toggle('riichi');
      expect(notifier.isFavorite('riichi'), true);
    });

    test('multiple yaku can be favorited', () {
      final notifier = container.read(yakuFavoritesProvider.notifier);
      notifier.toggle('riichi');
      notifier.toggle('tanyao');
      notifier.toggle('daisangen');
      expect(container.read(yakuFavoritesProvider), {'riichi', 'tanyao', 'daisangen'});
    });

    test('persists across provider recreations', () {
      // Toggle a favorite
      container.read(yakuFavoritesProvider.notifier).toggle('riichi');
      container.dispose();

      // Create a new container and verify persistence
      final container2 = ProviderContainer();
      addTearDown(() => container2.dispose());
      final favs = container2.read(yakuFavoritesProvider);
      expect(favs, {'riichi'});
    });
  });
}
