import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Abstraction over child-process invocation. All OS-process IO must go
/// through this interface so tests can substitute a fake.
abstract interface class ProcessRunner {
  /// Run a process to completion and capture stdout/stderr.
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });

  /// Spawn a long-running process and return a handle for streaming IO.
  Future<ProcessHandle> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class ProcessHandle {
  Stream<String> get stdout;
  Stream<String> get stderr;
  Future<int> get exitCode;
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return ProcessRunResult(
      exitCode: result.exitCode,
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }

  @override
  Future<ProcessHandle> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    return _SystemProcessHandle(process);
  }
}

class _SystemProcessHandle implements ProcessHandle {
  _SystemProcessHandle(this._process);

  final Process _process;

  @override
  Stream<String> get stdout =>
      _process.stdout.transform(utf8.decoder).asBroadcastStream();

  @override
  Stream<String> get stderr =>
      _process.stderr.transform(utf8.decoder).asBroadcastStream();

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      _process.kill(signal);
}

// ---------------------------------------------------------------------------
// Test-only fakes. Kept here (not in test/) so they are reusable across
// test/ and integration_test/ without duplicate implementations.
// ---------------------------------------------------------------------------

class RecordedInvocation {
  const RecordedInvocation({
    required this.executable,
    required this.arguments,
    this.workingDirectory,
    this.environment,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String>? environment;

  @override
  String toString() =>
      'RecordedInvocation($executable ${arguments.join(' ')} cwd=$workingDirectory)';
}

class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner();

  final List<RecordedInvocation> invocations = [];
  final Map<String, ProcessRunResult> _runResponses = {};

  void enqueueRunResult(String executable, ProcessRunResult result) {
    _runResponses[executable] = result;
  }

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    invocations.add(
      RecordedInvocation(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      ),
    );
    return _runResponses[executable] ??
        const ProcessRunResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Future<ProcessHandle> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    invocations.add(
      RecordedInvocation(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      ),
    );
    return _FakeProcessHandle();
  }
}

class _FakeProcessHandle implements ProcessHandle {
  final StreamController<String> _stdout =
      StreamController<String>.broadcast();
  final StreamController<String> _stderr =
      StreamController<String>.broadcast();
  final Completer<int> _exitCode = Completer<int>();

  @override
  Stream<String> get stdout => _stdout.stream;

  @override
  Stream<String> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exitCode.isCompleted) _exitCode.complete(-1);
    _stdout.close();
    _stderr.close();
    return true;
  }
}
