import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../editor/data/editor_buffers_controller.dart';
import '../../hugo_process/data/hugo_providers.dart';
import '../../hugo_process/domain/hugo_status.dart';
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
          if (lifecycle is OpenProject)
            const _HugoStatusBadge()
          else
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

class _HugoStatusBadge extends ConsumerWidget {
  const _HugoStatusBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = ref.watch(hugoControllerProvider);
    final controller = ref.read(hugoControllerProvider.notifier);

    final (label, color, icon, tooltip, onTap) = switch (status) {
      HugoStopped() => (
          l10n.hugoStatusStopped,
          theme.colorScheme.onSurfaceVariant,
          Icons.play_arrow,
          l10n.hugoActionStart,
          () => unawaited(controller.start()),
        ),
      HugoStarting() => (
          l10n.hugoStatusStarting,
          theme.colorScheme.tertiary,
          Icons.cached,
          l10n.hugoActionStop,
          () => unawaited(controller.stop()),
        ),
      HugoRunning(:final port) => (
          l10n.hugoStatusRunning(port),
          Colors.green.shade600,
          Icons.stop_circle_outlined,
          l10n.hugoActionStop,
          () => unawaited(controller.stop()),
        ),
      HugoErrored() => (
          l10n.hugoStatusError,
          theme.colorScheme.error,
          Icons.refresh,
          l10n.hugoActionRestart,
          () => unawaited(controller.restart()),
        ),
    };

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
