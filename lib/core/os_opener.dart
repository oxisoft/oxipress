import 'dart:io' show Platform;

import 'process_runner.dart';

/// Opens a file or URL in the OS default application. Used by the file tree
/// when a non-markdown file is clicked.
abstract interface class OsOpener {
  Future<void> open(String path);
}

class RealOsOpener implements OsOpener {
  RealOsOpener({required ProcessRunner processRunner})
      : _runner = processRunner;

  final ProcessRunner _runner;

  @override
  Future<void> open(String path) async {
    final (executable, arguments) = _commandFor(path);
    await _runner.run(executable, arguments);
  }

  (String, List<String>) _commandFor(String path) {
    if (Platform.isMacOS) return ('open', [path]);
    if (Platform.isLinux) return ('xdg-open', [path]);
    if (Platform.isWindows) return ('cmd', ['/c', 'start', '', path]);
    return ('xdg-open', [path]);
  }
}

class RecordingOsOpener implements OsOpener {
  RecordingOsOpener();

  final List<String> openedPaths = [];

  @override
  Future<void> open(String path) async {
    openedPaths.add(path);
  }
}
