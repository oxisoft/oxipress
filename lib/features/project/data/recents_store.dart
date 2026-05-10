import 'dart:convert';

import '../../../core/file_system.dart';
import '../../../core/storage.dart';
import '../domain/recent_project.dart';

/// Persists the recent-projects list. Backed by [Storage]; tests inject
/// `InMemoryStorage` to verify behaviour without touching disk.
class RecentsStore {
  RecentsStore(this._storage);

  static const String _key = 'recents.v1';
  static const int maxRecents = 10;

  final Storage _storage;

  Future<List<RecentProject>> load() async {
    final raw = await _storage.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RecentProject.fromJson)
          .toList(growable: false);
    } on FormatException catch (_) {
      return const [];
    } on TypeError catch (_) {
      return const [];
    }
  }

  Future<List<RecentProject>> add(RecentProject project) async {
    final current = await load();
    final filtered =
        current.where((r) => r.path != project.path).toList(growable: true);
    filtered.insert(0, project);
    if (filtered.length > maxRecents) {
      filtered.removeRange(maxRecents, filtered.length);
    }
    await _persist(filtered);
    return List.unmodifiable(filtered);
  }

  Future<List<RecentProject>> remove(String path) async {
    final current = await load();
    final filtered =
        current.where((r) => r.path != path).toList(growable: false);
    if (filtered.length != current.length) {
      await _persist(filtered);
    }
    return filtered;
  }

  /// Returns the recents list with entries whose path no longer exists on
  /// disk filtered out. Updates persisted state if anything was pruned.
  Future<List<RecentProject>> prune(FileSystem fileSystem) async {
    final current = await load();
    final stillPresent = <RecentProject>[];
    for (final entry in current) {
      if (await fileSystem.directoryExists(entry.path)) {
        stillPresent.add(entry);
      }
    }
    if (stillPresent.length != current.length) {
      await _persist(stillPresent);
    }
    return List.unmodifiable(stillPresent);
  }

  Future<void> _persist(List<RecentProject> entries) async {
    final encoded =
        jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await _storage.setString(_key, encoded);
  }
}
