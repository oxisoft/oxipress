/// Which root the file tree is showing for the open project.
enum TreeRootMode { content, projectRoot }

/// Persistent layout state for the three-panel workspace shell.
///
/// Sizing model: the **middle** (editor) panel always takes the remaining
/// width via flex; the **left** (tree) and **right** (preview) panels each
/// have a stored pixel width that the user adjusts by dragging the dividers.
/// When a panel is collapsed it shrinks to a thin strip and the next visible
/// panel inherits the flex slot — so collapsing the right panel makes the
/// editor expand into its space without disturbing the tree's width.
class PanelLayoutState {
  const PanelLayoutState({
    required this.leftWidth,
    required this.rightWidth,
    required this.collapsed,
  });

  /// Width of the left (tree) panel in logical pixels when not collapsed.
  final double leftWidth;

  /// Width of the right (preview) panel in logical pixels when not collapsed.
  final double rightWidth;

  /// `[leftCollapsed, middleCollapsed, rightCollapsed]`.
  final List<bool> collapsed;

  static const double defaultLeftWidth = 280;
  static const double defaultRightWidth = 360;
  static const double minPanelWidth = 160;
  static const double collapsedPanelWidth = 36;

  static const PanelLayoutState defaults = PanelLayoutState(
    leftWidth: defaultLeftWidth,
    rightWidth: defaultRightWidth,
    collapsed: [false, false, false],
  );

  Map<String, Object?> toJson() => {
        'leftWidth': leftWidth,
        'rightWidth': rightWidth,
        'collapsed': collapsed,
      };

  static PanelLayoutState fromJson(Map<String, Object?> json) {
    final rawCollapsed = (json['collapsed'] as List<dynamic>? ?? const [])
        .cast<bool>();
    return PanelLayoutState(
      leftWidth: (json['leftWidth'] as num?)?.toDouble() ?? defaultLeftWidth,
      rightWidth:
          (json['rightWidth'] as num?)?.toDouble() ?? defaultRightWidth,
      collapsed: rawCollapsed.length == 3
          ? rawCollapsed
          : defaults.collapsed,
    );
  }

  PanelLayoutState copyWith({
    double? leftWidth,
    double? rightWidth,
    List<bool>? collapsed,
  }) =>
      PanelLayoutState(
        leftWidth: leftWidth ?? this.leftWidth,
        rightWidth: rightWidth ?? this.rightWidth,
        collapsed: collapsed ?? this.collapsed,
      );

  PanelLayoutState withCollapsed(int index, bool value) {
    final next = List<bool>.of(collapsed);
    next[index] = value;
    return copyWith(collapsed: next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PanelLayoutState) return false;
    if (leftWidth != other.leftWidth) return false;
    if (rightWidth != other.rightWidth) return false;
    if (collapsed.length != other.collapsed.length) return false;
    for (var i = 0; i < collapsed.length; i++) {
      if (collapsed[i] != other.collapsed[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([leftWidth, rightWidth, ...collapsed]);
}

/// Per-project persisted workspace settings: panel layout, expanded folder
/// paths in the tree, which root the tree is showing, and the editor's
/// open tabs (paths relative to the project root) plus which one is active.
class WorkspaceState {
  const WorkspaceState({
    required this.panelLayout,
    required this.expandedFolders,
    required this.treeRootMode,
    this.openTabs = const <String>[],
    this.activeTabPath,
  });

  final PanelLayoutState panelLayout;
  final Set<String> expandedFolders;
  final TreeRootMode treeRootMode;

  /// Editor tabs in order, as paths **relative** to the project root.
  /// Storing relative paths means the state survives moving / renaming the
  /// project's parent directory.
  final List<String> openTabs;

  /// Currently-active tab path (relative to project root), or null when
  /// nothing is open.
  final String? activeTabPath;

  static const WorkspaceState defaults = WorkspaceState(
    panelLayout: PanelLayoutState.defaults,
    expandedFolders: <String>{},
    treeRootMode: TreeRootMode.content,
    openTabs: <String>[],
    activeTabPath: null,
  );

  Map<String, Object?> toJson() => {
        'panelLayout': panelLayout.toJson(),
        'expandedFolders': expandedFolders.toList()..sort(),
        'treeRootMode': treeRootMode.name,
        'openTabs': openTabs,
        if (activeTabPath != null) 'activeTabPath': activeTabPath,
      };

  static WorkspaceState fromJson(Map<String, Object?> json) {
    return WorkspaceState(
      panelLayout: PanelLayoutState.fromJson(
        (json['panelLayout'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
      expandedFolders:
          (json['expandedFolders'] as List<dynamic>? ?? const [])
              .cast<String>()
              .toSet(),
      treeRootMode: TreeRootMode.values.firstWhere(
        (t) => t.name == (json['treeRootMode'] as String?),
        orElse: () => TreeRootMode.content,
      ),
      openTabs: (json['openTabs'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      activeTabPath: json['activeTabPath'] as String?,
    );
  }

  WorkspaceState copyWith({
    PanelLayoutState? panelLayout,
    Set<String>? expandedFolders,
    TreeRootMode? treeRootMode,
    List<String>? openTabs,
    String? activeTabPath,
    bool clearActiveTab = false,
  }) =>
      WorkspaceState(
        panelLayout: panelLayout ?? this.panelLayout,
        expandedFolders: expandedFolders ?? this.expandedFolders,
        treeRootMode: treeRootMode ?? this.treeRootMode,
        openTabs: openTabs ?? this.openTabs,
        activeTabPath: clearActiveTab
            ? null
            : (activeTabPath ?? this.activeTabPath),
      );

  WorkspaceState withFolderExpanded(String path, bool expanded) {
    final next = Set<String>.of(expandedFolders);
    if (expanded) {
      next.add(path);
    } else {
      next.remove(path);
    }
    return copyWith(expandedFolders: next);
  }

  WorkspaceState withTabOpened(String relativePath) {
    final next = openTabs.contains(relativePath)
        ? openTabs
        : [...openTabs, relativePath];
    return copyWith(openTabs: next, activeTabPath: relativePath);
  }

  WorkspaceState withTabClosed(String relativePath) {
    if (!openTabs.contains(relativePath)) return this;
    final remaining =
        openTabs.where((t) => t != relativePath).toList(growable: false);
    if (activeTabPath == relativePath) {
      final newActive = remaining.isEmpty ? null : remaining.last;
      return copyWith(
        openTabs: remaining,
        activeTabPath: newActive,
        clearActiveTab: newActive == null,
      );
    }
    return copyWith(openTabs: remaining);
  }

  WorkspaceState withActiveTab(String relativePath) {
    if (!openTabs.contains(relativePath)) return this;
    return copyWith(activeTabPath: relativePath);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceState &&
          other.panelLayout == panelLayout &&
          _setEquals(other.expandedFolders, expandedFolders) &&
          other.treeRootMode == treeRootMode &&
          _listEquals(other.openTabs, openTabs) &&
          other.activeTabPath == activeTabPath);

  @override
  int get hashCode => Object.hash(
        panelLayout,
        Object.hashAllUnordered(expandedFolders),
        treeRootMode,
        Object.hashAll(openTabs),
        activeTabPath,
      );

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
