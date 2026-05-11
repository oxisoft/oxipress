/// Humanizes a filename into a readable title: strips extension, replaces
/// separators (`-`, `_`, `.`) with spaces, and capitalizes the first letter
/// of each word.
///
/// Examples:
/// - `first-post.md` → `First Post`
/// - `getting_started.md` → `Getting Started`
/// - `2024.01.05-release.md` → `2024 01 05 Release`
String humanizeFilename(String basename) {
  // Drop the extension.
  final dot = basename.lastIndexOf('.');
  final stem = dot > 0 ? basename.substring(0, dot) : basename;
  // Split on separators.
  final words = stem
      .split(RegExp(r'[-_.]+'))
      .where((w) => w.isNotEmpty)
      .map(_capitalize);
  return words.join(' ');
}

String _capitalize(String word) {
  if (word.isEmpty) return word;
  if (word.length == 1) return word.toUpperCase();
  return word[0].toUpperCase() + word.substring(1);
}

/// Builds the default Hugo markdown frontmatter + body stub for a new file.
String defaultHugoTemplate({
  required String basename,
  DateTime? now,
}) {
  final title = humanizeFilename(basename);
  final dateString = (now ?? DateTime.now().toUtc()).toIso8601String();
  return '''
---
title: "$title"
date: $dateString
draft: true
---

''';
}
