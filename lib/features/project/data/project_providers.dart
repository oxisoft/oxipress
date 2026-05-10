import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'project_repository.dart';
import 'project_state_store.dart';
import 'recents_store.dart';

final recentsStoreProvider = Provider<RecentsStore>(
  (ref) => RecentsStore(ref.watch(storageProvider)),
);

final projectStateStoreProvider = Provider<ProjectStateStore>(
  (ref) => ProjectStateStore(ref.watch(fileSystemProvider)),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => DefaultProjectRepository(
    fileSystem: ref.watch(fileSystemProvider),
    recentsStore: ref.watch(recentsStoreProvider),
  ),
);
