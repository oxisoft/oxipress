import 'frontmatter.dart';
import 'frontmatter_format.dart';
import 'markdown_document.dart';

/// Editable in-memory buffer for one open file.
///
/// Holds two snapshots: what is currently being edited (`current*`) and what
/// is on disk (`saved*`). `isDirty` is a structural diff between the two —
/// equality of frontmatter entry list (order + value) and body string.
class EditorBuffer {
  const EditorBuffer({
    required this.absolutePath,
    required this.format,
    required this.savedEntries,
    required this.savedBody,
    required this.currentEntries,
    required this.currentBody,
    this.lastSavedAt,
  });

  final String absolutePath;
  final FrontmatterFormat format;
  final List<FrontmatterEntry> savedEntries;
  final String savedBody;
  final List<FrontmatterEntry> currentEntries;
  final String currentBody;
  final DateTime? lastSavedAt;

  factory EditorBuffer.fromDocument(
    String absolutePath,
    MarkdownDocument document,
  ) {
    final entries = List<FrontmatterEntry>.unmodifiable(
      document.frontmatter.entries,
    );
    return EditorBuffer(
      absolutePath: absolutePath,
      format: document.frontmatter.format,
      savedEntries: entries,
      savedBody: document.body,
      currentEntries: entries,
      currentBody: document.body,
    );
  }

  bool get isDirty {
    if (currentBody != savedBody) return true;
    if (currentEntries.length != savedEntries.length) return true;
    for (var i = 0; i < currentEntries.length; i++) {
      if (currentEntries[i] != savedEntries[i]) return true;
    }
    return false;
  }

  EditorBuffer copyWith({
    List<FrontmatterEntry>? savedEntries,
    String? savedBody,
    List<FrontmatterEntry>? currentEntries,
    String? currentBody,
    DateTime? lastSavedAt,
  }) =>
      EditorBuffer(
        absolutePath: absolutePath,
        format: format,
        savedEntries: savedEntries ?? this.savedEntries,
        savedBody: savedBody ?? this.savedBody,
        currentEntries: currentEntries ?? this.currentEntries,
        currentBody: currentBody ?? this.currentBody,
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      );

  /// Drop in-memory edits, returning to the on-disk snapshot.
  EditorBuffer reverted() => copyWith(
        currentEntries: savedEntries,
        currentBody: savedBody,
      );

  /// Mark the current state as saved (e.g. after a successful disk write).
  EditorBuffer markedSaved({DateTime? at}) => copyWith(
        savedEntries: List<FrontmatterEntry>.unmodifiable(currentEntries),
        savedBody: currentBody,
        lastSavedAt: at ?? DateTime.now(),
      );
}
