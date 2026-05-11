import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/file_watcher.dart';
import '../../../core/providers.dart';
import '../../project/ui/project_controller.dart';
import '../domain/editor_buffer.dart';
import '../domain/frontmatter.dart';
import '../domain/frontmatter_parser.dart';
import '../domain/frontmatter_serializer.dart';
import 'external_changes_controller.dart';

/// Centralized store of [EditorBuffer]s keyed by absolute path. Widgets
/// `select` on the path of interest so unrelated buffer changes don't
/// trigger their rebuild.
///
/// Saves are entirely user-driven (Ctrl/Cmd+S or the toolbar Save button);
/// there is no auto-save. Closing a dirty tab triggers a confirm prompt at
/// the UI layer.
class EditorBuffersController
    extends Notifier<Map<String, EditorBuffer>> {
  @override
  Map<String, EditorBuffer> build() {
    final lifecycle = ref.watch(projectControllerProvider);
    StreamSubscription<FsChange>? watcherSub;
    if (lifecycle is OpenProject) {
      final watcher = ref.read(fileWatcherProvider);
      watcherSub =
          watcher.watch(lifecycle.project.path).listen(_onWatcherChange);
    } else {
      ref.read(externalChangesProvider.notifier).clear();
    }
    ref.onDispose(() {
      watcherSub?.cancel();
    });
    return const {};
  }

  /// How long after a save we ignore watcher events for the same file —
  /// otherwise our own atomic-rename writes look like external changes.
  static const Duration _selfWriteIgnoreWindow = Duration(seconds: 1);

  void _onWatcherChange(FsChange change) {
    final buffer = state[change.path];
    if (buffer == null) return;
    final lastSaved = buffer.lastSavedAt;
    if (lastSaved != null &&
        DateTime.now().difference(lastSaved) < _selfWriteIgnoreWindow) {
      return;
    }
    if (change.type == FsChangeType.removed) {
      if (buffer.isDirty) {
        ref.read(externalChangesProvider.notifier).mark(change.path);
      } else {
        close(change.path);
      }
      return;
    }
    if (buffer.isDirty) {
      ref.read(externalChangesProvider.notifier).mark(change.path);
    } else {
      // ignore: discarded_futures
      reloadFromDisk(change.path);
    }
  }

  /// Returns the buffer for [absolutePath], reading + parsing from disk if
  /// it isn't already in memory.
  Future<EditorBuffer> ensureLoaded(String absolutePath) async {
    final existing = state[absolutePath];
    if (existing != null) return existing;
    final fs = ref.read(fileSystemProvider);
    final raw = await fs.readFileAsString(absolutePath);
    final document = parseMarkdown(raw);
    final buffer = EditorBuffer.fromDocument(absolutePath, document);
    state = {...state, absolutePath: buffer};
    return buffer;
  }

  void updateBody(String absolutePath, String body) {
    final existing = state[absolutePath];
    if (existing == null) return;
    if (existing.currentBody == body) return;
    state = {...state, absolutePath: existing.copyWith(currentBody: body)};
  }

  void updateEntryValue(String absolutePath, String key, Object? value) {
    final existing = state[absolutePath];
    if (existing == null) return;
    final entries = existing.currentEntries
        .map(
          (e) => e.key == key
              ? FrontmatterEntry(key: e.key, value: value)
              : e,
        )
        .toList(growable: false);
    state = {
      ...state,
      absolutePath: existing.copyWith(currentEntries: entries),
    };
  }

  void renameEntry(String absolutePath, int index, String newKey) {
    final existing = state[absolutePath];
    if (existing == null) return;
    if (index < 0 || index >= existing.currentEntries.length) return;
    final entries = List<FrontmatterEntry>.of(existing.currentEntries);
    entries[index] =
        FrontmatterEntry(key: newKey, value: entries[index].value);
    state = {
      ...state,
      absolutePath: existing.copyWith(currentEntries: entries),
    };
  }

  void addEntry(String absolutePath, {String key = '', Object? value}) {
    final existing = state[absolutePath];
    if (existing == null) return;
    state = {
      ...state,
      absolutePath: existing.copyWith(
        currentEntries: [
          ...existing.currentEntries,
          FrontmatterEntry(key: key, value: value),
        ],
      ),
    };
  }

  void removeEntry(String absolutePath, int index) {
    final existing = state[absolutePath];
    if (existing == null) return;
    if (index < 0 || index >= existing.currentEntries.length) return;
    final entries = List<FrontmatterEntry>.of(existing.currentEntries)
      ..removeAt(index);
    state = {
      ...state,
      absolutePath: existing.copyWith(currentEntries: entries),
    };
  }

  Future<void> save(String absolutePath) async {
    final existing = state[absolutePath];
    if (existing == null) return;
    final source = serializeMarkdown(
      format: existing.format,
      entries: existing.currentEntries,
      body: existing.currentBody,
    );
    final fs = ref.read(fileSystemProvider);
    await fs.writeFileAtomic(absolutePath, source);
    state = {...state, absolutePath: existing.markedSaved()};
  }

  void revert(String absolutePath) {
    final existing = state[absolutePath];
    if (existing == null) return;
    state = {...state, absolutePath: existing.reverted()};
  }

  /// Re-reads the file from disk, replacing both saved and current snapshots.
  Future<EditorBuffer?> reloadFromDisk(String absolutePath) async {
    final fs = ref.read(fileSystemProvider);
    final raw = await fs.readFileAsString(absolutePath);
    final document = parseMarkdown(raw);
    final buffer = EditorBuffer.fromDocument(absolutePath, document);
    state = {...state, absolutePath: buffer};
    return buffer;
  }

  void close(String absolutePath) {
    if (!state.containsKey(absolutePath)) return;
    final next = Map<String, EditorBuffer>.of(state)..remove(absolutePath);
    state = next;
  }

  /// Moves a buffer to a new absolute path key (used after a rename). No-op
  /// if there's no buffer at the old key.
  void rekey(String oldAbsolutePath, String newAbsolutePath) {
    final existing = state[oldAbsolutePath];
    if (existing == null) return;
    if (oldAbsolutePath == newAbsolutePath) return;
    final next = Map<String, EditorBuffer>.of(state)
      ..remove(oldAbsolutePath)
      ..[newAbsolutePath] = EditorBuffer(
        absolutePath: newAbsolutePath,
        format: existing.format,
        savedEntries: existing.savedEntries,
        savedBody: existing.savedBody,
        currentEntries: existing.currentEntries,
        currentBody: existing.currentBody,
        lastSavedAt: existing.lastSavedAt,
      );
    state = next;
  }
}

final editorBuffersProvider =
    NotifierProvider<EditorBuffersController, Map<String, EditorBuffer>>(
  EditorBuffersController.new,
);

/// Convenience provider that triggers `ensureLoaded` on first access and
/// surfaces the buffer reactively (so edits to the buffer's body /
/// frontmatter rebuild the watcher).
final editorBufferProvider = FutureProvider.autoDispose
    .family<EditorBuffer, String>((ref, absolutePath) async {
  final existing = ref.watch(
    editorBuffersProvider.select((m) => m[absolutePath]),
  );
  if (existing != null) return existing;
  return ref
      .read(editorBuffersProvider.notifier)
      .ensureLoaded(absolutePath);
});
