import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/project_identity.dart';

void main() {
  group('ProjectIdentity.forPath', () {
    test('returns the same key for the same canonicalized path', () {
      final a = ProjectIdentity.forPath('/users/me/site');
      final b = ProjectIdentity.forPath('/users/me/site');
      expect(a, b);
    });

    test('returns different keys for different paths', () {
      final a = ProjectIdentity.forPath('/users/me/siteA');
      final b = ProjectIdentity.forPath('/users/me/siteB');
      expect(a, isNot(b));
    });

    test('normalizes redundant segments', () {
      final a = ProjectIdentity.forPath('/users/me/site');
      final b = ProjectIdentity.forPath('/users/me/foo/../site');
      expect(a, b);
    });

    test('produces a key safe to use in storage (no padding)', () {
      final key = ProjectIdentity.forPath('/foo/bar');
      expect(key, isNot(contains('=')));
    });
  });
}
