import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/editor_buffers_controller.dart';
import '../data/find_replace_controller.dart';
import '../data/frontmatter_visibility.dart';
import 'close_tab_action.dart';
import 'editable_frontmatter_view.dart';
import 'editor_tab_bar.dart';
import 'find_replace_bar.dart';
import 'raw_markdown_editor.dart';

class EditorPanel extends ConsumerWidget {
  const EditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lifecycle = ref.watch(projectControllerProvider);
    if (lifecycle is! OpenProject) {
      return _Placeholder(text: l10n.editorPlaceholder);
    }

    final workspaceAsync = ref.watch(workspaceStateProvider);
    return workspaceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (workspace) {
        if (workspace.openTabs.isEmpty) {
          return _Placeholder(text: l10n.editorPlaceholder);
        }
        final active = workspace.activeTabPath ?? workspace.openTabs.last;
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyW, meta: true):
                _CloseActiveTabIntent(),
            SingleActivator(LogicalKeyboardKey.keyW, control: true):
                _CloseActiveTabIntent(),
            SingleActivator(LogicalKeyboardKey.keyS, meta: true):
                _SaveActiveTabIntent(),
            SingleActivator(LogicalKeyboardKey.keyS, control: true):
                _SaveActiveTabIntent(),
            SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                _OpenFindIntent(),
            SingleActivator(LogicalKeyboardKey.keyF, control: true):
                _OpenFindIntent(),
            SingleActivator(LogicalKeyboardKey.keyH, meta: true):
                _OpenReplaceIntent(),
            SingleActivator(LogicalKeyboardKey.keyH, control: true):
                _OpenReplaceIntent(),
            SingleActivator(LogicalKeyboardKey.escape):
                _CloseFindIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CloseActiveTabIntent: CallbackAction<_CloseActiveTabIntent>(
                onInvoke: (_) {
                  // ignore: discarded_futures
                  closeTabWithConfirm(
                    context: context,
                    ref: ref,
                    relativePath: active,
                  );
                  return null;
                },
              ),
              _SaveActiveTabIntent: CallbackAction<_SaveActiveTabIntent>(
                onInvoke: (_) {
                  final absolute = p.join(lifecycle.project.path, active);
                  // ignore: discarded_futures
                  ref
                      .read(editorBuffersProvider.notifier)
                      .save(absolute);
                  return null;
                },
              ),
              _OpenFindIntent: CallbackAction<_OpenFindIntent>(
                onInvoke: (_) {
                  ref.read(findReplaceProvider.notifier).open();
                  return null;
                },
              ),
              _OpenReplaceIntent: CallbackAction<_OpenReplaceIntent>(
                onInvoke: (_) {
                  ref
                      .read(findReplaceProvider.notifier)
                      .open(replace: true);
                  return null;
                },
              ),
              _CloseFindIntent: CallbackAction<_CloseFindIntent>(
                onInvoke: (_) {
                  final state = ref.read(findReplaceProvider);
                  if (state.visible) {
                    ref.read(findReplaceProvider.notifier).close();
                  }
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  const EditorTabBar(),
                  FindReplaceBar(
                    absolutePath:
                        p.join(lifecycle.project.path, active),
                  ),
                  Expanded(
                    child: _ActiveTabContent(
                      relativePath: active,
                      projectPath: lifecycle.project.path,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CloseActiveTabIntent extends Intent {
  const _CloseActiveTabIntent();
}

class _SaveActiveTabIntent extends Intent {
  const _SaveActiveTabIntent();
}

class _OpenFindIntent extends Intent {
  const _OpenFindIntent();
}

class _OpenReplaceIntent extends Intent {
  const _OpenReplaceIntent();
}

class _CloseFindIntent extends Intent {
  const _CloseFindIntent();
}

class _ActiveTabContent extends ConsumerWidget {
  const _ActiveTabContent({
    required this.relativePath,
    required this.projectPath,
  });

  final String relativePath;
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absolutePath = p.join(projectPath, relativePath);
    final loadAsync = ref.watch(editorBufferProvider(absolutePath));

    return loadAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(message: '$error'),
      data: (_) => _DocumentView(absolutePath: absolutePath),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.absolutePath});

  final String absolutePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FrontmatterSection(absolutePath: absolutePath),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        Expanded(
          child: RawMarkdownEditor(absolutePath: absolutePath),
        ),
      ],
    );
  }
}

class _FrontmatterSection extends ConsumerWidget {
  const _FrontmatterSection({required this.absolutePath});

  final String absolutePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final expanded = ref.watch(frontmatterVisibilityProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: ref.read(frontmatterVisibilityProvider.notifier).toggle,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.frontmatterSectionTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: expanded
                      ? l10n.frontmatterCollapse
                      : l10n.frontmatterExpand,
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: EditableFrontmatterView(absolutePath: absolutePath),
            ),
          ),
      ],
    );
  }
}

/// Compact Raw / Rich mode chip-pair for the editor panel's header actions
/// slot. Rich mode is disabled until Phase 9; this is a stub that conveys
/// the affordance without consuming a vertical row in the editor body.
class EditorModeToggle extends StatelessWidget {
  const EditorModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Tooltip(
      message: l10n.editorModeRichComingSoon,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeChip(
              icon: Icons.code,
              label: l10n.editorModeRaw,
              selected: true,
            ),
            _ModeChip(
              icon: Icons.text_fields,
              label: l10n.editorModeRich,
              selected: false,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.onPrimaryContainer
        : (enabled
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
