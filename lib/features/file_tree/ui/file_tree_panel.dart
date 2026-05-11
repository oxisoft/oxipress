import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../editor/data/editor_buffers_controller.dart';
import '../../editor/domain/editor_buffer.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/file_tree_mutations.dart';
import '../data/file_tree_mutations_service.dart';
import '../domain/file_tree_node.dart';
import '../domain/file_tree_view.dart';
import '../domain/path_policy.dart';
import 'file_tree_controller.dart';
import 'tree_dialogs.dart';

class FileTreePanel extends ConsumerWidget {
  const FileTreePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final viewAsync = ref.watch(fileTreeProvider);

    return viewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(message: '$error'),
      data: (view) {
        if (view.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.treeNoProject,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        return _TreeListView(view: view);
      },
    );
  }
}

class FileTreeRootToggle extends ConsumerWidget {
  const FileTreeRootToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref.watch(workspaceStateProvider);
    return workspace.when(
      data: (state) {
        final isContent = state.treeRootMode == TreeRootMode.content;
        return IconButton(
          icon: Icon(
            isContent ? Icons.folder_special_outlined : Icons.folder_outlined,
            size: 18,
          ),
          tooltip: isContent ? l10n.treeRootProjectRoot : l10n.treeRootContent,
          visualDensity: VisualDensity.compact,
          onPressed: () => ref
              .read(workspaceStateProvider.notifier)
              .setTreeRootMode(
                isContent ? TreeRootMode.projectRoot : TreeRootMode.content,
              ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _TreeListView extends ConsumerStatefulWidget {
  const _TreeListView({required this.view});

  final FileTreeView view;

  @override
  ConsumerState<_TreeListView> createState() => _TreeListViewState();
}

class _TreeListViewState extends ConsumerState<_TreeListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(widget.view);
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.treeEmpty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: rows.length,
        itemExtent: 26,
        itemBuilder: (context, index) {
          final row = rows[index];
          return _TreeRow(row: row, view: widget.view);
        },
      ),
    );
  }

  List<_Row> _flatten(FileTreeView view) {
    final rows = <_Row>[];
    void walk(String parentPath, int depth) {
      final children = view.children[parentPath] ?? const [];
      for (final node in children) {
        rows.add(_Row(node: node, depth: depth));
        if (node.isDirectory && view.expandedFolders.contains(node.path)) {
          walk(node.path, depth + 1);
        }
      }
    }

    walk(view.rootPath, 0);
    return rows;
  }
}

class _Row {
  const _Row({required this.node, required this.depth});

  final FileTreeNode node;
  final int depth;
}

enum _TreeAction {
  newFile,
  newFolder,
  open,
  rename,
  duplicate,
  delete,
  reveal,
}

class _TreeRow extends ConsumerWidget {
  const _TreeRow({required this.row, required this.view});

  final _Row row;
  final FileTreeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSelected = view.selectedPath == row.node.path;
    final isExpanded = row.node.isDirectory &&
        view.expandedFolders.contains(row.node.path);

