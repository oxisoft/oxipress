import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/hugo_process/domain/preview_url_computer.dart';

String _url(String path, [Map<String, Object?>? fm]) =>
    PreviewUrlComputer.pathForContentFile(
      relativeFromProject: path,
      frontmatter: fm,
    );

void main() {
  group('PreviewUrlComputer', () {
    test('root _index.md → /', () {
      expect(_url('content/_index.md'), '/');
    });

    test('top-level page', () {
      expect(_url('content/about.md'), '/about/');
    });

    test('section post', () {
      expect(_url('content/posts/foo.md'), '/posts/foo/');
    });

    test('page bundle (index.md)', () {
      expect(_url('content/posts/foo/index.md'), '/posts/foo/');
    });

    test('section _index.md', () {
      expect(_url('content/posts/_index.md'), '/posts/');
    });

    test('deep section', () {
      expect(
        _url('content/docs/getting-started/installation.md'),
        '/docs/getting-started/installation/',
      );
    });

    test('slug frontmatter overrides the stem', () {
      expect(
        _url('content/posts/foo.md', const {'slug': 'custom-slug'}),
        '/posts/custom-slug/',
      );
    });

    test('url frontmatter wins over everything', () {
      expect(
        _url(
          'content/posts/foo.md',
          const {'slug': 'ignored', 'url': '/totally/custom'},
        ),
        '/totally/custom/',
      );
    });

    test('url override missing leading slash is normalized', () {
      expect(
        _url('content/posts/foo.md', const {'url': 'about/team/'}),
        '/about/team/',
      );
    });

    test('paths outside content/ default to /', () {
      expect(_url('themes/foo/static/logo.png'), '/');
    });
  });
}
