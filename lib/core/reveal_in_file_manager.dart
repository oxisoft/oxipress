import 'dart:io' show Platform;

import 'package:path/path.dart' as p;

import 'process_runner.dart';

/// Reveals a file or folder in the host OS's file manager. On macOS this
/// selects the item in Finder; on Windows it selects in Explorer; on Linux
/// it opens the parent directory in the user's preferred file manager.
abstract interface class RevealInFileManager {
  Future<void> reveal(String absolutePath);
}

/// Pure dispatch: which command to run for a given OS + path. Exposed for
/// unit testing so we don't depend on the host platform.
(String executable, List<String> arguments) revealCommandFor({
  required String operatingSystem,
  required String absolutePath,
}) {
  switch (operatingSystem) {
    case 'macos':
      return ('open', ['-R', absolutePath]);
    case 'windows':
      return ('explorer', ['/select,$absolutePath']);
    default:
      return ('xdg-open', [p.dirname(absolutePath)]);
  }
}

class RealRevealInFileManager implements RevealInFileManager {
  RealRevealInFileManager({required ProcessRunner processRunner})
      : _runner = processRunner;

  final ProcessRunner _runner;

  @override
  Future<void> reveal(String absolutePath) async {
    final (executable, arguments) = revealCommandFor(
      operatingSystem: Platform.operatingSystem,
      absolutePath: absolutePath,
    );
    await _runner.run(executable, arguments);
  }
}

class RecordingRevealInFileManager implements RevealInFileManager {
  RecordingRevealInFileManager();

  final List<String> revealedPaths = [];

  @override
  Future<void> reveal(String absolutePath) async {
    revealedPaths.add(absolutePath);
  }
}
