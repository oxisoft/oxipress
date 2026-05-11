import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/editor/data/editor_buffers_controller.dart';
import 'package:oxipress/features/editor/ui/editor_panel.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';
import 'package:oxipress/features/project/ui/workspace_state_controller.dart';

import '../../../helpers/pump_app.dart';

const _projectPath = '/sites/sample';
const _filePath = '$_projectPath/content/post.md';
const _initialSource = '''
---
title: Post
draft: false
---

Body.
''';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile('$_projectPath/hugo.toml')
    ..addDirectory('$_projectPath/content')
    ..addFile(_filePath, content: _initialSource);
}

Future<ProviderContainer> _bootWithOpenTab(WidgetTester tester) async {
  final fs = _hugoSite();
  final container = await pumpAppWith(
    tester,
    const Scaffold(body: EditorPanel()),
    overrides: [
      storageProvider.overrideWithValue(InMemoryStorage()),
      fileSystemProvider.overrideWithValue(fs),
      fileWatcherProvider.overrideWithValue(FakeFileWatcher()),
    ],
  );
  await container
      .read(projectControllerProvider.notifier)
      .openProject(_projectPath);
  await tester.pumpAndSettle();
  // Ensure the workspace state controller has finished loading before
  // mutating tabs — otherwise its state.value is null and openTab is a
  // no-op.
  await container.read(workspaceStateProvider.future);
  await container
      .read(workspaceStateProvider.notifier)
      .openTab('content/post.md');
  await tester.pumpAndSettle();
  await container.read(editorBuffersProvider.notifier).ensureLoaded(_filePath);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('EditorPanel save flow', () {
    testWidgets('updateBody flips isDirty on the buffer', (tester) async {
      final container = await _bootWithOpenTab(tester);
      final controller = container.read(editorBuffersProvider.notifier);

      controller.updateBody(_filePath, 'edited body');
      await tester.pump();

      final buffer = container.read(editorBuffersProvider)[_filePath]!;
      expect(buffer.isDirty, isTrue);
    });

    testWidgets('explicit save writes file + clears dirty', (tester) async {
      final container = await _bootWithOpenTab(tester);
      final controller = container.read(editorBuffersProvider.notifier);

      controller.updateBody(_filePath, 'edited body\n');
      await tester.pump();
      await controller.save(_filePath);
      await tester.pumpAndSettle();

      final buffer = container.read(editorBuffersProvider)[_filePath]!;
      expect(buffer.isDirty, isFalse);

      final fs = container.read(fileSystemProvider) as InMemoryFileSystem;
      final onDisk = await fs.readFileAsString(_filePath);
      expect(onDisk.contains('edited body'), isTrue);
    });

    testWidgets('frontmatter changes are persisted in original format',
        (tester) async {
      final container = await _bootWithOpenTab(tester);
      final controller = container.read(editorBuffersProvider.notifier);

      controller.updateEntryValue(_filePath, 'title', 'Renamed');
      controller.addEntry(_filePath, key: 'slug', value: 'renamed');
      await tester.pump();
      await controller.save(_filePath);
      await tester.pumpAndSettle();

      final fs = container.read(fileSystemProvider) as InMemoryFileSystem;
      final onDisk = await fs.readFileAsString(_filePath);
      // Original was YAML — must stay YAML.
      expect(onDisk.startsWith('---\n'), isTrue);
      expect(onDisk.contains('title: Renamed'), isTrue);
      expect(onDisk.contains('slug: renamed'), isTrue);
    });
  });
}
