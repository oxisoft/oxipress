import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/features/hugo_process/domain/content_url_resolver.dart';
import 'package:path/path.dart' as p;

const _projectPath = '/sites/sample';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile(p.join(_projectPath, 'content', '_index.md'))
    ..addFile(p.join(_projectPath, 'content', 'about.md'))
    ..addDirectory(p.join(_projectPath, 'content', 'posts'))
    ..addFile(p.join(_projectPath, 'content', 'posts', '_index.md'))
    ..addFile(p.join(_projectPath, 'content', 'posts', 'first-post.md'))
    ..addDirectory(p.join(_projectPath, 'content', 'posts', 'photoset'))
    ..addFile(
      p.join(_projectPath, 'content', 'posts', 'photoset', 'index.md'),
    )
    ..addFile(
      p.join(_projectPath, 'content', 'docs', 'guide', 'install.md'),
    );
}

Future<String?> _match(String url) async {
  return ContentUrlResolver.matchContentFile(
    urlPath: url,
    fileSystem: _hugoSite(),
    projectPath: _projectPath,
  );
}

void main() {
  group('ContentUrlResolver.matchContentFile', () {
    test('root URL → content/_index.md', () async {
      expect(
        await _match('/'),
        p.join(_projectPath, 'content', '_index.md'),
      );
    });

    test('top-level page → about.md', () async {
      expect(
        await _match('/about/'),
        p.join(_projectPath, 'content', 'about.md'),
      );
    });

    test('section post → posts/first-post.md', () async {
      expect(
        await _match('/posts/first-post/'),
        p.join(_projectPath, 'content', 'posts', 'first-post.md'),
      );
    });

    test('page bundle → posts/photoset/index.md', () async {
      expect(
        await _match('/posts/photoset/'),
        p.join(_projectPath, 'content', 'posts', 'photoset', 'index.md'),
      );
    });

    test('section index → posts/_index.md', () async {
      expect(
        await _match('/posts/'),
        p.join(_projectPath, 'content', 'posts', '_index.md'),
      );
    });

    test('deep section → docs/guide/install.md', () async {
      expect(
        await _match('/docs/guide/install/'),
        p.join(_projectPath, 'content', 'docs', 'guide', 'install.md'),
      );
    });

    test('strips a trailing #anchor', () async {
      expect(
        await _match('/posts/first-post/#section'),
        p.join(_projectPath, 'content', 'posts', 'first-post.md'),
      );
    });

    test('strips a ?query string', () async {
      expect(
        await _match('/posts/first-post/?utm=foo'),
        p.join(_projectPath, 'content', 'posts', 'first-post.md'),
      );
    });

    test('accepts a full URL', () async {
      expect(
        await _match('http://127.0.0.1:1313/posts/first-post/'),
        p.join(_projectPath, 'content', 'posts', 'first-post.md'),
      );
    });

    test('returns null when nothing matches', () async {
      expect(await _match('/no/such/page/'), isNull);
    });

    test('returns null for an empty path', () async {
      expect(await _match(''), isNull);
    });
  });

  group('isInternalPreviewUrl', () {
    test('same host+port is internal', () {
      expect(
        isInternalPreviewUrl(
          Uri.parse('http://127.0.0.1:1313/posts/foo/'),
          baseUrl: 'http://127.0.0.1:1313',
        ),
        isTrue,
      );
    });

    test('localhost ↔ 127.0.0.1 considered internal', () {
      expect(
        isInternalPreviewUrl(
          Uri.parse('http://localhost:1313/'),
          baseUrl: 'http://127.0.0.1:1313',
        ),
        isTrue,
      );
    });

    test('different host is external', () {
      expect(
        isInternalPreviewUrl(
          Uri.parse('https://github.com/'),
          baseUrl: 'http://127.0.0.1:1313',
        ),
        isFalse,
      );
    });

    test('same host but different port is external', () {
      expect(
        isInternalPreviewUrl(
          Uri.parse('http://127.0.0.1:9999/'),
          baseUrl: 'http://127.0.0.1:1313',
        ),
        isFalse,
      );
    });

    test('relative URLs (no host) are internal', () {
      expect(
        isInternalPreviewUrl(
          Uri.parse('/posts/foo/'),
          baseUrl: 'http://127.0.0.1:1313',
        ),
        isTrue,
      );
    });
  });
}
