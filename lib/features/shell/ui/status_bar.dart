import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class BottomStatusBar extends StatelessWidget {
  const BottomStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
          Text(l10n.statusBarCursorPlaceholder, style: style),
          const Spacer(),
          Text(l10n.statusBarLastSavedPlaceholder, style: style),
        ],
      ),
    );
  }
}
