/// An entry in the recent-projects list shown on the welcome screen.
class RecentProject {
  const RecentProject({
    required this.path,
    required this.name,
    required this.lastOpenedAt,
  });

  final String path;
  final String name;
  final DateTime lastOpenedAt;

  Map<String, Object?> toJson() => {
        'path': path,
        'name': name,
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
      };

  static RecentProject fromJson(Map<String, Object?> json) => RecentProject(
        path: json['path']! as String,
        name: json['name']! as String,
        lastOpenedAt: DateTime.parse(json['lastOpenedAt']! as String),
      );

  RecentProject copyWith({
    String? path,
    String? name,
    DateTime? lastOpenedAt,
  }) =>
      RecentProject(
        path: path ?? this.path,
        name: name ?? this.name,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentProject &&
          other.path == path &&
          other.name == name &&
          other.lastOpenedAt == lastOpenedAt);

  @override
  int get hashCode => Object.hash(path, name, lastOpenedAt);

  @override
  String toString() => 'RecentProject(name: $name, path: $path)';
}
