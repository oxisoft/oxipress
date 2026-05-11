import 'package:path/path.dart' as p;

/// Computes the URL **path** portion for a Hugo content file. The preview
/// panel concatenates it with the Hugo server's base URL to navigate the
/// embedded webview.
///
/// Implements the common Hugo URL rules without consulting a custom
/// `permalinks` config (Phase 5 baseline — permalink overrides can land
/// in a later iteration):
/// - `content/_index.md`             → `/`
/// - `content/about.md`              → `/about/`
/// - `content/posts/foo.md`          → `/posts/foo/`
/// - `content/posts/foo/index.md`    → `/posts/foo/` (page bundle)
/// - `content/posts/_index.md`       → `/posts/` (section)
/// - `slug` frontmatter overrides the stem of a regular page.
/// - `url`  frontmatter overrides everything (absolute path).
class PreviewUrlComputer {
  PreviewUrlComputer._();

  static String pathForContentFile({
    required String relativeFromProject,
    Map<String, Object?>? frontmatter,
  }) {
    // `url` wins over everything else.
    final urlOverride = frontmatter?['url'];
    if (urlOverride is String && urlOverride.isNotEmpty) {
      var u = urlOverride;
      if (!u.startsWith('/')) u = '/$u';
      if (!u.endsWith('/')) u = '$u/';
      return u;
    }

    // Strip everything up to (and including) the "content" segment.
    final parts = p.split(p.normalize(relativeFromProject));
    final contentIdx = parts.indexOf('content');
    if (contentIdx == -1) return '/';
    final relParts = parts.sublist(contentIdx + 1);
    if (relParts.isEmpty) return '/';

    final lastPart = relParts.last;

    // Section listing (`_index.md`) → directory URL.
    if (lastPart == '_index.md') {
      if (relParts.length == 1) return '/';
      return '/${relParts.sublist(0, relParts.length - 1).join('/')}/';
    }

    // Page bundle (`index.md`) → containing directory URL.
    if (lastPart == 'index.md') {
      if (relParts.length == 1) return '/';
      return '/${relParts.sublist(0, relParts.length - 1).join('/')}/';
    }

    // Regular page: stem with optional slug override.
    final extDot = lastPart.lastIndexOf('.');
    final stem = extDot > 0 ? lastPart.substring(0, extDot) : lastPart;
    final slugOverride = frontmatter?['slug'];
    final effectiveStem =
        (slugOverride is String && slugOverride.isNotEmpty)
            ? slugOverride
            : stem;

    final dirSegments = relParts.sublist(0, relParts.length - 1);
    if (dirSegments.isEmpty) return '/$effectiveStem/';
    return '/${dirSegments.join('/')}/$effectiveStem/';
  }
}
