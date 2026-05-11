import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/reveal_in_file_manager.dart';

void main() {
  group('revealCommandFor', () {
    test('macOS uses `open -R <path>`', () {
      final (exe, args) = revealCommandFor(
        operatingSystem: 'macos',
        absolutePath: '/Users/me/site/content/post.md',
      );
      expect(exe, 'open');
      expect(args, ['-R', '/Users/me/site/content/post.md']);
    });

    test('Windows uses `explorer /select,<path>`', () {
      final (exe, args) = revealCommandFor(
        operatingSystem: 'windows',
        absolutePath: r'C:\Users\me\site\content\post.md',
      );
      expect(exe, 'explorer');
      expect(args, [r'/select,C:\Users\me\site\content\post.md']);
    });

    test('Linux falls back to xdg-open on the parent directory', () {
      final (exe, args) = revealCommandFor(
        operatingSystem: 'linux',
        absolutePath: '/home/me/site/content/post.md',
      );
      expect(exe, 'xdg-open');
      expect(args, ['/home/me/site/content']);
    });
  });

  group('RecordingRevealInFileManager', () {
    test('records every reveal call in order', () async {
      final r = RecordingRevealInFileManager();
      await r.reveal('/a');
      await r.reveal('/b');
      expect(r.revealedPaths, ['/a', '/b']);
    });
  });
}
