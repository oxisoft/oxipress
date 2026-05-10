import 'file_tree_node.dart';

/// Snapshot of the file tree currently rendered: which root we're under,
/// what children exist beneath each loaded directory, what's selected, and
/// which folders are currently expanded.
class FileTreeView {
  const FileTreeView({
    required this.rootPath,
    required this.children,
    required this.expandedFolders,
    required this.selectedPath,
  });

  /// Path of the directory used as the tree root.
  final String rootPath;

  /// Children loaded for each directory path (root + every expanded folder
  /// that's a descendant of the root).
  final Map<String, List<FileTreeNode>> children;

  /// Set of directory paths that are currently expanded.
  final Set<String> expandedFolders;

  /// Path of the currently-selected node, or null.
  final String? selectedPath;

  static const FileTreeView empty = FileTreeView(
    rootPath: '',
    children: <String, List<FileTreeNode>>{},
    expandedFolders: <String>{},
    selectedPath: null,
  );

  bool get isEmpty => rootPath.isEmpty;

  FileTreeView copyWith({
    String? rootPath,
    Map<String, List<FileTreeNode>>? children,
    Set<String>? expandedFolders,
    String? selectedPath,
    bool clearSelection = false,
  }) =>
      FileTreeView(
        rootPath: rootPath ?? this.rootPath,
        children: children ?? this.children,
        expandedFolders: expandedFolders ?? this.expandedFolders,
        selectedPath:
            clearSelection ? null : (selectedPath ?? this.selectedPath),
      );
}