    return Builder(
      builder: (rowContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) {
            unawaited(
              _showContextMenu(rowContext, ref, details.globalPosition),
            );
          },
          child: Material(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _onTap(ref),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0 + row.depth * 14,
                  right: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(row.node, isExpanded),
                      size: 16,
                      color: row.node.isDirectory
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _buildLabel(ref),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildLabel(WidgetRef ref) {
    if (row.node.isDirectory) return row.node.name;
    final isDirty = ref.watch(
      editorBuffersProvider.select<bool>(
        (Map<String, EditorBuffer> m) =>
            m[row.node.path]?.isDirty ?? false,
      ),
    );
    return isDirty ? '* ${row.node.name}' : row.node.name;
  }

  void _onTap(WidgetRef ref) {
    if (row.node.isDirectory) {
      ref.read(fileTreeProvider.notifier).toggleFolder(row.node.path);
      return;
    }

    final lifecycle = ref.read(projectControllerProvider);
    if (lifecycle is! OpenProject) return;

    if (row.node.isMarkdown) {
      // Opening a tab updates workspace.activeTabPath, which the file-tree
      // controller mirrors into its selection on the next rebuild.
      final relative =
          p.relative(row.node.path, from: lifecycle.project.path);
      ref.read(workspaceStateProvider.notifier).openTab(relative);
    } else {
      // Fire-and-forget; OsOpener failures are logged at the layer that
      // surfaces them. Non-markdown files do not affect tree selection.
      // ignore: unawaited_futures, discarded_futures
      ref.read(osOpenerProvider).open(row.node.path);
    }
  }

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final lifecycle = ref.read(projectControllerProvider);
    final workspace = ref.read(workspaceStateProvider).value;
    final isFile = !row.node.isDirectory;
    final isProjectRoot =
        workspace?.treeRootMode == TreeRootMode.projectRoot;
    final restricted = isProjectRoot &&
        lifecycle is OpenProject &&
        !isWriteAllowed(
          projectPath: lifecycle.project.path,
          absolutePath: row.node.path,
        );

    final action = await showMenu<_TreeAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: [
        if (isFile)
          PopupMenuItem(
            value: _TreeAction.open,
            child: Text(l10n.treeMenuOpen),
          )
        else ...[
          PopupMenuItem(
            value: _TreeAction.newFile,
            enabled: !restricted,
            child: Text(l10n.treeMenuNewFile),
          ),
          PopupMenuItem(
            value: _TreeAction.newFolder,
            enabled: !restricted,
            child: Text(l10n.treeMenuNewFolder),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _TreeAction.rename,
          enabled: !restricted,
          child: Text(l10n.treeMenuRename),
        ),
        if (isFile)
          PopupMenuItem(
            value: _TreeAction.duplicate,
            enabled: !restricted,
            child: Text(l10n.treeMenuDuplicate),
          ),
        PopupMenuItem(
          value: _TreeAction.delete,
          enabled: !restricted,
          child: Text(l10n.treeMenuDelete),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _TreeAction.reveal,
          child: Text(l10n.treeMenuReveal),
        ),
      ],
    );

    if (action == null) return;
    if (!context.mounted) return;
    await _handleAction(context, ref, action);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _TreeAction action,
  ) async {
    switch (action) {
      case _TreeAction.open:
        _onTap(ref);
      case _TreeAction.reveal:
        await ref.read(revealInFileManagerProvider).reveal(row.node.path);
      case _TreeAction.newFile:
        await _handleNewFile(context, ref);
      case _TreeAction.newFolder:
        await _handleNewFolder(context, ref);
      case _TreeAction.rename:
        await _handleRename(context, ref);
      case _TreeAction.duplicate:
        await _handleDuplicate(context, ref);
      case _TreeAction.delete:
        await _handleDelete(context, ref);
    }
  }

  Future<void> _handleNewFile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showNewFileDialog(context);
    if (result == null) return;
    final outcome = await ref
        .read(fileTreeMutationsServiceProvider)
        .createFile(
          parentDir: row.node.path,
          name: result.name,
          useTemplate: result.useTemplate,
        );
    if (!context.mounted) return;
    outcome.fold(
      (newPath) => _openFileAfterCreate(ref, newPath),
      (error) => _showError(context, ref, error),
    );
    // Make sure the folder is expanded so the new file is visible.
    unawaited(
      ref
          .read(workspaceStateProvider.notifier)
          .setFolderExpanded(row.node.path, expanded: true),
    );
  }

  Future<void> _handleNewFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await showNewFolderDialog(context);
    if (name == null) return;
    final outcome = await ref
        .read(fileTreeMutationsServiceProvider)
        .createFolder(parentDir: row.node.path, name: name);
    if (!context.mounted) return;
    outcome.fold(
      (_) {},
      (error) => _showError(context, ref, error),
    );
    unawaited(
      ref
          .read(workspaceStateProvider.notifier)
          .setFolderExpanded(row.node.path, expanded: true),
    );
  }

  Future<void> _handleRename(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newName =
        await showRenameDialog(context, currentName: row.node.name);
    if (newName == null || newName == row.node.name) return;
    final outcome = await ref
        .read(fileTreeMutationsServiceProvider)
        .renameNode(absolutePath: row.node.path, newName: newName);
    if (!context.mounted) return;
    outcome.fold(
      (_) {},
      (error) => _showError(context, ref, error),
    );
  }

  Future<void> _handleDuplicate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final outcome = await ref
        .read(fileTreeMutationsServiceProvider)
        .duplicate(absolutePath: row.node.path);
    if (!context.mounted) return;
    outcome.fold(
      (_) {},
      (error) => _showError(context, ref, error),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDeleteConfirm(
      context,
      name: row.node.name,
      isDirectory: row.node.isDirectory,
    );
    if (!confirm) return;
    if (!context.mounted) return;
    final outcome = await ref
        .read(fileTreeMutationsServiceProvider)
        .delete(absolutePath: row.node.path);
    if (!context.mounted) return;
    outcome.fold(
      (_) {},
      (error) => _showError(context, ref, error),
    );
  }

  void _openFileAfterCreate(WidgetRef ref, String absolutePath) {
    final lifecycle = ref.read(projectControllerProvider);
    if (lifecycle is! OpenProject) return;
    final relative =
        p.relative(absolutePath, from: lifecycle.project.path);
    ref.read(workspaceStateProvider.notifier).openTab(relative);
  }

  void _showError(
    BuildContext context,
    WidgetRef ref,
    TreeMutationError error,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (error) {
      AlreadyExistsError() => l10n.mutationErrorAlreadyExists,
      InvalidNameError() => l10n.mutationErrorInvalidName,
      NotFoundError() => l10n.mutationErrorNotFound,
      IoError(:final detail) => l10n.mutationErrorGeneric(detail),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  IconData _iconFor(FileTreeNode node, bool expanded) {
    if (node.isDirectory) {
      return expanded ? Icons.folder_open : Icons.folder;
    }
    if (node.isMarkdown) return Icons.article_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
