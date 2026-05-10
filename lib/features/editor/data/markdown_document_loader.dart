import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/frontmatter_parser.dart';
import '../domain/markdown_document.dart';

/// Loads a markdown file at the given absolute path and parses it into a
/// [MarkdownDocument]. Keyed by absolute path so two different open tabs for
/// the same file share one read.
///
/// Phase 2 is read-only; this provider is the only entry point for getting
/// the parsed document into the UI. Phase 3 will replace it with an
/// editable buffer.
final markdownDocumentProvider = FutureProvider.autoDispose
    .family<MarkdownDocument, String>((ref, absolutePath) async {
  final fs = ref.watch(fileSystemProvider);
  final raw = await fs.readFileAsString(absolutePath);
  return parseMarkdown(raw);
});
