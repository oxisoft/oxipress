import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/project_providers.dart';
import '../domain/recent_project.dart';

class RecentsController extends AsyncNotifier<List<RecentProject>> {
  @override
  Future<List<RecentProject>> build() async {
    final store = ref.read(recentsStoreProvider);
    final fs = ref.read(fileSystemProvider);
    return store.prune(fs);
  }

  Future<void> remove(String path) async {
    final store = ref.read(recentsStoreProvider);
    final updated = await store.remove(path);
    state = AsyncValue.data(updated);
  }
}

final recentsProvider =
    AsyncNotifierProvider<RecentsController, List<RecentProject>>(
  RecentsController.new,
);
