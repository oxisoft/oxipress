import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/editor/domain/editor_buffer.dart';
import 'package:oxipress/features/editor/domain/frontmatter.dart';
import 'package:oxipress/features/editor/domain/frontmatter_format.dart';

EditorBuffer _buffer({
  String body = 'body',
  List<FrontmatterEntry> entries = const [
    FrontmatterEntry(key: 'title', value: 'T'),
  ],
}) {
  return EditorBuffer(
    absolutePath: '/site/content/x.md',
    format: FrontmatterFormat.yaml,
    savedEntries: entries,
    savedBody: body,
    currentEntries: entries,
    currentBody: body,
  );
}

void main() {
  group('EditorBuffer.isDirty', () {
    test('false when current matches saved', () {
      expect(_buffer().isDirty, isFalse);
    });

    test('true when body differs', () {
      final b = _buffer().copyWith(currentBody: 'changed');
      expect(b.isDirty, isTrue);
    });

    test('true when entries length differs', () {
      final b = _buffer().copyWith(currentEntries: const []);
      expect(b.isDirty, isTrue);
    });

    test('true when entry value differs', () {
      final b = _buffer().copyWith(
        currentEntries: const [FrontmatterEntry(key: 'title', value: 'X')],
      );
      expect(b.isDirty, isTrue);
    });
  });

  group('EditorBuffer transitions', () {
    test('markedSaved syncs saved snapshot to current', () {
      final b = _buffer().copyWith(currentBody: 'new');
      expect(b.isDirty, isTrue);
      final saved = b.markedSaved();
      expect(saved.isDirty, isFalse);
      expect(saved.savedBody, 'new');
      expect(saved.lastSavedAt, isNotNull);
    });

    test('reverted drops current back to saved', () {
      final b = _buffer().copyWith(currentBody: 'new');
      expect(b.isDirty, isTrue);
      final reverted = b.reverted();
      expect(reverted.isDirty, isFalse);
      expect(reverted.currentBody, 'body');
    });
  });
}
