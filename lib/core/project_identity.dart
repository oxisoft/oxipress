import 'dart:convert';

import 'package:path/path.dart' as p;

/// Derives a stable, filesystem-agnostic storage key for a project located at
/// a given path. Used by the per-project state store so panel sizes, expanded
/// folder sets, etc., survive across restarts.
class ProjectIdentity {
  ProjectIdentity._();

  /// Returns a stable storage key for the project at [path].
  static String forPath(String path) {
    final canonical = p.canonicalize(path);
    return base64Url.encode(utf8.encode(canonical)).replaceAll('=', '');
  }
}
