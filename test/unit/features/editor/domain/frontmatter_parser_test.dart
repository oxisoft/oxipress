import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/editor/domain/frontmatter_format.dart';
import 'package:oxipress/features/editor/domain/frontmatter_parser.dart';

void main() {
  group('parseMarkdown — YAML', () {
    test('parses a typical YAML frontmatter and body', () {
      const source = '''
---
title: First post
date: 2026-01-05T10:00:00Z
draft: false
tags: ["intro", "hugo"]
---

Body of the first post.
''';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.yaml);
      expect(doc.frontmatter['title'], 'First post');
      expect(doc.frontmatter['draft'], false);
      expect(doc.frontmatter['tags'], ['intro', 'hugo']);
      expect(doc.body, 'Body of the first post.\n');
    });

    test('treats a YAML block with no closing delimiter as no frontmatter',
        () {
      const source = '---\ntitle: x\nmore body\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.none);
      expect(doc.body, source);
    });

    test('handles CRLF line endings', () {
      const source =
          '---\r\ntitle: hello\r\n---\r\nBody line\r\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.yaml);
      expect(doc.frontmatter['title'], 'hello');
    });

    test('handles BOM at start of source', () {
      const source = '﻿---\ntitle: x\n---\nBody\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.yaml);
      expect(doc.frontmatter['title'], 'x');
      expect(doc.body, 'Body\n');
    });

    test('preserves entry order', () {
      const source = '''
---
title: T
date: 2026-01-01
custom_field: hello
draft: false
---
body
''';
      final doc = parseMarkdown(source);
      expect(
        doc.frontmatter.entries.map((e) => e.key).toList(),
        ['title', 'date', 'custom_field', 'draft'],
      );
    });
  });

  group('parseMarkdown — TOML', () {
    test('parses a TOML frontmatter block', () {
      const source = '''
+++
title = "Second post"
date = 2026-01-12T10:00:00Z
draft = false
tags = ["hugo"]
+++

Body of the second post.
''';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.toml);
      expect(doc.frontmatter['title'], 'Second post');
      expect(doc.frontmatter['draft'], false);
      expect(doc.frontmatter['tags'], ['hugo']);
      expect(doc.body.trim().startsWith('Body'), isTrue);
    });

    test('falls back to empty frontmatter on malformed TOML', () {
      const source = '+++\nthis is = =not toml\n+++\nbody\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.toml);
      expect(doc.frontmatter.entries, isEmpty);
      expect(doc.body, 'body\n');
    });
  });

  group('parseMarkdown — JSON', () {
    test('parses a JSON frontmatter object', () {
      const source = '{\n  "title": "JSON post",\n  "draft": true\n}\nbody\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.json);
      expect(doc.frontmatter['title'], 'JSON post');
      expect(doc.frontmatter['draft'], true);
      expect(doc.body, 'body\n');
    });

    test('handles nested JSON objects', () {
      const source =
          '{\n  "title": "x",\n  "params": {"hero": "image.png"}\n}\n# heading\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.json);
      expect(doc.frontmatter['title'], 'x');
      expect(doc.frontmatter['params'], isA<Map<String, Object?>>());
    });

    test('returns empty frontmatter when JSON is malformed', () {
      const source = '{\n  not json\n}\nbody\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.json);
      expect(doc.frontmatter.entries, isEmpty);
    });
  });

  group('parseMarkdown — none', () {
    test('returns the whole source as body when no frontmatter is present',
        () {
      const source = '# Heading\n\nBody paragraph.\n';
      final doc = parseMarkdown(source);
      expect(doc.frontmatter.format, FrontmatterFormat.none);
      expect(doc.body, source);
    });

    test('handles empty source', () {
      final doc = parseMarkdown('');
      expect(doc.frontmatter.format, FrontmatterFormat.none);
      expect(doc.body, '');
    });
  });
}
