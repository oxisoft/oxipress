import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/paths.dart';

void main() {
  group('resolveConfigDirPath', () {
    test('Linux honors XDG_CONFIG_HOME when set', () {
      final path = resolveConfigDirPath(
        operatingSystem: 'linux',
        environment: const {'XDG_CONFIG_HOME': '/custom/xdg'},
        fallbackAppSupport: '/should/not/be/used',
        appName: 'oxipress',
      );
      expect(path, '/custom/xdg/oxipress');
    });

    test('Linux falls back to \$HOME/.config when XDG missing', () {
      final path = resolveConfigDirPath(
        operatingSystem: 'linux',
        environment: const {'HOME': '/home/me'},
        fallbackAppSupport: '/should/not/be/used',
        appName: 'oxipress',
      );
      expect(path, '/home/me/.config/oxipress');
    });

    test('Linux falls back to provided app-support path when no env', () {
      final path = resolveConfigDirPath(
        operatingSystem: 'linux',
        environment: const {},
        fallbackAppSupport: '/var/oxipress',
        appName: 'oxipress',
      );
      expect(path, '/var/oxipress');
    });

    test('non-Linux uses provided app-support path', () {
      for (final os in ['macos', 'windows']) {
        final path = resolveConfigDirPath(
          operatingSystem: os,
          environment: const {'XDG_CONFIG_HOME': '/should/not/be/used'},
          fallbackAppSupport: '/app/support/oxipress',
          appName: 'oxipress',
        );
        expect(path, '/app/support/oxipress', reason: 'os=$os');
      }
    });
  });
}
