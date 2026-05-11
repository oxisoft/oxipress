import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/editor/data/editor_buffers_controller.dart';
import 'package:oxipress/features/file_tree/data/file_tree_mutations_service.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';
import 'package:oxipress/features/project/ui/workspace_state_controller.dart';

const _projectPath = '/sites/sample';
const _firstPostRel = 'content/posts/first.md';
const _firstPostAbs = '$_projectPath/$_firstPostRel';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile('$_projectPath/hugo.toml')
    ..addDirectory('$_projectPath/content')
    ..addDirectory('$_projectPath/content/posts')
    ..addFile(_firstPostAbs, content: '---\ntitle: First\n---\nBody.\n');
}

Future<ProviderContainer> _container(InMemoryFileSystem fs) async {
  final container = ProviderContainer(
    overrides: <Override>[
      storageProvider.overrideWithValue(InMemoryStorage()),
      fileSystemProvider.overrideWithValue(fs),
      fileWatcherProvider.overrideWithValue(FakeFileWatcher()),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(projectControllerProvider.notifier)
      .openProject(_projectPath);
  await container.read(workspaceStateProvider.future);
  return container;
}

void main() {
  group('FileTreeMutationsService', () {
    test('createFile inserts a Hugo template + new file appears on disk',
        () async {
      final fs = _hugoSite();
      final container = await _container(fs);
      final service =
          container.read(fileTreeMutationsServiceProvider);

      final result = await service.createFile(
        parentDir: '$_projectPath/content/posts',
        name: 'second.md',
      );
      expect(result.isSuccess, isTrue);
      const newPath = '$_projectPath/content/posts/second.md';
      expect(await fs.fileExists(newPath), isTrue);
      final body = await fs.readFileAsString(newPath);
      expect(body.contains('title: "Second"'), isTrue);
      expect(body.contains('draft: true'), isTrue);
    });

    test('rename rewrites an open tab + rekeys the editor buffer',
        () async {
      final fs = _hugoSite();
      final container = await _container(fs);
      // Open the file as a tab + ensure buffer loaded.
      await container
          .read(workspaceStateProvider.notifier)
          .openTab(_firstPostRel);
      await container
          .read(editorBuffersProvider.notifier)
          .ensureLoaded(_firstPostAbs);

      final service =
          container.read(fileTreeMutationsServiceProvider);
      final result = await service.renameNode(
        absolutePath: _firstPostAbs,
        newName: 'renamed.md',
      );
      expect(result.isSuccess, isTrue);

      const newRel = 'content/posts/renamed.md';
      const newAbs = '$_projectPath/$newRel';

      final workspace =
          container.read(workspaceStateProvider).value!;
      expect(workspace.openTabs, contains(newRel));
      expect(workspace.openTabs, isNot(contains(_firstPostRel)));
      expect(workspace.activeTabPath, newRel);

      final buffers = container.read(editorBuffersProvider);
      expect(buffers.containsKey(newAbs), isTrue);
      expect(buffers.containsKey(_firstPostAbs), isFalse);
    });

    test('renaming a folder cascades to descendants', () async {
      final fs = _hugoSite();
      final container = await _container(fs);
      await container
          .read(workspaceStateProvider.notifier)
          .openTab(_firstPostRel);

      final service =
          container.read(fileTreeMutationsServiceProvider);
      final result = await service.renameNode(
        absolutePath: '$_projectPath/content/posts',
        newName: 'articles',
      );
      expect(result.isSuccess, isTrue);

      final workspace =
          container.read(workspaceStateProvider).value!;
      expect(
        workspace.openTabs,
        contains('content/articles/first.md'),
      );
    });

    test('delete closes open tabs + drops buffers below the deleted path',
        () async {
      final fs = _hugoSite();
      final container = await _container(fs);
      await container
          .read(workspaceStateProvider.notifier)
          .openTab(_firstPostRel);
      await container
          .read(editorBuffersProvider.notifier)
          .ensureLoaded(_firstPostAbs);

      final service =
          container.read(fileTreeMutationsServiceProvider);
      final result = await service.delete(
        absolutePath: '$_projectPath/content/posts',
      );
      expect(result.isSuccess, isTrue);

      final workspace =
          container.read(workspaceStateProvider).value!;
      expect(workspace.openTabs, isEmpty);
      expect(workspace.activeTabPath, isNull);

      final buffers = container.read(editorBuffersProvider);
      expect(buffers.containsKey(_firstPostAbs), isFalse);
    });

    test('duplicate creates a -copy sibling without opening a tab',
        () async {
      final fs = _hugoSite();
      final container = await _container(fs);

      final service =
          container.read(fileTreeMutationsServiceProvider);
      final result = await service.duplicate(absolutePath: _firstPostAbs);
      expect(result.isSuccess, isTrue);
      expect(
        result.valueOrNull,
        '$_projectPath/content/posts/first-copy.md',
      );
      expect(await fs.fileExists(result.valueOrNull!), isTrue);

      // No tab was opened.
      expect(
        container.read(workspaceStateProvider).value!.openTabs,
        isEmpty,
      );
    });
  });
}
