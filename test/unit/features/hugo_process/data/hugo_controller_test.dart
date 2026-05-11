import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/file_watcher.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/hugo_process/data/hugo_providers.dart';
import 'package:oxipress/features/hugo_process/data/hugo_server.dart';
import 'package:oxipress/features/hugo_process/domain/hugo_status.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';

const _projectPath = '/sites/sample';

InMemoryFileSystem _hugoSite() {
  return InMemoryFileSystem()
    ..addFile('$_projectPath/hugo.toml')
    ..addDirectory('$_projectPath/content');
}

ProviderContainer _container({
  required InMemoryFileSystem fs,
  required FakeHugoServer hugo,
  FakeFileWatcher? watcher,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      storageProvider.overrideWithValue(InMemoryStorage()),
      fileSystemProvider.overrideWithValue(fs),
      fileWatcherProvider.overrideWithValue(watcher ?? FakeFileWatcher()),
      hugoServerProvider.overrideWithValue(hugo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('HugoController', () {
    test('starts Hugo when a project opens', () async {
      final fs = _hugoSite();
      final hugo = FakeHugoServer();
      final container = _container(fs: fs, hugo: hugo);

      // Subscribe so the controller is built.
      container.listen<HugoStatus>(hugoControllerProvider, (_, _) {});
      expect(container.read(hugoControllerProvider), isA<HugoStopped>());

      await container
          .read(projectControllerProvider.notifier)
          .openProject(_projectPath);
      // Allow the controller's start() future to complete.
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(hugoControllerProvider),
        isA<HugoRunning>(),
      );
    });

    test('stops Hugo when the project closes', () async {
      final fs = _hugoSite();
      final hugo = FakeHugoServer();
      final container = _container(fs: fs, hugo: hugo);
      container.listen<HugoStatus>(hugoControllerProvider, (_, _) {});

      await container
          .read(projectControllerProvider.notifier)
          .openProject(_projectPath);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hugoControllerProvider), isA<HugoRunning>());

      container.read(projectControllerProvider.notifier).close();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hugoControllerProvider), isA<HugoStopped>());
    });

    test('restarts Hugo when hugo.toml changes', () async {
      final fs = _hugoSite();
      final hugo = FakeHugoServer();
      final watcher = FakeFileWatcher();
      final container = _container(fs: fs, hugo: hugo, watcher: watcher);
      container.listen<HugoStatus>(hugoControllerProvider, (_, _) {});

      await container
          .read(projectControllerProvider.notifier)
          .openProject(_projectPath);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hugoControllerProvider), isA<HugoRunning>());

      // Trigger a config-file event via the watcher.
      watcher.emit(
        _projectPath,
        const FsChange(
          type: FsChangeType.modified,
          path: '$_projectPath/hugo.toml',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      // Status passes through Stopped + Starting + Running; final state Running.
      expect(container.read(hugoControllerProvider), isA<HugoRunning>());
    });
  });
}
