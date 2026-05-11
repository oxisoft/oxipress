import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class NewFileDialogResult {
  const NewFileDialogResult({required this.name, required this.useTemplate});

  final String name;
  final bool useTemplate;
}

Future<NewFileDialogResult?> showNewFileDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: 'new-post.md');
  final formKey = GlobalKey<FormState>();
  var useTemplate = true;

  final result = await showDialog<NewFileDialogResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(l10n.newFileDialogTitle),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.newFileNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '!' : null,
                    onFieldSubmitted: (_) =>
                        _submitNewFile(ctx, formKey, controller, useTemplate),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: useTemplate,
                        onChanged: (v) => setState(() => useTemplate = v),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(l10n.newFileUseTemplate)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.dialogCancel),
              ),
              FilledButton(
                onPressed: () => _submitNewFile(
                  ctx,
                  formKey,
                  controller,
                  useTemplate,
                ),
                child: Text(l10n.dialogCreate),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

void _submitNewFile(
  BuildContext context,
  GlobalKey<FormState> formKey,
  TextEditingController controller,
  bool useTemplate,
) {
  if (!(formKey.currentState?.validate() ?? false)) return;
  Navigator.pop(
    context,
    NewFileDialogResult(
      name: controller.text.trim(),
      useTemplate: useTemplate,
    ),
  );
}

Future<String?> showNewFolderDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.newFolderDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.newFolderNameHint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          Navigator.pop(ctx, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            if (v.isEmpty) return;
            Navigator.pop(ctx, v);
          },
          child: Text(l10n.dialogCreate),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: currentName);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: _nameSelectionEnd(currentName),
  );
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.renameDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.renameDialogHint,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: const [],
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          Navigator.pop(ctx, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            if (v.isEmpty) return;
            Navigator.pop(ctx, v);
          },
          child: Text(l10n.dialogRename),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

int _nameSelectionEnd(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return name.length;
  return dot;
}

Future<bool> showDeleteConfirm(
  BuildContext context, {
  required String name,
  required bool isDirectory,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteConfirmTitle),
      content: Text(
        isDirectory
            ? l10n.deleteConfirmFolder(name)
            : l10n.deleteConfirmFile(name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.dialogDelete),
        ),
      ],
    ),
  );
  return result ?? false;
}
