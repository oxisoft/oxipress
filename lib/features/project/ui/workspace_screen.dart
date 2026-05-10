import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../file_tree/ui/file_tree_panel.dart';
import '../../shell/ui/status_bar.dart';
import '../../shell/ui/three_panel_layout.dart';
import '../../shell/ui/top_toolbar.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: ThreePanelLayout(
              left: PanelDefinition(
                title: l10n.panelTitleFiles,
                actions: const [FileTreeRootToggle()],
                content: const FileTreePanel(),
              ),
              middle: PanelDefinition(
                title: l10n.panelTitleEditor,
                content: _Placeholder(text: l10n.editorPlaceholder),
              ),
              right: PanelDefinition(
                title: l10n.panelTitlePreview,
                content: _Placeholder(text: l10n.previewPlaceholder),
              ),
            ),
          ),
          const BottomStatusBar(),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
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
