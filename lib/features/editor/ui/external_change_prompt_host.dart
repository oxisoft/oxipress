import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/generated/app_localizations.dart';
import '../data/editor_buffers_controller.dart';
import '../data/external_changes_controller.dart';

/// Invisible host that listens to [externalChangesProvider] and shows a
/// modal "File changed on disk" prompt for each newly added path. Mount
/// this once at the workspace screen level.
class ExternalChangePromptHost extends ConsumerWidget {
  const ExternalChangePromptHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Set<String>>(externalChangesProvider, (previous, next) {
      final added = next.difference(previous ?? const <String>{});
      for (final path in added) {
        unawaited(_showPrompt(context, ref, path));
      }
    });
    return const SizedBox.shrink();
  }

  Future<void> _showPrompt(
    BuildContext context,
    WidgetRef ref,
    String absolutePath,
  ) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<_Choice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.externalChangeTitle),
        content: Text(l10n.externalChangeBody(p.basename(absolutePath))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _Choice.keepMine),
            child: Text(l10n.externalChangeKeepMine),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _Choice.reloadDisk),
            child: Text(l10n.externalChangeReloadDisk),
          ),
        ],
      ),
    );

    if (choice == _Choice.reloadDisk) {
      await ref
          .read(editorBuffersProvider.notifier)
          .reloadFromDisk(absolutePath);
    }
    ref.read(externalChangesProvider.notifier).resolve(absolutePath);
  }
}

enum _Choice { keepMine, reloadDisk }
