import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves OS-appropriate config directories.
///
/// Spec mapping:
/// - Linux:   `$XDG_CONFIG_HOME/oxipress/` or `~/.config/oxipress/`
/// - macOS:   `~/Library/Application Support/io.oxisoft.oxipress/`
/// - Windows: `%APPDATA%\io.oxisoft\oxipress\`
class Paths {
  Paths._();

  static const String appName = 'oxipress';

  /// Application configuration directory. Created if missing.
  static Future<Directory> configDir() async {
    final dir = await _resolveConfigDir();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Path to a config file under the app's config dir, creating parent dirs.
  static Future<File> configFile(String relativePath) async {
    final dir = await configDir();
    final file = File(p.join(dir.path, relativePath));
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    return file;
  }

  /// User-extensible themes dir: `<configDir>/themes/`. Created if missing.
  static Future<Directory> userThemesDir() async {
    final dir = await configDir();
    final themes = Directory(p.join(dir.path, 'themes'));
    if (!themes.existsSync()) {
      themes.createSync(recursive: true);
    }
    return themes;
  }

  static Future<Directory> _resolveConfigDir() async {
    final fallback = await getApplicationSupportDirectory();
    final resolved = resolveConfigDirPath(
      operatingSystem: Platform.operatingSystem,
      environment: Platform.environment,
      fallbackAppSupport: fallback.path,
      appName: appName,
    );
    return Directory(resolved);
  }
}

/// Pure resolver for the config dir path. Exposed for unit testing without
/// touching the real filesystem or `path_provider` plugins.
String resolveConfigDirPath({
  required String operatingSystem,
  required Map<String, String> environment,
  required String fallbackAppSupport,
  required String appName,
}) {
  if (operatingSystem == 'linux') {
    final xdg = environment['XDG_CONFIG_HOME'];
    if (xdg != null && xdg.isNotEmpty) {
      return p.join(xdg, appName);
    }
    final home = environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, '.config', appName);
    }
  }
  return fallbackAppSupport;
}
