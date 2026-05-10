import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/process_runner.dart';

void main() {
  group('FakeProcessRunner', () {
    test('records run invocations and returns enqueued result', () async {
      final runner = FakeProcessRunner()
        ..enqueueRunResult(
          'hugo',
          const ProcessRunResult(
            exitCode: 0,
            stdout: 'hugo v0.115.0',
            stderr: '',
          ),
        );

      final result = await runner.run(
        'hugo',
        ['version'],
        workingDirectory: '/tmp',
      );

      expect(result.exitCode, 0);
      expect(result.stdout, 'hugo v0.115.0');
      expect(runner.invocations, hasLength(1));
      expect(runner.invocations.first.executable, 'hugo');
      expect(runner.invocations.first.arguments, ['version']);
      expect(runner.invocations.first.workingDirectory, '/tmp');
    });

    test('returns default result when no enqueue matches', () async {
      final runner = FakeProcessRunner();
      final result = await runner.run('git', const ['status']);
      expect(result.exitCode, 0);
      expect(result.stdout, '');
      expect(result.stderr, '');
    });

    test('start() records invocation and returns a killable handle', () async {
      final runner = FakeProcessRunner();
      final handle = await runner.start('hugo', const ['serve']);

      expect(runner.invocations, hasLength(1));
      expect(runner.invocations.first.executable, 'hugo');

      handle.kill();
      expect(await handle.exitCode, -1);
    });
  });
}
