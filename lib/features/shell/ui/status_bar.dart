import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../project/ui/workspace_state_controller.dart';

class BottomStatusBar extends ConsumerWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final workspace = ref.watch(workspaceStateProvider).value;
    final activePath = workspace?.activeTabPath;
    final centerLabel =
        activePath ?? l10n.statusBarCursorPlaceholder;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(l10n.statusBarReady, style: style),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              centerLabel,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(l10n.statusBarLastSavedPlaceholder, style: style),
        ],
      ),
    );
  }
}
