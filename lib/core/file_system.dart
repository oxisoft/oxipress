import 'dart:io' as io;

import 'package:path/path.dart' as p;

/// A directory listing entry. Holds the full [path] and whether the entry
/// represents a directory.
class DirectoryEntry {
  const DirectoryEntry({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;

  String get name => p.basename(path);
  bool get isFile => !isDirectory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DirectoryEntry &&
          other.path == path &&
          other.isDirectory == isDirectory);

  @override
  int get hashCode => Object.hash(path, isDirectory);

  @override
  String toString() =>
      'DirectoryEntry(${isDirectory ? 'dir' : 'file'}: $path)';
}

class FileSystemException implements Exception {
  const FileSystemException(this.message);
  final String message;

  @override
  String toString() => 'FileSystemException: $message';
}

/// Pluggable filesystem facade. All filesystem reads in features go through
/// this so tests can substitute [InMemoryFileSystem].
abstract interface class FileSystem {
  Future<bool> fileExists(String path);
  Future<bool> directoryExists(String path);
  Future<List<DirectoryEntry>> listDirectory(String path);

  Future<String> readFileAsString(String path);
  Future<void> writeFileAsString(String path, String content);
  Future<void> createDirectory(String path, {bool recursive = false});
  Future<void> deleteFile(String path);
}

class RealFileSystem implements FileSystem {
  const RealFileSystem();

  @override
  Future<bool> fileExists(String path) async => io.File(path).existsSync();

  @override
  Future<bool> directoryExists(String path) async =>
      io.Directory(path).existsSync();

  @override
  Future<List<DirectoryEntry>> listDirectory(String path) async {
    final dir = io.Directory(path);
    if (!dir.existsSync()) {
      throw FileSystemException('Not a directory: $path');
    }
    return dir
        .listSync(followLinks: false)
        .map(
          (entity) => DirectoryEntry(
            path: entity.path,
            isDirectory: entity is io.Directory,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> readFileAsString(String path) async {
    final file = io.File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found: $path');
    }
    return file.readAsStringSync();
  }

  @override
  Future<void> writeFileAsString(String path, String content) async {
    io.File(path).writeAsStringSync(content, flush: true);
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    io.Directory(path).createSync(recursive: recursive);
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = io.File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

/// Self-consistent in-memory filesystem for tests. Uses host-style path
/// separators via `package:path` normalization, so tests should construct
/// paths with `p.join` to remain cross-platform.
class InMemoryFileSystem implements FileSystem {
  InMemoryFileSystem();

  final Map<String, _Entry> _entries = {};

  void addDirectory(String path) {
    final normalized = p.normalize(path);
    _entries[normalized] = _Entry.directory();
    _ensureParents(normalized);
  }

  void addFile(String path, {String content = ''}) {
    final normalized = p.normalize(path);
    _entries[normalized] = _Entry.file(content);
    _ensureParents(normalized);
  }

  void removeEntry(String path) {
    _entries.remove(p.normalize(path));
  }

  /// Convenience accessor for tests; returns the file's content if [path]
  /// resolves to a stored file.
  String? readSync(String path) {
    return _entries[p.normalize(path)]?.content;
  }

  void _ensureParents(String normalizedPath) {
    var parent = p.dirname(normalizedPath);
    while (parent.isNotEmpty) {
      if (_entries.containsKey(parent)) break;
      _entries[parent] = _Entry.directory();
      final next = p.dirname(parent);
      if (next == parent) break;
      parent = next;
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    return _entries[p.normalize(path)]?.isFile ?? false;
  }

  @override
  Future<bool> directoryExists(String path) async {
    return _entries[p.normalize(path)]?.isDirectory ?? false;
  }

  @override
  Future<List<DirectoryEntry>> listDirectory(String path) async {
    final normalized = p.normalize(path);
    final entry = _entries[normalized];
    if (entry == null || !entry.isDirectory) {
      throw FileSystemException('Not a directory: $path');
    }
    final sep = p.separator;
    final prefix =
        normalized.endsWith(sep) ? normalized : '$normalized$sep';
    final results = <DirectoryEntry>[];
    for (final key in _entries.keys) {
      if (key == normalized) continue;
      if (!key.startsWith(prefix)) continue;
      final rest = key.substring(prefix.length);
      if (rest.contains(sep)) continue;
      results.add(
        DirectoryEntry(
          path: key,
          isDirectory: _entries[key]!.isDirectory,
        ),
      );
    }
    return results;
  }

  @override
  Future<String> readFileAsString(String path) async {
    final entry = _entries[p.normalize(path)];
    if (entry == null || !entry.isFile) {
      throw FileSystemException('File not found: $path');
    }
    return entry.content ?? '';
  }

  @override
  Future<void> writeFileAsString(String path, String content) async {
    addFile(path, content: content);
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    final normalized = p.normalize(path);
    if (!recursive) {
      final parent = p.dirname(normalized);
      if (parent.isNotEmpty &&
          parent != normalized &&
          !_entries.containsKey(parent)) {
        throw FileSystemException(
          'Parent directory missing for: $path',
        );
      }
    }
    addDirectory(path);
  }

  @override
  Future<void> deleteFile(String path) async {
    removeEntry(path);
  }
}

class _Entry {
  _Entry.directory()
      : isDirectory = true,
        content = null;
  _Entry.file(this.content) : isDirectory = false;

  final bool isDirectory;
  final String? content;

  bool get isFile => !isDirectory;
}
