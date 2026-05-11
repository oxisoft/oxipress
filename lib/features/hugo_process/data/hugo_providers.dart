import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/file_watcher.dart';
import '../../../core/providers.dart';
import '../../project/ui/project_controller.dart';
import '../domain/hugo_status.dart';
import 'hugo_server.dart';

/// Singleton [HugoServer] instance, disposed with the container. Override
/// in tests with `hugoServerProvider.overrideWithValue(FakeHugoServer())`.
final hugoServerProvider = Provider<HugoServer>((ref) {
  final server = SystemHugoServer(
    processRunner: ref.read(processRunnerProvider),
  );
  ref.onDispose(() {
    unawaited(server.dispose());
  });
  return server;
});

const Set<String> _hugoConfigFilenames = {
  'hugo.toml',
  'hugo.yaml',
  'hugo.json',
  'config.toml',
  'config.yaml',
  'config.json',
};

/// Riverpod-managed [HugoStatus] for the active project. Auto-starts Hugo
/// when a project opens, stops it on close, and restarts on config-file
/// changes.
class HugoController extends Notifier<HugoStatus> {
  StreamSubscription<HugoStatus>? _statusSub;
  StreamSubscription<FsChange>? _watcherSub;

  @override
  HugoStatus build() {
    final server = ref.watch(hugoServerProvider);

    _statusSub?.cancel();
    _statusSub = server.statusStream.listen(_onStatus);

    ref.listen(projectControllerProvider, _onProjectChange);

    final current = ref.read(projectControllerProvider);
    if (current is OpenProject && server.status is HugoStopped) {
      unawaited(server.start(projectPath: current.project.path));
      _attachConfigWatcher(current.project.path);
    }

    ref.onDispose(() {
      _statusSub?.cancel();
      _watcherSub?.cancel();
    });

    return server.status;
  }

  void _onStatus(HugoStatus s) {
    state = s;
  }

  void _onProjectChange(ProjectLifecycle? prev, ProjectLifecycle next) {
    final server = ref.read(hugoServerProvider);
    if (next is OpenProject) {
      if (prev is OpenProject &&
          prev.project.path == next.project.path) {
        return;
      }
      unawaited(server.start(projectPath: next.project.path));
      _attachConfigWatcher(next.project.path);
    } else {
      _watcherSub?.cancel();
      _watcherSub = null;
      unawaited(server.stop());
    }
  }

  void _attachConfigWatcher(String projectPath) {
    _watcherSub?.cancel();
    final watcher = ref.read(fileWatcherProvider);
    _watcherSub = watcher.watch(projectPath).listen((event) {
      final name = p.basename(event.path).toLowerCase();
      if (_hugoConfigFilenames.contains(name)) {
        unawaited(ref.read(hugoServerProvider).restart());
      }
    });
  }

  Future<void> start() async {
    final lifecycle = ref.read(projectControllerProvider);
    if (lifecycle is OpenProject) {
      await ref
          .read(hugoServerProvider)
          .start(projectPath: lifecycle.project.path);
    }
  }

  Future<void> stop() async {
    await ref.read(hugoServerProvider).stop();
  }

  Future<void> restart() async {
    await ref.read(hugoServerProvider).restart();
  }
}

final hugoControllerProvider =
    NotifierProvider<HugoController, HugoStatus>(HugoController.new);
