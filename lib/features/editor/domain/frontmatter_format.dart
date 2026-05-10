/// Format of the frontmatter block detected at the top of a markdown file.
enum FrontmatterFormat {
  /// `---` delimited YAML block.
  yaml,

  /// `+++` delimited TOML block.
  toml,

  /// JSON object literal at the top of the file.
  json,

  /// No frontmatter — the entire source is body.
  none,
}
