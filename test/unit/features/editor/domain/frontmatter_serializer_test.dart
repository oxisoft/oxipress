import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/editor/domain/frontmatter.dart';
import 'package:oxipress/features/editor/domain/frontmatter_format.dart';
import 'package:oxipress/features/editor/domain/frontmatter_parser.dart';
import 'package:oxipress/features/editor/domain/frontmatter_serializer.dart';

void main() {
  group('serializeMarkdown — YAML', () {
    test('produces a delimited block + body with trailing newline', () {
      final source = serializeMarkdown(
        format: FrontmatterFormat.yaml,
        entries: const [
          FrontmatterEntry(key: 'title', value: 'Hello'),
          FrontmatterEntry(key: 'draft', value: false),
        ],
        body: '# Body\n',
      );
      expect(
        source,
        '---\ntitle: Hello\ndraft: false\n---\n\n# Body\n',
      );
    });

    test('quotes strings that look like reserved YAML literals', () {
      final source = serializeMarkdown(
        format: FrontmatterFormat.yaml,
        entries: const [
          FrontmatterEntry(key: 'title', value: 'true'),
          FrontmatterEntry(key: 'slug', value: 'no'),
        ],
        body: '',
      );
      expect(source.contains('title: "true"'), isTrue);
      expect(source.contains('slug: "no"'), isTrue);
    });

    test('emits flow style for lists of scalars', () {
      final source = serializeMarkdown(
        format: FrontmatterFormat.yaml,
        entries: const [
          FrontmatterEntry(key: 'tags', value: ['a', 'b', 'c']),
        ],
        body: '',
      );
      expect(source.contains('tags: [a, b, c]'), isTrue);
    });

    test('YAML round-trip preserves title / draft / tags / order', () {
      const original = '''
---
title: Round trip
date: 2026-05-10T12:00:00.000Z
draft: false
tags: [intro, hugo]
---

Body content.
''';
      final doc = parseMarkdown(original);
      final back = serializeMarkdown(
        format: doc.frontmatter.format,
        entries: doc.frontmatter.entries,
        body: doc.body,
      );
      final reparsed = parseMarkdown(back);
      expect(reparsed.frontmatter['title'], 'Round trip');
      expect(reparsed.frontmatter['draft'], false);
      expect(reparsed.frontmatter['tags'], ['intro', 'hugo']);
      expect(
        reparsed.frontmatter.entries.map((e) => e.key).toList(),
        ['title', 'date', 'draft', 'tags'],
      );
      expect(reparsed.body, doc.body);
    });
  });

  group('serializeMarkdown — TOML', () {
    test('produces a delimited block with double-quoted strings', () {
      final source = serializeMarkdown(
        format: FrontmatterFormat.toml,
        entries: const [
          FrontmatterEntry(key: 'title', value: 'Hello'),
          FrontmatterEntry(key: 'tags', value: ['a', 'b']),
        ],
        body: 'body\n',
      );
      expect(source.startsWith('+++\n'), isTrue);
      expect(source.contains('title = "Hello"'), isTrue);
      expect(source.contains('tags = ["a", "b"]'), isTrue);
      expect(source.contains('\n+++\n\nbody\n'), isTrue);
    });

    test('TOML round-trip preserves keys + values', () {
      const original = '''
+++
title = "TOML post"
draft = false
tags = ["t1", "t2"]
+++

Body.
''';
      final doc = parseMarkdown(original);
      final back = serializeMarkdown(
        format: doc.frontmatter.format,
        entries: doc.frontmatter.entries,
        body: doc.body,
      );
      final reparsed = parseMarkdown(back);
      expect(reparsed.frontmatter.format, FrontmatterFormat.toml);
      expect(reparsed.frontmatter['title'], 'TOML post');
      expect(reparsed.frontmatter['draft'], false);
      expect(reparsed.frontmatter['tags'], ['t1', 't2']);
    });
  });

  group('serializeMarkdown — JSON', () {
    test('produces an indented JSON object + body', () {
      final source = serializeMarkdown(
        format: FrontmatterFormat.json,
        entries: const [
          FrontmatterEntry(key: 'title', value: 'JSON'),
        ],
        body: 'b',
      );
      expect(source.contains('"title": "JSON"'), isTrue);
      expect(source.endsWith('b\n'), isTrue);
    });

    test('JSON round-trip preserves keys + values', () {
      const original = '''
{
  "title": "x",
  "draft": true
}

body
''';
      final doc = parseMarkdown(original);
      final back = serializeMarkdown(
        format: doc.frontmatter.format,
        entries: doc.frontmatter.entries,
        body: doc.body,
      );
      final reparsed = parseMarkdown(back);
      expect(reparsed.frontmatter['title'], 'x');
      expect(reparsed.frontmatter['draft'], true);
    });
  });

  test('serializeMarkdown — none returns just the body', () {
    final source = serializeMarkdown(
      format: FrontmatterFormat.none,
      entries: const [],
      body: '# Just body',
    );
    expect(source, '# Just body\n');
  });
}
