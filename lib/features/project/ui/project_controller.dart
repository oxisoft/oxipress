import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../data/project_providers.dart';
import '../domain/hugo_site_validator.dart';
import '../domain/project.dart';
import 'recents_controller.dart';

/// Lifecycle of the currently-open project.
sealed class ProjectLifecycle {
  const ProjectLifecycle();
}

final class IdleProject extends ProjectLifecycle {
  const IdleProject();
}

final class OpeningProject extends ProjectLifecycle {
  const OpeningProject(this.path);
  final String path;
}

final class OpenProject extends ProjectLifecycle {
  const OpenProject(this.project);
  final Project project;
}

final class ProjectOpenError extends ProjectLifecycle {
  const ProjectOpenError(this.error, this.path);
  final HugoSiteValidationError error;
  final String path;
}

class ProjectController extends Notifier<ProjectLifecycle> {
  @override
  ProjectLifecycle build() => const IdleProject();

  Future<void> openProject(String path) async {
    state = OpeningProject(path);
    final repo = ref.read(projectRepositoryProvider);
    final result = await repo.openProject(path);
    final next = switch (result) {
      Success<Project, HugoSiteValidationError>(:final value) =>
        OpenProject(value),
      Failure<Project, HugoSiteValidationError>(:final error) =>
        ProjectOpenError(error, path),
    };
    state = next;
    if (next is OpenProject) {
      ref.invalidate(recentsProvider);
    }
  }

  void close() {
    state = const IdleProject();
  }

  void clearError() {
    if (state is ProjectOpenError) {
      state = const IdleProject();
    }
  }
}

final projectControllerProvider =
    NotifierProvider<ProjectController, ProjectLifecycle>(
  ProjectController.new,
);
