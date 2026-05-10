import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger.dart';
import '../data/project_providers.dart';
import '../domain/workspace_state.dart';
import 'project_controller.dart';

/// Holds the persisted [WorkspaceState] for the currently-open project.
/// Rebuilds when the open project changes; persists on every mutation
/// (debounced by 250 ms).
class WorkspaceStateController extends AsyncNotifier<WorkspaceState> {
  String? _projectPath;
  Timer? _saveTimer;
  final AppLogger _log = AppLogger('workspace_state');

  @override
  Future<WorkspaceState> build() async {
    final lifecycle = ref.watch(projectControllerProvider);
    if (lifecycle is! OpenProject) {
      _projectPath = null;
      _saveTimer?.cancel();
      return WorkspaceState.defaults;
    }
    _projectPath = lifecycle.project.path;

    ref.onDispose(() {
      _saveTimer?.cancel();
    });

    final store = ref.read(projectStateStoreProvider);
    return store.load(lifecycle.project.path);
  }

  Future<void> setLeftWidth(double width) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      panelLayout: current.panelLayout.copyWith(leftWidth: width),
    );
    state = AsyncValue.data(next);
    _scheduleSave(next);
  }

  Future<void> setRightWidth(double width) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      panelLayout: current.panelLayout.copyWith(rightWidth: width),
    );
    state = AsyncValue.data(next);
    _scheduleSave(next);
  }

  Future<void> setPanelCollapsed(int index, {required bool collapsed}) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      panelLayout: current.panelLayout.withCollapsed(index, collapsed),
    );
    state = AsyncValue.data(next);
    _scheduleSave(next);
  }

  Future<void> setFolderExpanded(
    String path, {
    required bool expanded,
  }) async {
    final current = state.value;
    if (current == null) return;
    final next = current.withFolderExpanded(path, expanded);
    state = AsyncValue.data(next);
    _scheduleSave(next);
  }

  Future<void> setTreeRootMode(TreeRootMode mode) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(treeRootMode: mode);
    state = AsyncValue.data(next);
    _scheduleSave(next);
  }

  void _scheduleSave(WorkspaceState pending) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persistNow(pending));
    });
  }

  Future<void> _persistNow(WorkspaceState pending) async {
    final path = _projectPath;
    if (path == null) return;
    final store = ref.read(projectStateStoreProvider);
    try {
      await store.save(path, pending);
    } on Object catch (error, stackTrace) {
      // Persistence failures (sandbox denial, read-only filesystem, disk
      // full) must not crash the app or wedge the controller. The in-memory
      // state stays current; we just log and move on.
      _log.warn(
        'failed to persist workspace state',
        fields: {'path': path, 'error': error.toString()},
      );
      _log.error('persist stack', error: error, stackTrace: stackTrace);
    }
  }
}

final workspaceStateProvider =
    AsyncNotifierProvider<WorkspaceStateController, WorkspaceState>(
  WorkspaceStateController.new,
);
