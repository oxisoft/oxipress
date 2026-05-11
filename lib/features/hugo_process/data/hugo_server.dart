import 'dart:async';
import 'dart:io';

import '../../../core/logger.dart';
import '../../../core/process_runner.dart';
import '../domain/hugo_status.dart';

/// Owns the `hugo serve` subprocess for a project. Lifecycle:
/// stopped → starting → (running | errored). Tests substitute
/// [FakeHugoServer] for deterministic state transitions.
abstract interface class HugoServer {
  HugoStatus get status;
  Stream<HugoStatus> get statusStream;
  Stream<String> get stdout;
  Stream<String> get stderr;

  Future<void> start({
    required String projectPath,
    bool buildDrafts = true,
  });
  Future<void> stop();
  Future<void> restart();
  Future<void> dispose();
}

class SystemHugoServer implements HugoServer {
  SystemHugoServer({required ProcessRunner processRunner})
      : _runner = processRunner;

  final ProcessRunner _runner;
  final AppLogger _log = AppLogger('hugo_server');

  final StreamController<HugoStatus> _statusController =
      StreamController<HugoStatus>.broadcast();
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  HugoStatus _status = const HugoStopped();
  ProcessHandle? _handle;
  String? _lastProjectPath;
  bool _lastBuildDrafts = true;

  @override
  HugoStatus get status => _status;
  @override
  Stream<HugoStatus> get statusStream => _statusController.stream;
  @override
  Stream<String> get stdout => _stdoutController.stream;
  @override
  Stream<String> get stderr => _stderrController.stream;

  void _setStatus(HugoStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  Future<int> _allocatePort() async {
    final socket = await ServerSocket.bind('127.0.0.1', 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  @override
  Future<void> start({
    required String projectPath,
    bool buildDrafts = true,
  }) async {
    if (_status is HugoRunning || _status is HugoStarting) return;
    _lastProjectPath = projectPath;
    _lastBuildDrafts = buildDrafts;

    int port;
    try {
      port = await _allocatePort();
    } on Object catch (e) {
      _setStatus(HugoErrored(message: 'Could not allocate port: $e'));
      return;
    }

    _setStatus(HugoStarting(projectPath: projectPath, port: port));
    final args = <String>[
      'serve',
      '--bind',
      '127.0.0.1',
      '--port',
      '$port',
      if (buildDrafts) '--buildDrafts',
      '--buildFuture',
      '--noHTTPCache',
      '--disableFastRender',
    ];
    _log.info('starting hugo', fields: {'port': port, 'path': projectPath});

    try {
      _handle = await _runner.start(
        'hugo',
        args,
        workingDirectory: projectPath,
      );
    } on Object catch (e) {
      _setStatus(HugoErrored(message: 'Failed to spawn hugo: $e'));
      return;
    }

    _handle!.stdout.listen(
      (line) {
        if (!_stdoutController.isClosed) _stdoutController.add(line);
        if (_status is HugoStarting && _isReadyLine(line)) {
          _setStatus(HugoRunning(projectPath: projectPath, port: port));
        }
      },
      onError: (Object e) {
        _log.warn('hugo stdout error', fields: {'error': e.toString()});
      },
    );
    _handle!.stderr.listen(
      (line) {
        if (!_stderrController.isClosed) _stderrController.add(line);
      },
      onError: (Object e) {
        _log.warn('hugo stderr error', fields: {'error': e.toString()});
      },
    );
    unawaited(_handle!.exitCode.then((code) {
      _handle = null;
      if (_status is HugoStopped) return;
      _setStatus(HugoErrored(
        message: 'Hugo exited',
        exitCode: code,
      ));
    }));
  }

  bool _isReadyLine(String line) =>
      line.contains('Web Server is available at') ||
      line.contains('Press Ctrl+C to stop');

  @override
  Future<void> stop() async {
    final handle = _handle;
    _handle = null;
    _setStatus(const HugoStopped());
    if (handle == null) return;
    handle.kill();
    try {
      await handle.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException catch (_) {
      handle.kill(ProcessSignal.sigkill);
      try {
        await handle.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException catch (_) {
        _log.warn('hugo did not exit after SIGKILL');
      }
    }
  }

  @override
  Future<void> restart() async {
    final path = _lastProjectPath;
    final drafts = _lastBuildDrafts;
    await stop();
    if (path != null) {
      await start(projectPath: path, buildDrafts: drafts);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _statusController.close();
    await _stdoutController.close();
    await _stderrController.close();
  }
}

/// In-memory fake that lets tests drive [HugoStatus] transitions directly.
class FakeHugoServer implements HugoServer {
  FakeHugoServer();

  final StreamController<HugoStatus> _statusController =
      StreamController<HugoStatus>.broadcast();
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  HugoStatus _status = const HugoStopped();

  @override
  HugoStatus get status => _status;
  @override
  Stream<HugoStatus> get statusStream => _statusController.stream;
  @override
  Stream<String> get stdout => _stdoutController.stream;
  @override
  Stream<String> get stderr => _stderrController.stream;

  int port = 1313;

  void emitStatus(HugoStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  void emitStdout(String line) {
    if (!_stdoutController.isClosed) _stdoutController.add(line);
  }

  void emitStderr(String line) {
    if (!_stderrController.isClosed) _stderrController.add(line);
  }

  @override
  Future<void> start({
    required String projectPath,
    bool buildDrafts = true,
  }) async {
    emitStatus(HugoStarting(projectPath: projectPath, port: port));
    emitStatus(HugoRunning(projectPath: projectPath, port: port));
  }

  @override
  Future<void> stop() async {
    emitStatus(const HugoStopped());
  }

  @override
  Future<void> restart() async {
    final s = _status;
    if (s is HugoRunning) {
      await stop();
      await start(projectPath: s.projectPath);
    } else if (s is HugoStarting) {
      await stop();
      await start(projectPath: s.projectPath);
    }
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _stdoutController.close();
    await _stderrController.close();
  }
}
