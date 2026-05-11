import 'dart:async';

import 'package:watcher/watcher.dart' as w;

enum FsChangeType { added, modified, removed }

class FsChange {
  const FsChange({required this.type, required this.path});

  final FsChangeType type;
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FsChange && other.type == type && other.path == path);

  @override
  int get hashCode => Object.hash(type, path);

  @override
  String toString() => 'FsChange(${type.name}, $path)';
}

/// Pluggable directory watcher. Real implementation is backed by
/// `package:watcher`; tests use [FakeFileWatcher] to drive events synchronously.
abstract interface class FileWatcher {
  /// Watch [path] for changes. Returns a broadcast stream — callers are
  /// responsible for cancelling their subscriptions when done.
  Stream<FsChange> watch(String path);
}

class WatcherFileWatcher implements FileWatcher {
  const WatcherFileWatcher();

  @override
  Stream<FsChange> watch(String path) {
    final watcher = w.DirectoryWatcher(path);
    return watcher.events
        .map(_mapEvent)
        .where((event) => event != null)
        .cast<FsChange>();
  }

  FsChange? _mapEvent(w.WatchEvent event) {
    final type = switch (event.type) {
      w.ChangeType.ADD => FsChangeType.added,
      w.ChangeType.MODIFY => FsChangeType.modified,
      w.ChangeType.REMOVE => FsChangeType.removed,
      _ => null,
    };
    if (type == null) return null;
    return FsChange(type: type, path: event.path);
  }
}

class FakeFileWatcher implements FileWatcher {
  FakeFileWatcher();

  final Map<String, StreamController<FsChange>> _controllers = {};

  void emit(String watchedPath, FsChange change) {
    _controllers[watchedPath]?.add(change);
  }

  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }

  @override
  Stream<FsChange> watch(String path) {
    return _controllers
        .putIfAbsent(path, StreamController<FsChange>.broadcast)
        .stream;
  }
}
