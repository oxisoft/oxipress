import 'dart:convert';

import 'package:toml/toml.dart' as toml;
import 'package:yaml/yaml.dart' as yaml;

import 'frontmatter.dart';
import 'frontmatter_format.dart';
import 'markdown_document.dart';

/// Parses a markdown source string into a [MarkdownDocument].
///
/// Handles BOM stripping, CRLF / LF / mixed line endings, YAML / TOML / JSON
/// frontmatter blocks, and falls back gracefully when no frontmatter is
/// present or when the block is malformed.
MarkdownDocument parseMarkdown(String source) {
  final cleaned = _stripBom(source);

  final yamlBlock = _extractDelimited(cleaned, '---');
  if (yamlBlock != null) {
    return _parseYamlBlock(yamlBlock, cleaned);
  }
  final tomlBlock = _extractDelimited(cleaned, '+++');
  if (tomlBlock != null) {
    return _parseTomlBlock(tomlBlock, cleaned);
  }
  if (_looksLikeJson(cleaned)) {
    final parsed = _parseJsonBlock(cleaned);
    if (parsed != null) return parsed;
  }
  return MarkdownDocument(
    frontmatter: Frontmatter.empty,
    body: cleaned,
    rawSource: source,
  );
}

/// Visible for testing.
String stripBomForTest(String s) => _stripBom(s);

String _stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

/// Returns the inner block of a `<delimiter>` … `<delimiter>` frontmatter
/// section plus the body following the closing delimiter, or null if no
/// well-formed block is present at the start of [source].
({String inner, String body})? _extractDelimited(
  String source,
  String delimiter,
) {
  final lineEndings = <int>[];
  for (var i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == 0x0A) lineEndings.add(i);
  }
  if (lineEndings.isEmpty) return null;

  final firstLine = source.substring(0, lineEndings.first).trimRight();
  if (firstLine.trim() != delimiter) return null;

  // Find the line whose trimmed content is the delimiter, after the first.
  var cursor = lineEndings.first + 1;
  for (var i = 1; i < lineEndings.length; i++) {
    final lineEnd = lineEndings[i];
    final line = source.substring(cursor, lineEnd);
    if (line.trim() == delimiter) {
      final inner = source.substring(lineEndings.first + 1, cursor);
      var body = source.substring(lineEnd + 1);
      // Drop a single leading newline so users don't see a blank line.
      if (body.startsWith('\n')) body = body.substring(1);
      return (inner: inner, body: body);
    }
    cursor = lineEnd + 1;
  }
  return null;
}

MarkdownDocument _parseYamlBlock(
  ({String inner, String body}) block,
  String source,
) {
  try {
    final parsed = yaml.loadYaml(block.inner);
    return MarkdownDocument(
      frontmatter: Frontmatter(
        format: FrontmatterFormat.yaml,
        entries: _entriesFrom(parsed),
      ),
      body: block.body,
      rawSource: source,
    );
  } on yaml.YamlException catch (_) {
    return MarkdownDocument(
      frontmatter: const Frontmatter(
        format: FrontmatterFormat.yaml,
        entries: [],
      ),
      body: block.body,
      rawSource: source,
    );
  }
}

MarkdownDocument _parseTomlBlock(
  ({String inner, String body}) block,
  String source,
) {
  try {
    final document = toml.TomlDocument.parse(block.inner);
    return MarkdownDocument(
      frontmatter: Frontmatter(
        format: FrontmatterFormat.toml,
        entries: _entriesFrom(document.toMap()),
      ),
      body: block.body,
      rawSource: source,
    );
  } on Object catch (_) {
    return MarkdownDocument(
      frontmatter: const Frontmatter(
        format: FrontmatterFormat.toml,
        entries: [],
      ),
      body: block.body,
      rawSource: source,
    );
  }
}

bool _looksLikeJson(String source) {
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') continue;
    return c == '{';
  }
  return false;
}

MarkdownDocument? _parseJsonBlock(String source) {
  // Scan for the matching closing brace, respecting nested objects/arrays
  // and string literals. The body starts immediately after.
  var depth = 0;
  var inString = false;
  var escape = false;
  var startedAt = -1;
  for (var i = 0; i < source.length; i++) {
    final ch = source[i];
    if (startedAt == -1) {
      if (ch == '{') {
        startedAt = i;
        depth = 1;
      } else if (ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r') {
        return null;
      }
      continue;
    }
    if (escape) {
      escape = false;
      continue;
    }
    if (inString) {
      if (ch == r'\') {
        escape = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        final block = source.substring(startedAt, i + 1);
        var body = source.substring(i + 1);
        if (body.startsWith('\r\n')) {
          body = body.substring(2);
        } else if (body.startsWith('\n')) {
          body = body.substring(1);
        }
        try {
          final decoded = jsonDecode(block);
          return MarkdownDocument(
            frontmatter: Frontmatter(
              format: FrontmatterFormat.json,
              entries: _entriesFrom(decoded),
            ),
            body: body,
            rawSource: source,
          );
        } on FormatException catch (_) {
          return MarkdownDocument(
            frontmatter: const Frontmatter(
              format: FrontmatterFormat.json,
              entries: [],
            ),
            body: body,
            rawSource: source,
          );
        }
      }
    }
  }
  return null;
}

List<FrontmatterEntry> _entriesFrom(Object? parsed) {
  if (parsed is! Map) return const [];
  return parsed.entries
      .map(
        (e) => FrontmatterEntry(
          key: e.key.toString(),
          value: _normalize(e.value),
        ),
      )
      .toList(growable: false);
}

Object? _normalize(Object? value) {
  if (value is yaml.YamlList) {
    return value.map(_normalize).toList(growable: false);
  }
  if (value is yaml.YamlMap) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      out[entry.key.toString()] = _normalize(entry.value);
    }
    return out;
  }
  if (value is List) {
    return value.map(_normalize).toList(growable: false);
  }
  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      out[entry.key.toString()] = _normalize(entry.value);
    }
    return out;
  }
  return value;
}
