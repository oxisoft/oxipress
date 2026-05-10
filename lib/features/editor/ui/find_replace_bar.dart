import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/editor_buffers_controller.dart';
import '../data/find_replace_controller.dart';
import '../domain/editor_buffer.dart';

/// Find / Replace bar shown above the editor when the user invokes
/// Ctrl/Cmd+F or Ctrl/Cmd+H. Operates against the active buffer's body.
class FindReplaceBar extends ConsumerStatefulWidget {
  const FindReplaceBar({super.key, required this.absolutePath});

  final String absolutePath;

  @override
  ConsumerState<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends ConsumerState<FindReplaceBar> {
  late final TextEditingController _queryController;
  late final TextEditingController _replacementController;
  final FocusNode _queryFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(findReplaceProvider);
    _queryController = TextEditingController(text: state.query);
    _replacementController =
        TextEditingController(text: state.replacement);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _replacementController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(findReplaceProvider);
    if (!state.visible) return const SizedBox.shrink();

    // Sync controllers if the state changed externally (e.g. close+reopen).
    if (state.query != _queryController.text) {
      _queryController.text = state.query;
    }
    if (state.replacement != _replacementController.text) {
      _replacementController.text = state.replacement;
    }

    final body = ref.watch(
      editorBuffersProvider.select<String>(
        (Map<String, EditorBuffer> m) =>
            m[widget.absolutePath]?.currentBody ?? '',
      ),
    );
    final matches = computeFindMatches(body, state);
    final hasMatches = matches.isNotEmpty;
    final currentLabel = hasMatches
        ? l10n.findMatchCount(
            (state.currentMatch < 0 ? 0 : state.currentMatch) + 1,
            matches.length,
          )
        : (state.query.isEmpty ? '' : l10n.findNoMatches);

    // Autofocus the query field when the bar is first opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_queryFocus.hasFocus && state.visible) {
        _queryFocus.requestFocus();
      }
    });

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _queryFocus,
                    decoration: InputDecoration(
                      hintText: l10n.findHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: ref
                        .read(findReplaceProvider.notifier)
                        .setQuery,
                  ),
                ),
                const SizedBox(width: 8),
                Text(currentLabel, style: theme.textTheme.labelSmall),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                  tooltip: l10n.findPrev,
                  onPressed: hasMatches
                      ? () => ref
                          .read(findReplaceProvider.notifier)
                          .prev(matches.length)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  tooltip: l10n.findNext,
                  onPressed: hasMatches
                      ? () => ref
                          .read(findReplaceProvider.notifier)
                          .next(matches.length)
                      : null,
                ),
                _ToggleChip(
                  label: 'Aa',
                  tooltip: l10n.findCaseSensitive,
                  selected: state.caseSensitive,
                  onTap: () => ref
                      .read(findReplaceProvider.notifier)
                      .setCaseSensitive(value: !state.caseSensitive),
                ),
                _ToggleChip(
                  label: 'W',
                  tooltip: l10n.findWholeWord,
                  selected: state.wholeWord,
                  onTap: () => ref
                      .read(findReplaceProvider.notifier)
                      .setWholeWord(value: !state.wholeWord),
                ),
                _ToggleChip(
                  label: '.*',
                  tooltip: l10n.findRegex,
                  selected: state.regex,
                  onTap: () => ref
                      .read(findReplaceProvider.notifier)
                      .setRegex(value: !state.regex),
                ),
                IconButton(
                  icon: Icon(
                    state.showReplace
                        ? Icons.expand_less
                        : Icons.find_replace,
                    size: 18,
                  ),
                  tooltip: l10n.replaceHint,
                  onPressed:
                      ref.read(findReplaceProvider.notifier).toggleReplace,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.findClose,
                  onPressed:
                      ref.read(findReplaceProvider.notifier).close,
                ),
              ],
            ),
            if (state.showReplace) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replacementController,
                      decoration: InputDecoration(
                        hintText: l10n.replaceHint,
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: ref
                          .read(findReplaceProvider.notifier)
                          .setReplacement,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: hasMatches
                        ? () => ref
                            .read(findReplaceProvider.notifier)
                            .replaceOne(widget.absolutePath, matches)
                        : null,
                    child: Text(l10n.findReplaceOne),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: hasMatches
                        ? () => ref
                            .read(findReplaceProvider.notifier)
                            .replaceAll(widget.absolutePath, matches)
                        : null,
                    child: Text(l10n.findReplaceAll),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
