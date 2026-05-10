import 'package:flutter/material.dart';

/// Read-only display of a markdown body. Phase 3 swaps this for a real code
/// editor with syntax highlighting and editing affordances; for Phase 2 we
/// just render the body in a monospace, selectable, scrollable widget.
class RawMarkdownView extends StatelessWidget {
  const RawMarkdownView({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: SelectableText(
        body.isEmpty ? '' : body,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }
}
