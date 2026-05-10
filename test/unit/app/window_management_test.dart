import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/app/window_management.dart';
import 'package:oxipress/core/storage.dart';

void main() {
  group('WindowState', () {
    test('JSON round-trips with all fields', () {
      const original = WindowState(width: 1400, height: 900, x: 100, y: 200);
      final json = original.toJson();
      final restored = WindowState.fromJson(
        Map<String, Object?>.from(json),
      );
      expect(restored, equals(original));
    });

    test('JSON round-trips without position', () {
      const original = WindowState(width: 1400, height: 900);
      final restored = WindowState.fromJson(
        Map<String, Object?>.from(original.toJson()),
      );
      expect(restored, equals(original));
      expect(restored.x, isNull);
      expect(restored.y, isNull);
    });

    test('defaults are 1280x800 with no position', () {
      expect(WindowState.defaults.width, 1280);
      expect(WindowState.defaults.height, 800);
      expect(WindowState.defaults.x, isNull);
      expect(WindowState.defaults.y, isNull);
    });
  });

  group('WindowPersistence', () {
    test('returns defaults when no value stored', () async {
      final p = WindowPersistence(InMemoryStorage());
      expect(await p.load(), WindowState.defaults);
    });

    test('persists and reloads window state', () async {
      final storage = InMemoryStorage();
      final p = WindowPersistence(storage);
      const state = WindowState(width: 1500, height: 1000, x: 50, y: 75);
      await p.save(state);
      expect(await p.load(), state);
    });

    test('returns defaults when stored value is malformed', () async {
      final storage = InMemoryStorage({'window.state.v1': '{not valid'});
      final p = WindowPersistence(storage);
      expect(await p.load(), WindowState.defaults);
    });
  });
}
