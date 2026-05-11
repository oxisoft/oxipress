import 'package:path/path.dart' as p;

/// Directories under a Hugo project root that OxiPress treats as writable
/// when the tree is in "project root" mode. Anything else is read-only.
const Set<String> allowedTopLevelDirs = {
  'content',
  'static',
  'assets',
  'data',
  'layouts',
};

/// Returns true if [absolutePath] (a file or directory anywhere under the
/// project root) is in an allowed top-level directory.
bool isWriteAllowed({
  required String projectPath,
  required String absolutePath,
}) {
  if (p.equals(absolutePath, projectPath)) return false;
  final relative = p.relative(absolutePath, from: projectPath);
  if (relative.startsWith('..')) return false;
  final parts = p.split(relative);
  if (parts.isEmpty) return false;
  return allowedTopLevelDirs.contains(parts.first);
}
