import 'frontmatter_format.dart';

/// One key-value entry inside a frontmatter block.
///
/// `value` is the raw decoded representation: `String`, `num`, `bool`,
/// `DateTime`, `List`, `Map`, or `null`. The UI inspects the runtime type to
/// render typed widgets for known Hugo fields and a generic key/value row
/// for everything else.
class FrontmatterEntry {
  const FrontmatterEntry({required this.key, required this.value});

  final String key;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrontmatterEntry &&
          other.key == key &&
          _deepEquals(other.value, value));

  @override
  int get hashCode => Object.hash(key, _deepHash(value));

  @override
  String toString() => 'FrontmatterEntry($key: $value)';
}

/// The frontmatter block at the top of a markdown file. Holds the [format]
/// it was detected in plus the ordered list of [entries].
class Frontmatter {
  const Frontmatter({required this.format, required this.entries});

  final FrontmatterFormat format;
  final List<FrontmatterEntry> entries;

  static const Frontmatter empty = Frontmatter(
    format: FrontmatterFormat.none,
    entries: [],
  );

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  /// Looks up the first entry whose key matches [key], or returns null.
  Object? operator [](String key) {
    for (final entry in entries) {
      if (entry.key == key) return entry.value;
    }
    return null;
  }

  bool containsKey(String key) {
    for (final entry in entries) {
      if (entry.key == key) return true;
    }
    return false;
  }
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}

int _deepHash(Object? value) {
  if (value is List) return Object.hashAll(value.map(_deepHash));
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
    return Object.hashAll(
      entries.map((e) => Object.hash(e.key, _deepHash(e.value))),
    );
  }
  return value.hashCode;
}
