import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../project/ui/project_controller.dart';

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
            icon: const Icon(Icons.save_outlined, size: 20),
            tooltip: l10n.toolbarSaveTooltip,
            onPressed: null,
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
