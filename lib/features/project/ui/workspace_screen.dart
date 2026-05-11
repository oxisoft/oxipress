import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../editor/ui/editor_panel.dart';
import '../../editor/ui/external_change_prompt_host.dart';
import '../../file_tree/ui/file_tree_panel.dart';
import '../../hugo_process/ui/preview_panel.dart';
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
      body: Stack(
        children: [
          Column(
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
                    actions: const [EditorModeToggle()],
                    content: const EditorPanel(),
                  ),
                  right: PanelDefinition(
                    title: l10n.panelTitlePreview,
                    actions: const [PreviewBaseUrlChip()],
                    content: const PreviewPanel(),
                  ),
                ),
              ),
              const BottomStatusBar(),
            ],
          ),
          const ExternalChangePromptHost(),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
