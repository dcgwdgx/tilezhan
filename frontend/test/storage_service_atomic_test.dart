import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/storage/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService atomic JSON persistence', () {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    const key = 'atomic_test';
    late Directory tempDirectory;
    late StorageService storage;

    File target() => File('${tempDirectory.path}/$key.json');
    File backup() => File('${tempDirectory.path}/$key.json.bak');
    File temporary() => File('${tempDirectory.path}/$key.json.tmp');

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'tilezhan-atomic-storage-test-',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDirectory.path;
        }
        return null;
      });
      storage = await StorageService.init();
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await tempDirectory.delete(recursive: true);
    });

    test('new commits read back consistently and retain the previous commit',
        () async {
      const oldValue = {
        'version': 1,
        'nested': {'ready': true},
      };
      const newValue = {
        'version': 2,
        'items': ['m1', 'm2'],
      };

      await storage.setJson(key, oldValue);
      expect(storage.getJson(key), oldValue);
      expect(target().existsSync(), isTrue);
      expect(temporary().existsSync(), isFalse);

      await storage.setJson(key, newValue);

      expect(storage.getJson(key), newValue);
      expect(
        jsonDecode(backup().readAsStringSync()),
        oldValue,
      );
      expect(temporary().existsSync(), isFalse);
    });

    test('an interruption after backup rotation recovers the old commit',
        () async {
      const oldValue = {'version': 'old'};
      const stagedValue = {'version': 'not-committed'};
      await storage.setJson(key, oldValue);

      target().renameSync(backup().path);
      temporary().writeAsStringSync(jsonEncode(stagedValue), flush: true);

      expect(target().existsSync(), isFalse);
      expect(storage.getJson(key), oldValue);
      expect(temporary().existsSync(), isTrue);
      expect(jsonDecode(temporary().readAsStringSync()), stagedValue);
    });

    test('a corrupt target falls back to its last valid backup', () async {
      const oldValue = {'version': 'old'};
      const committedValue = {'version': 'new'};
      const stagedValue = {'version': 'newer-but-uncommitted'};
      await storage.setJson(key, oldValue);
      await storage.setJson(key, committedValue);

      target().writeAsStringSync('{"version":', flush: true);
      temporary().writeAsStringSync(jsonEncode(stagedValue), flush: true);

      expect(storage.getJson(key), oldValue);
      expect(jsonDecode(backup().readAsStringSync()), oldValue);
      expect(jsonDecode(temporary().readAsStringSync()), stagedValue);
    });

    test('a temporary file alone is never treated as committed data', () {
      temporary().writeAsStringSync(
        jsonEncode(const {'version': 'staged-only'}),
        flush: true,
      );

      expect(storage.getJson(key), isEmpty);
      expect(target().existsSync(), isFalse);
      expect(backup().existsSync(), isFalse);
    });

    test('concurrent calls for one key commit in call order', () async {
      await Future.wait([
        storage.setJson(key, const {'version': 1}),
        storage.setJson(key, const {'version': 2}),
        storage.setJson(key, const {'version': 3}),
      ]);

      expect(storage.getJson(key), {'version': 3});
      expect(jsonDecode(backup().readAsStringSync()), {'version': 2});
      expect(temporary().existsSync(), isFalse);
    });
  });
}
