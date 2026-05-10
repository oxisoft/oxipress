import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/features/editor/data/editor_buffers_controller.dart';

const _path = '/sites/sample/content/post.md';
const _initial = '''
---
title: Post
draft: false
---

Body content.
''';

ProviderContainer _container({
  required FileSystem fs,
  FileWatcher? watcher,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      fileSystemProvider.overrideWithValue(fs),
      fileWatcherProvider.overrideWithValue(watcher ?? FakeFileWatcher()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('EditorBuffersController', () {
    test('ensureLoaded reads + parses a markdown file into memory',
        () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final buffer = await container
          .read(editorBuffersProvider.notifier)
          .ensureLoaded(_path);
      expect(buffer.absolutePath, _path);
      expect(buffer.currentBody.trim(), 'Body content.');
      expect(buffer.isDirty, isFalse);
      expect(
        container.read(editorBuffersProvider)[_path],
        isNotNull,
      );
    });

    test('updateBody flips isDirty', () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final controller = container.read(editorBuffersProvider.notifier);
      await controller.ensureLoaded(_path);
      controller.updateBody(_path, 'changed body');
      final buffer = container.read(editorBuffersProvider)[_path]!;
      expect(buffer.currentBody, 'changed body');
      expect(buffer.isDirty, isTrue);
    });

    test('save serializes + writes atomically and clears dirty', () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final controller = container.read(editorBuffersProvider.notifier);
      await controller.ensureLoaded(_path);
      controller.updateBody(_path, 'rewritten body\n');
      await controller.save(_path);

      final buffer = container.read(editorBuffersProvider)[_path]!;
      expect(buffer.isDirty, isFalse);

      // The file on disk now contains the rewritten body.
      final onDisk = await fs.readFileAsString(_path);
      expect(onDisk.contains('rewritten body'), isTrue);
      expect(onDisk.startsWith('---\n'), isTrue);
    });

    test('updateEntryValue rewrites a known field', () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final controller = container.read(editorBuffersProvider.notifier);
      await controller.ensureLoaded(_path);
      controller.updateEntryValue(_path, 'title', 'Different');
      await controller.save(_path);
      final onDisk = await fs.readFileAsString(_path);
      expect(onDisk.contains('title: Different'), isTrue);
    });

    test('close removes the buffer from the map', () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final controller = container.read(editorBuffersProvider.notifier);
      await controller.ensureLoaded(_path);
      controller.close(_path);
      expect(container.read(editorBuffersProvider)[_path], isNull);
    });

    test('reloadFromDisk drops in-memory edits in favor of disk content',
        () async {
      final fs = InMemoryFileSystem()
        ..addFile(_path, content: _initial);
      final container = _container(fs: fs);
      final controller = container.read(editorBuffersProvider.notifier);
      await controller.ensureLoaded(_path);
      controller.updateBody(_path, 'unsaved');
      expect(container.read(editorBuffersProvider)[_path]!.isDirty, isTrue);
      await controller.reloadFromDisk(_path);
      final buffer = container.read(editorBuffersProvider)[_path]!;
      expect(buffer.isDirty, isFalse);
      expect(buffer.currentBody.trim(), 'Body content.');
    });
  });
}
