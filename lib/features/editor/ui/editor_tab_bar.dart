import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/editor_buffers_controller.dart';
import 'close_tab_action.dart';

/// Horizontal scrolling tab bar showing every open editor tab. The active
/// tab is highlighted; clicking switches; the x button or middle-click
/// closes (with a save-prompt when the buffer is dirty). A pinned overflow
/// button at the right opens a vertical popup listing every open tab.
class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceStateProvider);
    final workspace = workspaceAsync.value;
    if (workspace == null || workspace.openTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tabPath in workspace.openTabs)
                    _TabButton(
                      relativePath: tabPath,
                      isActive: tabPath == workspace.activeTabPath,
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          _TabListMenuButton(workspace: workspace),
        ],
      ),
    );
  }
}

class _TabListMenuButton extends ConsumerWidget {
  const _TabListMenuButton({required this.workspace});

  final WorkspaceState workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.editorTabListTooltip,
      icon: Icon(
        Icons.list,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      onSelected: (path) {
        ref.read(workspaceStateProvider.notifier).setActiveTab(path);
      },
      itemBuilder: (context) => [
        for (final path in workspace.openTabs)
          PopupMenuItem<String>(
            value: path,
            child: _TabListEntry(
              path: path,
              isActive: path == workspace.activeTabPath,
            ),
          ),
      ],
    );
  }
}

class _TabListEntry extends ConsumerWidget {
  const _TabListEntry({required this.path, required this.isActive});

  final String path;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fileName = p.basename(path);
    final dirPath = p.dirname(path);
    final showDir = dirPath.isNotEmpty && dirPath != '.';

    final lifecycle = ref.watch(projectControllerProvider);
    final absolute = lifecycle is OpenProject
        ? p.join(lifecycle.project.path, path)
        : null;
    final isDirty = ref.watch(
      editorBuffersProvider.select(
        (m) => absolute != null
            ? m[absolute]?.isDirty ?? false
            : false,
      ),
    );

    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(
          Icons.article_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDirty ? '* $fileName' : fileName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (showDir)
                Text(
                  dirPath,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.check,
            size: 14,
            color: theme.colorScheme.primary,
          ),
        ],
      ],
    );
  }
}

class _TabButton extends ConsumerWidget {
  const _TabButton({required this.relativePath, required this.isActive});

  final String relativePath;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fileName = p.basename(relativePath);
    final color = isActive
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerLow;
    final foreground = isActive
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    final lifecycle = ref.watch(projectControllerProvider);
    final absolute = lifecycle is OpenProject
        ? p.join(lifecycle.project.path, relativePath)
        : null;
    final isDirty = ref.watch(
      editorBuffersProvider.select(
        (m) => absolute != null
            ? m[absolute]?.isDirty ?? false
            : false,
      ),
    );

    return Builder(
      builder: (rowContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTertiaryTapDown: (_) => _close(rowContext, ref),
          child: Material(
            color: color,
            child: InkWell(
              onTap: () => ref
                  .read(workspaceStateProvider.notifier)
                  .setActiveTab(relativePath),
              child: Container(
                constraints: const BoxConstraints(minWidth: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    bottom: BorderSide(
                      color: isActive
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDirty ? '* $fileName' : fileName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _close(rowContext, ref),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: foreground,
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

  void _close(BuildContext context, WidgetRef ref) {
    unawaited(
      closeTabWithConfirm(
        context: context,
        ref: ref,
        relativePath: relativePath,
      ),
    );
  }
}
