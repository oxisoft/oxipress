import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/result.dart';
import '../../editor/data/editor_buffers_controller.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../domain/filename_template.dart';
import 'file_tree_mutations.dart';

/// Coordinates a file-tree mutation with the rest of the app: after a
/// successful rename/delete, open tabs and editor buffers are rewritten so
/// the user doesn't see stale paths pointing at non-existent files.
class FileTreeMutationsService {
  FileTreeMutationsService(this._ref);

  final Ref _ref;

  Future<Result<String, TreeMutationError>> createFile({
    required String parentDir,
    required String name,
    bool useTemplate = true,
  }) {
    final content = useTemplate
        ? defaultHugoTemplate(basename: name)
        : '';
    return _ref.read(fileTreeMutationsProvider).createFile(
          parentDir: parentDir,
          name: name,
          content: content,
        );
  }

  Future<Result<String, TreeMutationError>> createFolder({
    required String parentDir,
    required String name,
  }) {
    return _ref
        .read(fileTreeMutationsProvider)
        .createFolder(parentDir: parentDir, name: name);
  }

  Future<Result<String, TreeMutationError>> renameNode({
    required String absolutePath,
    required String newName,
  }) async {
    final result = await _ref
        .read(fileTreeMutationsProvider)
        .rename(absolutePath: absolutePath, newName: newName);
    if (result.isSuccess) {
      final newAbsolutePath = result.valueOrNull!;
      await _propagateRename(absolutePath, newAbsolutePath);
    }
    return result;
  }

  Future<Result<void, TreeMutationError>> delete({
    required String absolutePath,
  }) async {
    final result = await _ref
        .read(fileTreeMutationsProvider)
        .delete(absolutePath: absolutePath);
    if (result.isSuccess) {
      await _propagateDelete(absolutePath);
    }
    return result;
  }

  Future<Result<String, TreeMutationError>> duplicate({
    required String absolutePath,
  }) {
    return _ref
        .read(fileTreeMutationsProvider)
        .duplicate(absolutePath: absolutePath);
  }

  Future<void> _propagateRename(
    String oldAbsolutePath,
    String newAbsolutePath,
  ) async {
    final lifecycle = _ref.read(projectControllerProvider);
    if (lifecycle is! OpenProject) return;
    final projectPath = lifecycle.project.path;
    final workspace = _ref.read(workspaceStateProvider).value;
    if (workspace == null) return;

    final oldRel = p.relative(oldAbsolutePath, from: projectPath);
    final newRel = p.relative(newAbsolutePath, from: projectPath);

    String? rewriteRel(String tab) {
      if (tab == oldRel) return newRel;
      if (p.isWithin(oldRel, tab)) {
        final suffix = p.relative(tab, from: oldRel);
        return p.join(newRel, suffix);
      }
      return null;
    }

    final newTabs = workspace.openTabs.map((tab) {
      return rewriteRel(tab) ?? tab;
    }).toList(growable: false);

    final newActive = workspace.activeTabPath == null
        ? null
        : rewriteRel(workspace.activeTabPath!) ?? workspace.activeTabPath;

    final newExpanded = <String>{};
    for (final folder in workspace.expandedFolders) {
      if (folder == oldAbsolutePath) {
        newExpanded.add(newAbsolutePath);
      } else if (p.isWithin(oldAbsolutePath, folder)) {
        final suffix = p.relative(folder, from: oldAbsolutePath);
        newExpanded.add(p.join(newAbsolutePath, suffix));
      } else {
        newExpanded.add(folder);
      }
    }

    final notifier = _ref.read(workspaceStateProvider.notifier);
    await notifier.replaceTabs(openTabs: newTabs, activeTabPath: newActive);
    await notifier.replaceExpandedFolders(newExpanded);

    final buffers = _ref.read(editorBuffersProvider);
    final bufferNotifier = _ref.read(editorBuffersProvider.notifier);
    for (final key in buffers.keys.toList()) {
      if (key == oldAbsolutePath) {
        bufferNotifier.rekey(key, newAbsolutePath);
      } else if (p.isWithin(oldAbsolutePath, key)) {
        final suffix = p.relative(key, from: oldAbsolutePath);
        bufferNotifier.rekey(key, p.join(newAbsolutePath, suffix));
      }
    }
  }

  Future<void> _propagateDelete(String absolutePath) async {
    final lifecycle = _ref.read(projectControllerProvider);
    if (lifecycle is! OpenProject) return;
    final projectPath = lifecycle.project.path;
    final workspace = _ref.read(workspaceStateProvider).value;
    if (workspace == null) return;

    final relativePath = p.relative(absolutePath, from: projectPath);

    final remainingTabs = workspace.openTabs.where((tab) {
      return tab != relativePath && !p.isWithin(relativePath, tab);
    }).toList(growable: false);

    String? newActive = workspace.activeTabPath;
    if (newActive != null) {
      if (newActive == relativePath || p.isWithin(relativePath, newActive)) {
        newActive = remainingTabs.isEmpty ? null : remainingTabs.last;
      }
    }

    final newExpanded = workspace.expandedFolders.where((folder) {
      return folder != absolutePath && !p.isWithin(absolutePath, folder);
    }).toSet();

    final notifier = _ref.read(workspaceStateProvider.notifier);
    await notifier.replaceTabs(openTabs: remainingTabs, activeTabPath: newActive);
    await notifier.replaceExpandedFolders(newExpanded);

    final buffers = _ref.read(editorBuffersProvider);
    final bufferNotifier = _ref.read(editorBuffersProvider.notifier);
    for (final key in buffers.keys.toList()) {
      if (key == absolutePath || p.isWithin(absolutePath, key)) {
        bufferNotifier.close(key);
      }
    }
  }
}

final fileTreeMutationsServiceProvider = Provider<FileTreeMutationsService>(
  FileTreeMutationsService.new,
);
