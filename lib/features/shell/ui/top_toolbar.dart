import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../editor/data/editor_buffers_controller.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';

class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lifecycle = ref.watch(projectControllerProvider);
    final projectName = switch (lifecycle) {
      OpenProject(:final project) => project.name,
      _ => '—',
    };

    final activeAbsolute = _resolveActivePath(ref, lifecycle);
    final isDirty = ref.watch(
      editorBuffersProvider.select(
        (m) => activeAbsolute != null
            ? m[activeAbsolute]?.isDirty ?? false
            : false,
      ),
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            projectName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          _Pill(label: l10n.toolbarBranchPlaceholder),
          const SizedBox(width: 8),
          _Pill(label: l10n.toolbarHugoStopped),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.save_outlined,
              size: 20,
              color: isDirty ? theme.colorScheme.primary : null,
            ),
            tooltip: isDirty
                ? l10n.toolbarSaveTooltip
                : l10n.toolbarSaveDisabledTooltip,
            onPressed: isDirty && activeAbsolute != null
                ? () {
                    // ignore: discarded_futures
                    ref
                        .read(editorBuffersProvider.notifier)
                        .save(activeAbsolute);
                  }
                : null,
          ),
          if (lifecycle is OpenProject)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: l10n.toolbarCloseProject,
              onPressed:
                  ref.read(projectControllerProvider.notifier).close,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: l10n.toolbarSettingsTooltip,
            onPressed: null,
          ),
        ],
      ),
    );
  }

  String? _resolveActivePath(WidgetRef ref, ProjectLifecycle lifecycle) {
    if (lifecycle is! OpenProject) return null;
    final workspace = ref.watch(workspaceStateProvider).value;
    final relative = workspace?.activeTabPath;
    if (relative == null) return null;
    return p.join(lifecycle.project.path, relative);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
