import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/file_tree/domain/filename_template.dart';

void main() {
  group('humanizeFilename', () {
    test('strips extension and capitalizes hyphen-separated words', () {
      expect(humanizeFilename('first-post.md'), 'First Post');
      expect(humanizeFilename('getting-started.md'), 'Getting Started');
    });

    test('handles underscores and dots as separators', () {
      expect(humanizeFilename('getting_started.md'), 'Getting Started');
      expect(humanizeFilename('release.notes.md'), 'Release Notes');
    });

    test('handles a single-word filename', () {
      expect(humanizeFilename('about.md'), 'About');
    });

    test('handles names with no extension', () {
      expect(humanizeFilename('readme'), 'Readme');
    });

    test('preserves digits as standalone words', () {
      expect(humanizeFilename('2024-release.md'), '2024 Release');
    });
  });

  group('defaultHugoTemplate', () {
    test('emits title, date, and draft frontmatter', () {
      final out = defaultHugoTemplate(
        basename: 'first-post.md',
        now: DateTime.utc(2026, 1, 5, 10, 0, 0),
      );
      expect(out.contains('title: "First Post"'), isTrue);
      expect(out.contains('date: 2026-01-05T10:00:00.000Z'), isTrue);
      expect(out.contains('draft: true'), isTrue);
      expect(out.startsWith('---\n'), isTrue);
    });
  });
}
