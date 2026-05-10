import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/file_tree/ui/file_tree_controller.dart';
import 'package:oxipress/features/file_tree/ui/file_tree_panel.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';

import '../../../helpers/pump_app.dart';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile('/sites/sample/hugo.toml')
    ..addDirectory('/sites/sample/content')
    ..addFile('/sites/sample/content/about.md')
    ..addFile('/sites/sample/content/_index.md')
    ..addDirectory('/sites/sample/content/posts')
    ..addFile('/sites/sample/content/posts/first-post.md')
    ..addFile('/sites/sample/content/posts/second-post.md')
    ..addDirectory('/sites/sample/content/docs')
    ..addFile('/sites/sample/content/docs/getting-started.md');
}

Future<ProviderContainer> _bootWithSampleSite(WidgetTester tester) async {
  final fs = _hugoSite();
  final container = await pumpAppWith(
    tester,
    const Scaffold(body: FileTreePanel()),
    overrides: [
      storageProvider.overrideWithValue(InMemoryStorage()),
      fileSystemProvider.overrideWithValue(fs),
      fileWatcherProvider.overrideWithValue(FakeFileWatcher()),
    ],
  );
  await container
      .read(projectControllerProvider.notifier)
      .openProject('/sites/sample');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('FileTreePanel', () {
    testWidgets('renders the content/ root with directories first',
        (tester) async {
      await _bootWithSampleSite(tester);

      expect(find.text('docs'), findsOneWidget);
      expect(find.text('posts'), findsOneWidget);
      expect(find.text('about.md'), findsOneWidget);
      expect(find.text('_index.md'), findsOneWidget);

      // Unexpanded folders' children are hidden.
      expect(find.text('first-post.md'), findsNothing);
    });

    testWidgets('tapping a folder expands it and shows children',
        (tester) async {
      await _bootWithSampleSite(tester);

      await tester.tap(find.text('posts'));
      await tester.pumpAndSettle();

      expect(find.text('first-post.md'), findsOneWidget);
      expect(find.text('second-post.md'), findsOneWidget);
      // Sibling folder still collapsed.
      expect(find.text('getting-started.md'), findsNothing);
    });

    testWidgets('expansion survives an external refresh', (tester) async {
      final container = await _bootWithSampleSite(tester);

      await tester.tap(find.text('posts'));
      await tester.pumpAndSettle();
      expect(find.text('first-post.md'), findsOneWidget);

      // Simulate the watcher firing a change → controller rebuild.
      container.invalidate(fileTreeProvider);
      await tester.pumpAndSettle();

      // Expansion is persisted in workspace state, so children remain.
      expect(find.text('first-post.md'), findsOneWidget);
    });
  });
}
