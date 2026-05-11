import 'frontmatter.dart';

/// A parsed markdown source: the detected frontmatter (or empty) plus the
/// body following it, plus the original source string for round-trip needs.
class MarkdownDocument {
  const MarkdownDocument({
    required this.frontmatter,
    required this.body,
    required this.rawSource,
  });

  final Frontmatter frontmatter;
  final String body;
  final String rawSource;

  static const MarkdownDocument empty = MarkdownDocument(
    frontmatter: Frontmatter.empty,
    body: '',
    rawSource: '',
  );
}
