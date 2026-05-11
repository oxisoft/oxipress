import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks files whose on-disk content changed externally while the user has
/// unsaved edits in the corresponding `EditorBuffer`. The UI watches this
/// set and shows a "keep mine / reload disk" prompt for each newly added
/// path.
class ExternalChangesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void mark(String absolutePath) {
    if (state.contains(absolutePath)) return;
    state = {...state, absolutePath};
  }

  void resolve(String absolutePath) {
    if (!state.contains(absolutePath)) return;
    state = state.where((p) => p != absolutePath).toSet();
  }

  void clear() {
    if (state.isEmpty) return;
    state = const {};
  }
}

final externalChangesProvider =
    NotifierProvider<ExternalChangesController, Set<String>>(
  ExternalChangesController.new,
);
