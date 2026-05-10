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
}
