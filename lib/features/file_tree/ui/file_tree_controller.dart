import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';
import '../../../core/file_watcher.dart';
import '../../../core/providers.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../domain/file_tree_node.dart';
import '../domain/file_tree_view.dart';

/// Loads the file-tree view for the currently-open project, eagerly
/// pre-computing children for the root and every persisted expanded folder.
/// Subscribes to a [FileWatcher] for the root to refresh on external edits.
class FileTreeController extends AsyncNotifier<FileTreeView> {
  StreamSubscription<FsChange>? _watcherSub;
  Timer? _refreshDebounce;

  @override
  Future<FileTreeView> build() async {
    final lifecycle = ref.watch(projectControllerProvider);
    final workspace = await ref.watch(workspaceStateProvider.future);

    ref.onDispose(_disposeSubscriptions);

    if (lifecycle is! OpenProject) {
      _cancelSubscriptions();
      return FileTreeView.empty;
    }

    final rootPath = workspace.treeRootMode == TreeRootMode.content
        ? p.join(lifecycle.project.path, 'content')
        : lifecycle.project.path;

    final fs = ref.read(fileSystemProvider);
    final children = <String, List<FileTreeNode>>{};

    children[rootPath] = await _loadChildren(fs, rootPath);

    for (final expanded in workspace.expandedFolders) {
      if (!_isDescendantOrSame(expanded, rootPath)) continue;
      try {
        children[expanded] = await _loadChildren(fs, expanded);
      } on FileSystemException catch (_) {
        // Directory may have disappeared since last persist; skip silently.
      }
    }

    _attachWatcher(rootPath);

    // Tree selection is derived from the active editor tab. Whenever a
    // different tab becomes active (via the editor tab bar, the file tree
    // itself, or persistence restore), the tree highlight follows.
    final activeRelative = workspace.activeTabPath;
    final selectedAbsolute = activeRelative == null
        ? null
        : p.join(lifecycle.project.path, activeRelative);

    return FileTreeView(
      rootPath: rootPath,
      children: children,
      expandedFolders: workspace.expandedFolders,
      selectedPath: selectedAbsolute,
    );
  }

  Future<void> toggleFolder(String path) async {
    final view = state.value;
    if (view == null) return;
    final controller = ref.read(workspaceStateProvider.notifier);
    final isExpanded = view.expandedFolders.contains(path);
    await controller.setFolderExpanded(path, expanded: !isExpanded);
  }

  void selectPath(String? path) {
    final view = state.value;
    if (view == null) return;
    state = AsyncValue.data(
      view.copyWith(selectedPath: path, clearSelection: path == null),
    );
  }

  Future<List<FileTreeNode>> _loadChildren(FileSystem fs, String path) async {
    final entries = await fs.listDirectory(path);
    final nodes = entries
        .where((entry) => !p.basename(entry.path).startsWith('.'))
        .map(
          (entry) => FileTreeNode(
            path: entry.path,
            name: p.basename(entry.path),
            isDirectory: entry.isDirectory,
          ),
        )
        .toList()
      ..sort(FileTreeNode.compare);
    return List<FileTreeNode>.unmodifiable(nodes);
  }

  bool _isDescendantOrSame(String path, String root) {
    final n = p.normalize(path);
    final r = p.normalize(root);
    if (n == r) return true;
    return p.isWithin(r, n);
  }

  void _attachWatcher(String rootPath) {
    _cancelSubscriptions();
    final watcher = ref.read(fileWatcherProvider);
    _watcherSub = watcher.watch(rootPath).listen((_) {
      _scheduleRefresh();
    });
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 200),
      ref.invalidateSelf,
    );
  }

  void _cancelSubscriptions() {
    _watcherSub?.cancel();
    _watcherSub = null;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
  }

  void _disposeSubscriptions() {
    _cancelSubscriptions();
  }
}

final fileTreeProvider =
    AsyncNotifierProvider<FileTreeController, FileTreeView>(
  FileTreeController.new,
);
