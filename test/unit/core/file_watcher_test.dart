import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_watcher.dart';

void main() {
  group('FakeFileWatcher', () {
    test('emits events to the watch stream for the matching path',
        () async {
      final watcher = FakeFileWatcher();
      final received = <FsChange>[];
      final sub = watcher.watch('/a').listen(received.add);

      watcher.emit('/a',
          const FsChange(type: FsChangeType.added, path: '/a/foo.md'));
      watcher.emit('/a',
          const FsChange(type: FsChangeType.modified, path: '/a/foo.md'));

      // Wait one event-loop turn for the broadcast to flush.
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0].type, FsChangeType.added);
      expect(received[1].type, FsChangeType.modified);

      await sub.cancel();
      await watcher.close();
    });

    test('does not deliver events to unrelated subscribers', () async {
      final watcher = FakeFileWatcher();
      final received = <FsChange>[];
      final sub = watcher.watch('/a').listen(received.add);

      watcher.emit('/b',
          const FsChange(type: FsChangeType.added, path: '/b/foo.md'));
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);

      await sub.cancel();
      await watcher.close();
    });
  });
}
