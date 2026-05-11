/// A single node in the file tree.
class FileTreeNode {
  const FileTreeNode({
    required this.path,
    required this.name,
    required this.isDirectory,
  });

  final String path;
  final String name;
  final bool isDirectory;

  bool get isFile => !isDirectory;

  bool get isMarkdown =>
      isFile && (name.endsWith('.md') || name.endsWith('.markdown'));

  /// Order: directories before files; within each, case-insensitive name.
  static int compare(FileTreeNode a, FileTreeNode b) {
    if (a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileTreeNode &&
          other.path == path &&
          other.name == name &&
          other.isDirectory == isDirectory);

  @override
  int get hashCode => Object.hash(path, name, isDirectory);

  @override
  String toString() =>
      'FileTreeNode(${isDirectory ? 'dir' : 'file'}: $path)';
}
