import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../project/domain/workspace_state.dart';
import '../../project/ui/workspace_state_controller.dart';
import 'panel_chrome.dart';

/// Three-panel resizable workspace layout.
///
/// Sizing model:
/// - **Middle** (editor) takes the flex slot whenever it is visible — it
///   absorbs space when the right panel collapses, etc.
/// - **Left** (tree) and **right** (preview) have stored pixel widths that
///   the user adjusts by dragging the dividers; their widths are preserved
///   across collapse/expand cycles.
/// - When the middle is collapsed, the next visible panel (right, then left)
///   inherits the flex slot.
///
/// Persistence: widths are written to disk only when the user finishes a
/// drag (via [MultiSplitView.onDividerDragEnd]) — not on every layout
/// recompute, so initial layout / window-resize clamping doesn't churn the
/// workspace.json file.
class ThreePanelLayout extends ConsumerWidget {
  const ThreePanelLayout({
    super.key,
    required this.left,
    required this.middle,
    required this.right,
  });

  final PanelDefinition left;
  final PanelDefinition middle;
  final PanelDefinition right;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceStateProvider);
    return workspace.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (state) => _Split(
        state: state,
        left: left,
        middle: middle,
        right: right,
      ),
    );
  }
}

class PanelDefinition {
  const PanelDefinition({
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
}

class _Split extends ConsumerStatefulWidget {
  const _Split({
    required this.state,
    required this.left,
    required this.middle,
    required this.right,
  });

  final WorkspaceState state;
  final PanelDefinition left;
  final PanelDefinition middle;
  final PanelDefinition right;

  @override
  ConsumerState<_Split> createState() => _SplitState();
}

class _SplitState extends ConsumerState<_Split> {
  late MultiSplitViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController(areas: _buildAreas(widget.state));
  }

  @override
  void didUpdateWidget(_Split oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.panelLayout != oldWidget.state.panelLayout) {
      _controller.areas = _buildAreas(widget.state);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Persist the post-drag widths of left / right whenever a divider drag
  /// ends. We only call setters when the value actually changed and only
  /// for visible (non-collapsed) panels.
  void _persistAfterDrag() {
    final layout = widget.state.panelLayout;
    final notifier = ref.read(workspaceStateProvider.notifier);

    final leftSize = _controller.areas[0].size;
    if (leftSize != null &&
        !layout.collapsed[0] &&
        leftSize != layout.leftWidth) {
      notifier.setLeftWidth(leftSize);
    }

    final rightSize = _controller.areas[2].size;
    if (rightSize != null &&
        !layout.collapsed[2] &&
        rightSize != layout.rightWidth) {
      notifier.setRightWidth(rightSize);
    }
  }

  /// The middle panel takes the flex slot when visible. If middle is
  /// collapsed, the next visible panel (right, then left) inherits flex so
  /// the layout always consumes the full width.
  int _flexOwner(List<bool> collapsed) {
    if (!collapsed[1]) return 1;
    if (!collapsed[2]) return 2;
    return 0;
  }

  List<Area> _buildAreas(WorkspaceState state) {
    final layout = state.panelLayout;
    final flexOwner = _flexOwner(layout.collapsed);
    return [
      _areaFor(0, layout, flexOwner),
      _areaFor(1, layout, flexOwner),
      _areaFor(2, layout, flexOwner),
    ];
  }

  Area _areaFor(int index, PanelLayoutState layout, int flexOwner) {
    if (layout.collapsed[index]) {
      return Area(
        id: _idFor(index),
        size: PanelLayoutState.collapsedPanelWidth,
        min: PanelLayoutState.collapsedPanelWidth,
        max: PanelLayoutState.collapsedPanelWidth,
      );
    }
    if (index == flexOwner) {
      return Area(
        id: _idFor(index),
        flex: 1,
        min: PanelLayoutState.minPanelWidth,
      );
    }
    final size = switch (index) {
      0 => layout.leftWidth,
      2 => layout.rightWidth,
      _ => PanelLayoutState.minPanelWidth,
    };
    return Area(
      id: _idFor(index),
      size: size,
      min: PanelLayoutState.minPanelWidth,
    );
  }

  String _idFor(int index) => switch (index) {
        0 => 'left',
        1 => 'middle',
        _ => 'right',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = widget.state;

    Widget panelFor(int index, PanelDefinition def, PanelCollapseSide side) {
      return PanelChrome(
        title: def.title,
        collapsed: state.panelLayout.collapsed[index],
        onCollapseToggle: () => ref
            .read(workspaceStateProvider.notifier)
            .setPanelCollapsed(
              index,
              collapsed: !state.panelLayout.collapsed[index],
            ),
        collapseSide: side,
        actions: def.actions,
        collapseTooltip: l10n.collapsePanel,
        expandTooltip: l10n.expandPanel,
        child: def.content,
      );
    }

    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 6,
        dividerPainter: DividerPainters.background(
          color: theme.colorScheme.outlineVariant,
          highlightedColor: theme.colorScheme.primary,
        ),
      ),
      child: MultiSplitView(
        controller: _controller,
        onDividerDragEnd: (_) => _persistAfterDrag(),
        builder: (context, area) {
          return switch (area.id) {
            'left' => panelFor(
                0,
                widget.left,
                PanelCollapseSide.collapseToLeft,
              ),
            'middle' => panelFor(
                1,
                widget.middle,
                PanelCollapseSide.collapseToLeft,
              ),
            'right' => panelFor(
                2,
                widget.right,
                PanelCollapseSide.collapseToRight,
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
