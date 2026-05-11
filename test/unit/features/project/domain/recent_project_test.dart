import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/project/domain/recent_project.dart';

void main() {
  group('RecentProject', () {
    test('JSON round-trip preserves all fields', () {
      final original = RecentProject(
        path: '/site',
        name: 'site',
        lastOpenedAt: DateTime.utc(2026, 5, 10, 9, 30),
      );
      final json = original.toJson();
      final restored = RecentProject.fromJson(
        Map<String, Object?>.from(json),
      );
      expect(restored, original);
    });

    test('copyWith updates only the specified fields', () {
      final r = RecentProject(
        path: '/site',
        name: 'site',
        lastOpenedAt: DateTime.utc(2026),
      );
      final updated = r.copyWith(lastOpenedAt: DateTime.utc(2027));
      expect(updated.path, r.path);
      expect(updated.name, r.name);
      expect(updated.lastOpenedAt, DateTime.utc(2027));
    });
  });
}
