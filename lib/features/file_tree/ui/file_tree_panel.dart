import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../domain/file_tree_node.dart';
import '../domain/file_tree_view.dart';
import 'file_tree_controller.dart';

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

    return Material(
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
                  row.node.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
