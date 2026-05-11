import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/project/domain/workspace_state.dart';

void main() {
  group('PanelLayoutState', () {
    test('defaults: tree 280px, preview 360px, none collapsed', () {
      expect(PanelLayoutState.defaults.leftWidth, 280);
      expect(PanelLayoutState.defaults.rightWidth, 360);
      expect(PanelLayoutState.defaults.collapsed, [false, false, false]);
    });

    test('JSON round-trip preserves widths and collapsed flags', () {
      const state = PanelLayoutState(
        leftWidth: 320,
        rightWidth: 420,
        collapsed: [false, false, true],
      );
      final restored = PanelLayoutState.fromJson(
        Map<String, Object?>.from(state.toJson()),
      );
      expect(restored, state);
    });

    test('withCollapsed returns a new state with the flag flipped', () {
      const state = PanelLayoutState.defaults;
      final collapsed = state.withCollapsed(0, true);
      expect(collapsed.collapsed, [true, false, false]);
      expect(state.collapsed, [false, false, false]);
    });

    test('fromJson backfills defaults if fields are missing', () {
      final restored = PanelLayoutState.fromJson(const {});
      expect(restored.leftWidth, PanelLayoutState.defaultLeftWidth);
      expect(restored.rightWidth, PanelLayoutState.defaultRightWidth);
      expect(restored.collapsed, [false, false, false]);
    });

    test('fromJson recovers from malformed collapsed list length', () {
      final restored = PanelLayoutState.fromJson({
        'leftWidth': 200,
        'rightWidth': 200,
        'collapsed': [false, false],
      });
      expect(restored.collapsed, [false, false, false]);
    });
  });

  group('WorkspaceState', () {
    test('JSON round-trip preserves layout, expanded set, root mode', () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState(
          leftWidth: 240,
          rightWidth: 480,
          collapsed: [false, true, false],
        ),
        expandedFolders: {'/site/content', '/site/content/posts'},
        treeRootMode: TreeRootMode.projectRoot,
      );
      final restored = WorkspaceState.fromJson(
        Map<String, Object?>.from(state.toJson()),
      );
      expect(restored, state);
    });

    test('withFolderExpanded toggles a single folder', () {
      const state = WorkspaceState.defaults;
      final expanded = state.withFolderExpanded('/foo', true);
      expect(expanded.expandedFolders, contains('/foo'));
      final collapsed = expanded.withFolderExpanded('/foo', false);
      expect(collapsed.expandedFolders, isNot(contains('/foo')));
    });

    test('defaults: content root, no expanded folders', () {
      expect(
        WorkspaceState.defaults.treeRootMode,
        TreeRootMode.content,
      );
      expect(WorkspaceState.defaults.expandedFolders, isEmpty);
    });

    test('equality treats expanded set as unordered', () {
      const a = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: {'a', 'b', 'c'},
        treeRootMode: TreeRootMode.content,
      );
      const b = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: {'c', 'b', 'a'},
        treeRootMode: TreeRootMode.content,
      );
      expect(a, b);
    });
  });

  group('WorkspaceState tabs', () {
    test('defaults: empty open tabs and null active tab', () {
      expect(WorkspaceState.defaults.openTabs, isEmpty);
      expect(WorkspaceState.defaults.activeTabPath, isNull);
    });

    test('JSON round-trip preserves tabs and active tab', () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['content/about.md', 'content/posts/first-post.md'],
        activeTabPath: 'content/posts/first-post.md',
      );
      final restored = WorkspaceState.fromJson(
        Map<String, Object?>.from(state.toJson()),
      );
      expect(restored, state);
    });

    test('withTabOpened appends + activates a new tab', () {
      const state = WorkspaceState.defaults;
      final next = state.withTabOpened('content/foo.md');
      expect(next.openTabs, ['content/foo.md']);
      expect(next.activeTabPath, 'content/foo.md');
    });

    test('withTabOpened on an already-open tab just activates it', () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['a.md', 'b.md'],
        activeTabPath: 'a.md',
      );
      final next = state.withTabOpened('b.md');
      expect(next.openTabs, ['a.md', 'b.md']);
      expect(next.activeTabPath, 'b.md');
    });

    test('withTabClosed removes and falls back to the last remaining tab',
        () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['a.md', 'b.md', 'c.md'],
        activeTabPath: 'b.md',
      );
      final next = state.withTabClosed('b.md');
      expect(next.openTabs, ['a.md', 'c.md']);
      expect(next.activeTabPath, 'c.md');
    });

    test('withTabClosed clears active when the last tab is closed', () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['only.md'],
        activeTabPath: 'only.md',
      );
      final next = state.withTabClosed('only.md');
      expect(next.openTabs, isEmpty);
      expect(next.activeTabPath, isNull);
    });

    test('withTabClosed leaves active intact when closing a non-active tab',
        () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['a.md', 'b.md'],
        activeTabPath: 'a.md',
      );
      final next = state.withTabClosed('b.md');
      expect(next.openTabs, ['a.md']);
      expect(next.activeTabPath, 'a.md');
    });

    test('withActiveTab is a no-op for an unknown path', () {
      const state = WorkspaceState(
        panelLayout: PanelLayoutState.defaults,
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
        openTabs: ['a.md'],
        activeTabPath: 'a.md',
      );
      final next = state.withActiveTab('nope.md');
      expect(next, state);
    });
  });
}
