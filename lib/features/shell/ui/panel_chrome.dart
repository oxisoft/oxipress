import 'package:flutter/material.dart';

/// Side that the chevron icon points toward when the panel is collapsed.
enum PanelCollapseSide { collapseToLeft, collapseToRight }

/// Wraps a panel's content with a header (title + actions + collapse toggle)
/// when expanded, or a thin vertical strip with an expand button when
/// collapsed.
class PanelChrome extends StatelessWidget {
  const PanelChrome({
    super.key,
    required this.title,
    required this.collapsed,
    required this.onCollapseToggle,
    required this.collapseSide,
    required this.child,
    this.collapseTooltip,
    this.expandTooltip,
    this.actions = const [],
  });

  final String title;
  final bool collapsed;
  final VoidCallback onCollapseToggle;
  final PanelCollapseSide collapseSide;
  final Widget child;
  final List<Widget> actions;
  final String? collapseTooltip;
  final String? expandTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (collapsed) {
      return _CollapsedStrip(
        title: title,
        collapseSide: collapseSide,
        onExpand: onCollapseToggle,
        expandTooltip: expandTooltip,
        theme: theme,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: title,
          actions: actions,
          collapseSide: collapseSide,
          onCollapse: onCollapseToggle,
          collapseTooltip: collapseTooltip,
          theme: theme,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.actions,
    required this.collapseSide,
    required this.onCollapse,
    required this.collapseTooltip,
    required this.theme,
  });

  final String title;
  final List<Widget> actions;
  final PanelCollapseSide collapseSide;
  final VoidCallback onCollapse;
  final String? collapseTooltip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final collapseIcon = collapseSide == PanelCollapseSide.collapseToLeft
        ? Icons.chevron_left
        : Icons.chevron_right;
    final collapseButton = IconButton(
      icon: Icon(collapseIcon, size: 18),
      tooltip: collapseTooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onCollapse,
    );

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          if (collapseSide == PanelCollapseSide.collapseToLeft) collapseButton,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          ...actions,
          if (collapseSide == PanelCollapseSide.collapseToRight) collapseButton,
        ],
      ),
    );
  }
}

class _CollapsedStrip extends StatelessWidget {
  const _CollapsedStrip({
    required this.title,
    required this.collapseSide,
    required this.onExpand,
    required this.expandTooltip,
    required this.theme,
  });

  final String title;
  final PanelCollapseSide collapseSide;
  final VoidCallback onExpand;
  final String? expandTooltip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final expandIcon = collapseSide == PanelCollapseSide.collapseToLeft
        ? Icons.chevron_right
        : Icons.chevron_left;
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Column(
        children: [
          IconButton(
            icon: Icon(expandIcon, size: 18),
            tooltip: expandTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: onExpand,
          ),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
