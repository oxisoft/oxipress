import 'dart:convert';

import 'frontmatter.dart';
import 'frontmatter_format.dart';

/// Serializes a frontmatter block + body back into a markdown source string,
/// preserving the original block format. Hand-rolled YAML and TOML writers
/// keep the entry order stable; JSON falls back to `JsonEncoder.withIndent`.
///
/// Comments inside the original frontmatter source are **not** preserved —
/// the parser surfaces only the decoded values, so any whitespace/comment
/// niceties between keys are lost on save. (Documented for users.)
String serializeMarkdown({
  required FrontmatterFormat format,
  required List<FrontmatterEntry> entries,
  required String body,
}) {
  final normalizedBody = body.endsWith('\n') ? body : '$body\n';
  switch (format) {
    case FrontmatterFormat.yaml:
      final block = _writeYaml(entries);
      return '---\n$block---\n\n$normalizedBody';
    case FrontmatterFormat.toml:
      final block = _writeToml(entries);
      return '+++\n$block+++\n\n$normalizedBody';
    case FrontmatterFormat.json:
      final block = _writeJson(entries);
      return '$block\n\n$normalizedBody';
    case FrontmatterFormat.none:
      return normalizedBody;
  }
}

// ---------------------------------------------------------------------------
// YAML
// ---------------------------------------------------------------------------

String _writeYaml(List<FrontmatterEntry> entries) {
  final sb = StringBuffer();
  for (final entry in entries) {
    sb.write(entry.key);
    sb.write(':');
    _writeYamlValue(sb, entry.value, indent: 0, atTopLevel: true);
    sb.write('\n');
  }
  return sb.toString();
}

void _writeYamlValue(
  StringBuffer sb,
  Object? value, {
  required int indent,
  required bool atTopLevel,
}) {
  if (value == null) {
    sb.write(' null');
    return;
  }
  if (value is bool) {
    sb.write(value ? ' true' : ' false');
    return;
  }
  if (value is num) {
    sb.write(' ${value.toString()}');
    return;
  }
  if (value is DateTime) {
    sb.write(' ${value.toUtc().toIso8601String()}');
    return;
  }
  if (value is List) {
    if (value.isEmpty) {
      sb.write(' []');
      return;
    }
    if (value.every(_isScalar)) {
      sb.write(' [');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) sb.write(', ');
        _writeYamlInlineScalar(sb, value[i]);
      }
      sb.write(']');
      return;
    }
    sb.write('\n');
    for (final item in value) {
      sb.write(' ' * (indent + 2));
      sb.write('-');
      _writeYamlValue(sb, item, indent: indent + 2, atTopLevel: false);
      sb.write('\n');
    }
    return;
  }
  if (value is Map) {
    if (value.isEmpty) {
      sb.write(' {}');
      return;
    }
    sb.write('\n');
    var first = true;
    for (final entry in value.entries) {
      if (!first) sb.write('\n');
      sb.write(' ' * (indent + 2));
      sb.write(entry.key.toString());
      sb.write(':');
      _writeYamlValue(sb, entry.value, indent: indent + 2, atTopLevel: false);
      first = false;
    }
    return;
  }
  sb.write(' ');
  _writeYamlInlineScalar(sb, value);
}

void _writeYamlInlineScalar(StringBuffer sb, Object? v) {
  if (v == null) {
    sb.write('null');
    return;
  }
  if (v is bool) {
    sb.write(v ? 'true' : 'false');
    return;
  }
  if (v is num) {
    sb.write(v.toString());
    return;
  }
  if (v is DateTime) {
    sb.write(v.toUtc().toIso8601String());
    return;
  }
  sb.write(_yamlScalar(v.toString()));
}

bool _isScalar(Object? v) =>
    v == null || v is bool || v is num || v is DateTime || v is String;

String _yamlScalar(String s) {
  if (s.isEmpty) return '""';
  if (_yamlNeedsQuoting(s)) {
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
  return s;
}

bool _yamlNeedsQuoting(String s) {
  if (s.contains('\n')) return true;
  if (s.startsWith(' ') || s.endsWith(' ')) return true;
  const reserved = {'true', 'false', 'null', 'yes', 'no', 'on', 'off', '~'};
  if (reserved.contains(s.toLowerCase())) return true;
  if (RegExp(r'^-?\d').hasMatch(s)) return true;
  if (RegExp(r'^[\[\]\{\}#&\*!|>"%@`]').hasMatch(s)) return true;
  if (s.contains(': ')) return true;
  if (s.startsWith('- ') || s == '-') return true;
  if (s.startsWith('? ') || s.startsWith(': ')) return true;
  return false;
}

// ---------------------------------------------------------------------------
// TOML
// ---------------------------------------------------------------------------

String _writeToml(List<FrontmatterEntry> entries) {
  final sb = StringBuffer();
  for (final entry in entries) {
    sb.write(entry.key);
    sb.write(' = ');
    _writeTomlValue(sb, entry.value);
    sb.write('\n');
  }
  return sb.toString();
}

void _writeTomlValue(StringBuffer sb, Object? value) {
  if (value == null) {
    sb.write('""');
    return;
  }
  if (value is bool) {
    sb.write(value ? 'true' : 'false');
    return;
  }
  if (value is num) {
    sb.write(value.toString());
    return;
  }
  if (value is DateTime) {
    sb.write(value.toUtc().toIso8601String());
    return;
  }
  if (value is List) {
    sb.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) sb.write(', ');
      _writeTomlValue(sb, value[i]);
    }
    sb.write(']');
    return;
  }
  if (value is Map) {
    sb.write('{ ');
    var first = true;
    for (final entry in value.entries) {
      if (!first) sb.write(', ');
      sb.write('${entry.key} = ');
      _writeTomlValue(sb, entry.value);
      first = false;
    }
    sb.write(' }');
    return;
  }
  sb.write(_tomlString(value.toString()));
}

String _tomlString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

String _writeJson(List<FrontmatterEntry> entries) {
  final map = <String, Object?>{};
  for (final entry in entries) {
    map[entry.key] = _normalizeForJson(entry.value);
  }
  return const JsonEncoder.withIndent('  ').convert(map);
}

Object? _normalizeForJson(Object? v) {
  if (v is DateTime) return v.toUtc().toIso8601String();
  if (v is List) return v.map(_normalizeForJson).toList(growable: false);
  if (v is Map) {
    return v.map(
      (k, val) => MapEntry(k.toString(), _normalizeForJson(val)),
    );
  }
  return v;
}
