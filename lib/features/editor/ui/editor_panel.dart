import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/markdown_document_loader.dart';
import '../domain/markdown_document.dart';
import 'editor_tab_bar.dart';
import 'frontmatter_view.dart';
import 'raw_markdown_view.dart';

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
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CloseActiveTabIntent: CallbackAction<_CloseActiveTabIntent>(
                onInvoke: (_) {
                  ref
                      .read(workspaceStateProvider.notifier)
                      .closeTab(active);
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  const EditorTabBar(),
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

class _ActiveTabContent extends ConsumerWidget {
  const _ActiveTabContent({
    required this.relativePath,
    required this.projectPath,
  });

  final String relativePath;
  final String projectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final absolutePath = p.join(projectPath, relativePath);
    final docAsync = ref.watch(markdownDocumentProvider(absolutePath));

    return docAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(message: '$error'),
      data: (doc) => _DocumentView(
        document: doc,
        relativePath: relativePath,
        emptyBodyText: l10n.editorEmptyBody,
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({
    required this.document,
    required this.relativePath,
    required this.emptyBodyText,
  });

  final MarkdownDocument document;
  final String relativePath;
  final String emptyBodyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ModeToggleStub(),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrontmatterView(frontmatter: document.frontmatter),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                document.body.trim().isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          emptyBodyText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : RawMarkdownView(body: document.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeToggleStub extends StatelessWidget {
  const _ModeToggleStub();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Tooltip(
            message: l10n.editorModeRichComingSoon,
            child: SegmentedButton<_EditorMode>(
              segments: <ButtonSegment<_EditorMode>>[
                ButtonSegment(
                  value: _EditorMode.raw,
                  icon: const Icon(Icons.code, size: 16),
                  label: Text(l10n.editorModeRaw),
                ),
                ButtonSegment(
                  value: _EditorMode.rich,
                  icon: const Icon(Icons.text_fields, size: 16),
                  label: Text(l10n.editorModeRich),
                ),
              ],
              selected: const {_EditorMode.raw},
              onSelectionChanged: null,
            ),
          ),
        ],
      ),
    );
  }
}

enum _EditorMode { raw, rich }

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
