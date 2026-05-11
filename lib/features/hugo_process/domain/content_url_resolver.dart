import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';

/// Reverse of `PreviewUrlComputer`: given a URL path on the Hugo serve,
/// find the project-relative content file that produces it under Hugo's
/// default URL rules. Returns null if no candidate exists on disk.
///
/// Approach A: candidate enumeration, no frontmatter inspection. Slug / url
/// frontmatter overrides and custom `permalinks` config are not handled —
/// callers will get a silent miss for those.
class ContentUrlResolver {
  ContentUrlResolver._();

  /// Strip the Hugo base URL, query string, and `#anchor`, then look for a
  /// matching content file.
  static Future<String?> matchContentFile({
    required String urlPath,
    required FileSystem fileSystem,
    required String projectPath,
  }) async {
    final normalized = _normalizePath(urlPath);
    if (normalized == null) return null;

    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();

    final candidates = <String>[];

    if (segments.isEmpty) {
      // Root URL → content root.
      candidates.add(p.join(projectPath, 'content', '_index.md'));
    } else {
      final joinedDir = p.joinAll([projectPath, 'content', ...segments]);
      final parentDir =
          p.joinAll([projectPath, 'content', ...segments.take(segments.length - 1)]);
      final lastSegment = segments.last;

      // Regular page: <segments[0..n-1]>/<lastSegment>.md
      candidates.add(p.join(parentDir, '$lastSegment.md'));
      // Page bundle: <segments>/index.md
      candidates.add(p.join(joinedDir, 'index.md'));
      // Section listing: <segments>/_index.md
      candidates.add(p.join(joinedDir, '_index.md'));
    }

    for (final candidate in candidates) {
      if (await fileSystem.fileExists(candidate)) return candidate;
    }
    return null;
  }

  /// Pure helper, exposed for unit tests: strip query / fragment / trailing
  /// slash from a URL path. Returns null for empty input.
  static String? _normalizePath(String urlPath) {
    if (urlPath.isEmpty) return null;
    var path = urlPath;
    // If a full URL was passed, parse and take the path.
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        final uri = Uri.parse(path);
        path = uri.path;
      } on FormatException catch (_) {
        return null;
      }
    }
    // Strip query.
    final qIdx = path.indexOf('?');
    if (qIdx >= 0) path = path.substring(0, qIdx);
    // Strip fragment.
    final hIdx = path.indexOf('#');
    if (hIdx >= 0) path = path.substring(0, hIdx);
    if (path.isEmpty) return '/';
    return path;
  }

  /// Visible-for-test convenience: parses + strips query/fragment from any
  /// URL or path. Returns null on empty input.
  static String? normalizeForTest(String urlPath) => _normalizePath(urlPath);
}

/// Returns true if [uri] points at the same Hugo serve host+port as
/// [baseUrl]. Used to allow internal navigation while routing external
/// links to the OS browser.
bool isInternalPreviewUrl(Uri uri, {required String baseUrl}) {
  final base = Uri.parse(baseUrl);
  if (uri.host.isEmpty) return true; // relative or fragment-only navigation
  final hostMatches = uri.host == base.host ||
      (uri.host == 'localhost' && base.host == '127.0.0.1') ||
      (uri.host == '127.0.0.1' && base.host == 'localhost');
  if (!hostMatches) return false;
  if (uri.hasPort && base.hasPort && uri.port != base.port) return false;
  return true;
}
