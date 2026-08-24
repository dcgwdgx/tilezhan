import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/storage/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService.getIntOrNull', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'tilezhan-storage-test-',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDirectory.path;
        }
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await tempDirectory.delete(recursive: true);
    });

    test('distinguishes a missing value from a saved zero', () async {
      final storage = await StorageService.init();

      expect(storage.getIntOrNull(StorageService.kElo), isNull);
      expect(storage.getInt(StorageService.kElo), 0);

      await storage.setInt(StorageService.kElo, 0);
      expect(storage.getIntOrNull(StorageService.kElo), 0);

      await storage.setInt(StorageService.kElo, 925);
      expect(storage.getIntOrNull(StorageService.kElo), 925);
      expect(storage.getInt(StorageService.kElo), 925);
    });

    test('returns null for a non-int stored value', () async {
      await File('${tempDirectory.path}/prefs.json').writeAsString(
        '{"elo":"not-an-int"}',
      );
      final storage = await StorageService.init();

      expect(storage.getIntOrNull(StorageService.kElo), isNull);
    });
  });
}
