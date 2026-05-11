import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';
import '../../../core/result.dart';
import '../domain/hugo_site_validator.dart';
import '../domain/project.dart';
import '../domain/recent_project.dart';
import 'recents_store.dart';

abstract interface class ProjectRepository {
  Future<Result<Project, HugoSiteValidationError>> openProject(String path);
}

class DefaultProjectRepository implements ProjectRepository {
  DefaultProjectRepository({
    required FileSystem fileSystem,
    required RecentsStore recentsStore,
  })  : _fileSystem = fileSystem,
        _recentsStore = recentsStore;

  final FileSystem _fileSystem;
  final RecentsStore _recentsStore;

  @override
  Future<Result<Project, HugoSiteValidationError>> openProject(
    String path,
  ) async {
    final validation = await validateHugoSite(
      fileSystem: _fileSystem,
      path: path,
    );

    if (validation.isFailure) {
      return Result.failure(validation.errorOrNull!);
    }

    final kind = validation.valueOrNull!;
    final name = p.basename(path);
    final project = Project(path: path, name: name, configKind: kind);

    await _recentsStore.add(
      RecentProject(
        path: path,
        name: name,
        lastOpenedAt: DateTime.now(),
      ),
    );

    return Result.success(project);
  }
}
