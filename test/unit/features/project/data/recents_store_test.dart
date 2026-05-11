import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/project/data/recents_store.dart';
import 'package:oxipress/features/project/domain/recent_project.dart';

RecentProject _entry(String name, {DateTime? when}) => RecentProject(
      path: '/sites/$name',
      name: name,
      lastOpenedAt: when ?? DateTime.utc(2026, 1, 1),
    );

void main() {
  group('RecentsStore', () {
    test('returns empty list when nothing stored', () async {
      final store = RecentsStore(InMemoryStorage());
      expect(await store.load(), isEmpty);
    });

    test('add inserts most-recently-opened first', () async {
      final store = RecentsStore(InMemoryStorage());
      await store.add(_entry('alpha'));
      await store.add(_entry('beta'));
      final loaded = await store.load();
      expect(loaded.map((r) => r.name), ['beta', 'alpha']);
    });

    test('add deduplicates by path and bumps to top', () async {
      final store = RecentsStore(InMemoryStorage());
      await store.add(_entry('alpha'));
      await store.add(_entry('beta'));
      await store.add(_entry('alpha',
          when: DateTime.utc(2026, 6, 1))); // re-open
      final loaded = await store.load();
      expect(loaded.map((r) => r.name), ['alpha', 'beta']);
      expect(loaded.length, 2);
    });

    test('add caps the list at maxRecents (10)', () async {
      final store = RecentsStore(InMemoryStorage());
      for (var i = 0; i < 15; i++) {
        await store.add(_entry('site$i',
            when: DateTime.utc(2026, 1, 1).add(Duration(days: i))));
      }
      final loaded = await store.load();
      expect(loaded.length, RecentsStore.maxRecents);
      // Most recent five additions survive (site14 → site5).
      expect(loaded.first.name, 'site14');
    });

    test('remove removes by path', () async {
      final store = RecentsStore(InMemoryStorage());
      await store.add(_entry('alpha'));
      await store.add(_entry('beta'));
      await store.remove('/sites/alpha');
      final loaded = await store.load();
      expect(loaded.map((r) => r.name), ['beta']);
    });

    test('prune drops entries whose path no longer exists', () async {
      final fs = InMemoryFileSystem()..addDirectory('/sites/alpha');
      final store = RecentsStore(InMemoryStorage());
      await store.add(_entry('alpha'));
      await store.add(_entry('beta'));
      final pruned = await store.prune(fs);
      expect(pruned.map((r) => r.name), ['alpha']);
      expect((await store.load()).map((r) => r.name), ['alpha']);
    });

    test('survives malformed JSON by returning empty list', () async {
      final storage = InMemoryStorage({'recents.v1': '{not-json'});
      final store = RecentsStore(storage);
      expect(await store.load(), isEmpty);
    });
  });
}
