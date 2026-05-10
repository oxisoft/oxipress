import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the editor's frontmatter section is expanded. Hidden by default
/// so the body editor uses the full vertical space. Phase 10 may wire a
/// persistent setting; for now this lives only in memory.
class FrontmatterVisibilityController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setExpanded({required bool expanded}) {
    state = expanded;
  }
}

final frontmatterVisibilityProvider =
    NotifierProvider<FrontmatterVisibilityController, bool>(
  FrontmatterVisibilityController.new,
);
