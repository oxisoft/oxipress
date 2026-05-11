import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/file_tree/domain/path_policy.dart';
import 'package:path/path.dart' as p;

void main() {
  group('isWriteAllowed', () {
    test('allows files inside content/, static/, assets/, data/, layouts/',
        () {
      for (final dir in allowedTopLevelDirs) {
        expect(
          isWriteAllowed(
            projectPath: '/site',
            absolutePath: p.join('/site', dir, 'foo.md'),
          ),
          isTrue,
          reason: 'expected writable in $dir/',
        );
      }
    });

    test('rejects files outside the allowed top-level directories', () {
      expect(
        isWriteAllowed(
          projectPath: '/site',
          absolutePath: '/site/themes/default/style.css',
        ),
        isFalse,
      );
      expect(
        isWriteAllowed(
          projectPath: '/site',
          absolutePath: '/site/hugo.toml',
        ),
        isFalse,
      );
    });

    test('rejects the project root itself', () {
      expect(
        isWriteAllowed(
          projectPath: '/site',
          absolutePath: '/site',
        ),
        isFalse,
      );
    });

    test('rejects paths above the project root', () {
      expect(
        isWriteAllowed(
          projectPath: '/site',
          absolutePath: '/other/content/foo.md',
        ),
        isFalse,
      );
    });
  });
}
