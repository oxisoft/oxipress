import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/storage.dart';

void main() {
  group('InMemoryStorage', () {
    test('round-trips string values', () async {
      final s = InMemoryStorage();
      await s.setString('k', 'v');
      expect(await s.getString('k'), 'v');
      expect(await s.containsKey('k'), isTrue);
    });

    test('round-trips bool, int, double, list', () async {
      final s = InMemoryStorage();
      await s.setBool('b', true);
      await s.setInt('i', 7);
      await s.setDouble('d', 1.5);
      await s.setStringList('l', ['a', 'b']);
      expect(await s.getBool('b'), isTrue);
      expect(await s.getInt('i'), 7);
      expect(await s.getDouble('d'), 1.5);
      expect(await s.getStringList('l'), ['a', 'b']);
    });

    test('returns null for missing keys', () async {
      final s = InMemoryStorage();
      expect(await s.getString('nope'), isNull);
      expect(await s.containsKey('nope'), isFalse);
    });

    test('remove deletes a key', () async {
      final s = InMemoryStorage();
      await s.setString('k', 'v');
      await s.remove('k');
      expect(await s.getString('k'), isNull);
      expect(await s.containsKey('k'), isFalse);
    });

    test('clear empties storage', () async {
      final s = InMemoryStorage();
      await s.setString('a', '1');
      await s.setString('b', '2');
      await s.clear();
      expect(await s.containsKey('a'), isFalse);
      expect(await s.containsKey('b'), isFalse);
    });

    test('seeds from initial map', () async {
      final s = InMemoryStorage({'preset': 'value'});
      expect(await s.getString('preset'), 'value');
    });
  });
}
