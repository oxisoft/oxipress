import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/os_opener.dart';

void main() {
  group('RecordingOsOpener', () {
    test('records every opened path in order', () async {
      final opener = RecordingOsOpener();
      await opener.open('/tmp/a.png');
      await opener.open('/tmp/b.svg');
      expect(opener.openedPaths, ['/tmp/a.png', '/tmp/b.svg']);
    });
  });
}
