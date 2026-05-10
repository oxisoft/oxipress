import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/editor/data/frontmatter_visibility.dart';
import 'package:oxipress/features/editor/ui/editor_panel.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';
import 'package:oxipress/features/project/ui/workspace_state_controller.dart';

import '../../../helpers/pump_app.dart';

const _projectPath = '/sites/sample';
const _firstPostBody = '''
---
title: First post
draft: false
tags: ["intro", "hugo"]
---

This is the body of the first post.
''';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile('$_projectPath/hugo.toml')
    ..addDirectory('$_projectPath/content')
    ..addFile('$_projectPath/content/about.md',
        content: '---\ntitle: About\n---\nAbout body.\n')
    ..addFile(
      '$_projectPath/content/posts/first-post.md',
      content: _firstPostBody,
    );
}

Future<ProviderContainer> _bootProject(WidgetTester tester) async {
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
  // Tests assert on frontmatter content; expand the section since it's
  // collapsed by default in the production UI.
  container
      .read(frontmatterVisibilityProvider.notifier)
      .setExpanded(expanded: true);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('EditorPanel', () {
    testWidgets('shows the placeholder when no tabs are open',
        (tester) async {
      await _bootProject(tester);
      expect(
        find.text('Open a markdown file from the tree.'),
        findsOneWidget,
      );
    });

    testWidgets('renders frontmatter + body for the active tab',
        (tester) async {
      final container = await _bootProject(tester);

      await container
          .read(workspaceStateProvider.notifier)
          .openTab('content/posts/first-post.md');
      await tester.pumpAndSettle();

      // Frontmatter row keys
      expect(find.text('title'), findsOneWidget);
      expect(find.text('draft'), findsOneWidget);
      expect(find.text('tags'), findsOneWidget);
      // Frontmatter values
      expect(find.text('First post'), findsOneWidget);
      // Body
      expect(
        find.textContaining('This is the body of the first post.'),
        findsOneWidget,
      );
    });

    testWidgets('switching tabs re-renders the active document',
        (tester) async {
      final container = await _bootProject(tester);
      final notifier = container.read(workspaceStateProvider.notifier);

      await notifier.openTab('content/posts/first-post.md');
      await notifier.openTab('content/about.md');
      await tester.pumpAndSettle();

      // The about page becomes active after the second openTab.
      expect(find.text('About'), findsOneWidget);

      await notifier.setActiveTab('content/posts/first-post.md');
      await tester.pumpAndSettle();
      expect(find.text('First post'), findsOneWidget);
    });

    testWidgets('closing the active tab activates the previous one',
        (tester) async {
      final container = await _bootProject(tester);
      final notifier = container.read(workspaceStateProvider.notifier);

      await notifier.openTab('content/about.md');
      await notifier.openTab('content/posts/first-post.md');
      await tester.pumpAndSettle();

      await notifier.closeTab('content/posts/first-post.md');
      await tester.pumpAndSettle();

      expect(
        container.read(workspaceStateProvider).value!.activeTabPath,
        'content/about.md',
      );
      expect(find.text('About'), findsOneWidget);
    });
  });
}
