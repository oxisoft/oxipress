import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_info.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/hugo_site_validator.dart';
import '../domain/recent_project.dart';
import 'folder_picker.dart';
import 'project_controller.dart';
import 'recents_controller.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lifecycle = ref.watch(projectControllerProvider);
    final recentsAsync = ref.watch(recentsProvider);

    ref.listen<ProjectLifecycle>(projectControllerProvider, (prev, next) {
      if (next is ProjectOpenError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(l10n, next.error))),
        );
        ref.read(projectControllerProvider.notifier).clearError();
      }
    });

    final isOpening = lifecycle is OpeningProject;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: FilledButton.icon(
                    onPressed: isOpening
                        ? null
                        : () => _onOpenPressed(context, ref),
                    icon: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open),
                    label: Text(
                      isOpening ? l10n.openingProject : l10n.openProject,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _RecentsSection(
                  recentsAsync: recentsAsync,
                  isOpening: isOpening,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.documentationComingSoon)),
                      );
                    },
                    child: Text(l10n.documentation),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'v${AppInfo.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onOpenPressed(BuildContext context, WidgetRef ref) async {
    final picker = ref.read(folderPickerProvider);
    final path = await picker.pickFolder();
    if (path == null) return;
    await ref.read(projectControllerProvider.notifier).openProject(path);
  }

  String _messageFor(AppLocalizations l10n, HugoSiteValidationError e) {
    return switch (e) {
      HugoSiteValidationError.pathDoesNotExist => l10n.errorPathDoesNotExist,
      HugoSiteValidationError.notADirectory => l10n.errorNotADirectory,
      HugoSiteValidationError.missingContentDirectory =>
        l10n.errorMissingContentDirectory,
      HugoSiteValidationError.missingHugoConfig =>
        l10n.errorMissingHugoConfig,
    };
  }
}

class _RecentsSection extends ConsumerWidget {
  const _RecentsSection({
    required this.recentsAsync,
    required this.isOpening,
  });

  final AsyncValue<List<RecentProject>> recentsAsync;
  final bool isOpening;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final recents = recentsAsync.value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l10n.recentProjects, style: headerStyle),
        ),
        const SizedBox(height: 8),
        if (recents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              l10n.noRecentProjects,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Material(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: recents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final entry = recents[index];
                  return _RecentTile(
                    entry: entry,
                    enabled: !isOpening,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.entry, required this.enabled});

  final RecentProject entry;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.folder_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        entry.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entry.path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatRelative(entry.lastOpenedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: l10n.removeFromRecents,
            visualDensity: VisualDensity.compact,
            onPressed: enabled
                ? () async {
                    await ref
                        .read(recentsProvider.notifier)
                        .remove(entry.path);
                  }
                : null,
          ),
        ],
      ),
      onTap: enabled
          ? () => ref
              .read(projectControllerProvider.notifier)
              .openProject(entry.path)
          : null,
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
