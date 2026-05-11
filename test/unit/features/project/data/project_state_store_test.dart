import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/features/project/data/project_state_store.dart';
import 'package:oxipress/features/project/domain/workspace_state.dart';
import 'package:path/path.dart' as p;

const _projectPath = '/sites/sample';

InMemoryFileSystem _fsWithProject() =>
    InMemoryFileSystem()..addDirectory(_projectPath);

void main() {
  group('ProjectStateStore', () {
    test('returns defaults when no .oxipress/workspace.json exists',
        () async {
      final store = ProjectStateStore(_fsWithProject());
      expect(await store.load(_projectPath), WorkspaceState.defaults);
    });

    test('save writes workspace.json + .gitignore inside .oxipress/',
        () async {
      final fs = _fsWithProject();
      final store = ProjectStateStore(fs);
      const state = WorkspaceState(
        panelLayout: PanelLayoutState(
          leftWidth: 320,
          rightWidth: 420,
          collapsed: [false, false, true],
        ),
        expandedFolders: {'/sites/sample/content/posts'},
        treeRootMode: TreeRootMode.projectRoot,
      );
      await store.save(_projectPath, state);

      final dir = p.join(_projectPath, '.oxipress');
      expect(await fs.directoryExists(dir), isTrue);
      expect(
        await fs.fileExists(p.join(dir, 'workspace.json')),
        isTrue,
      );
      expect(
        await fs.fileExists(p.join(dir, '.gitignore')),
        isTrue,
      );
      expect(
        await fs.readFileAsString(p.join(dir, '.gitignore')),
        '*\n',
      );
    });

    test('save+load round-trips workspace state', () async {
      final fs = _fsWithProject();
      final store = ProjectStateStore(fs);
      const state = WorkspaceState(
        panelLayout: PanelLayoutState(
          leftWidth: 320,
          rightWidth: 420,
          collapsed: [false, false, true],
        ),
        expandedFolders: {'/sites/sample/content/posts'},
        treeRootMode: TreeRootMode.projectRoot,
      );
      await store.save(_projectPath, state);
      expect(await store.load(_projectPath), state);
    });

    test('two projects keep independent state files', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory('/sites/a')
        ..addDirectory('/sites/b');
      final store = ProjectStateStore(fs);

      const stateA = WorkspaceState(
        panelLayout: PanelLayoutState(
          leftWidth: 200,
          rightWidth: 300,
          collapsed: [false, false, false],
        ),
        expandedFolders: <String>{},
        treeRootMode: TreeRootMode.content,
      );
      const stateB = WorkspaceState(
        panelLayout: PanelLayoutState(
          leftWidth: 380,
          rightWidth: 500,
          collapsed: [true, false, false],
        ),
        expandedFolders: {'/sites/b/content/posts'},
        treeRootMode: TreeRootMode.projectRoot,
      );

      await store.save('/sites/a', stateA);
      await store.save('/sites/b', stateB);

      expect(await store.load('/sites/a'), stateA);
      expect(await store.load('/sites/b'), stateB);
    });

    test('clear removes the workspace.json file', () async {
      final fs = _fsWithProject();
      final store = ProjectStateStore(fs);
      await store.save(_projectPath, WorkspaceState.defaults);
      await store.clear(_projectPath);
      final wsPath =
          p.join(_projectPath, '.oxipress', 'workspace.json');
      expect(await fs.fileExists(wsPath), isFalse);
      expect(await store.load(_projectPath), WorkspaceState.defaults);
    });

    test('returns defaults when workspace.json contains malformed JSON',
        () async {
      final fs = _fsWithProject();
      final store = ProjectStateStore(fs);
      final wsPath =
          p.join(_projectPath, '.oxipress', 'workspace.json');
      fs.addFile(wsPath, content: '{not-json');
      expect(await store.load(_projectPath), WorkspaceState.defaults);
    });
  });
}
