import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../../project/ui/project_controller.dart';
import '../../project/ui/workspace_state_controller.dart';
import '../data/editor_buffers_controller.dart';

enum _CloseChoice { save, dontSave, cancel }

/// Closes the tab at [relativePath]. When the buffer is dirty, prompts the
/// user with Save / Don't save / Cancel before discarding the in-memory
/// buffer.
///
/// Use this helper for **every** tab-close entry point (tab bar x,
/// middle-click, Ctrl/Cmd+W) so the user is never surprised by losing work.
Future<void> closeTabWithConfirm({
  required BuildContext context,
  required WidgetRef ref,
  required String relativePath,
}) async {
  final lifecycle = ref.read(projectControllerProvider);
  if (lifecycle is! OpenProject) return;
  final absolutePath = p.join(lifecycle.project.path, relativePath);
  final buffer = ref.read(editorBuffersProvider)[absolutePath];

  if (buffer == null || !buffer.isDirty) {
    _doClose(ref, relativePath, absolutePath);
    return;
  }

  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final choice = await showDialog<_CloseChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.closeTabUnsavedTitle),
      content: Text(
        l10n.closeTabUnsavedBody(p.basename(relativePath)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _CloseChoice.cancel),
          child: Text(l10n.closeTabCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _CloseChoice.dontSave),
          child: Text(l10n.closeTabDontSave),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _CloseChoice.save),
          child: Text(l10n.closeTabSave),
        ),
      ],
    ),
  );

  switch (choice) {
    case null:
    case _CloseChoice.cancel:
      return;
    case _CloseChoice.save:
      await ref
          .read(editorBuffersProvider.notifier)
          .save(absolutePath);
      _doClose(ref, relativePath, absolutePath);
    case _CloseChoice.dontSave:
      _doClose(ref, relativePath, absolutePath);
  }
}

void _doClose(WidgetRef ref, String relativePath, String absolutePath) {
  ref.read(workspaceStateProvider.notifier).closeTab(relativePath);
  ref.read(editorBuffersProvider.notifier).close(absolutePath);
}
