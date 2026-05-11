/// Identifies which Hugo site config file was discovered at the project root.
enum HugoConfigKind {
  toml('hugo.toml'),
  yaml('hugo.yaml'),
  json('hugo.json'),
  legacyToml('config.toml'),
  legacyYaml('config.yaml'),
  legacyJson('config.json');

  const HugoConfigKind(this.filename);

  final String filename;

  bool get isLegacy => switch (this) {
        HugoConfigKind.legacyToml ||
        HugoConfigKind.legacyYaml ||
        HugoConfigKind.legacyJson =>
          true,
        _ => false,
      };
}

/// A currently-opened Hugo project.
class Project {
  const Project({
    required this.path,
    required this.name,
    required this.configKind,
  });

  /// Absolute path to the project root on disk.
  final String path;

  /// Display name (defaults to the directory basename).
  final String name;

  /// Which kind of Hugo config file lives at the root.
  final HugoConfigKind configKind;

  Project copyWith({String? path, String? name, HugoConfigKind? configKind}) =>
      Project(
        path: path ?? this.path,
        name: name ?? this.name,
        configKind: configKind ?? this.configKind,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.path == path &&
          other.name == name &&
          other.configKind == configKind);

  @override
  int get hashCode => Object.hash(path, name, configKind);

  @override
  String toString() =>
      'Project(name: $name, path: $path, configKind: ${configKind.filename})';
}
