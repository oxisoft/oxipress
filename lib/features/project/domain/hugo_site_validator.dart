import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';
import '../../../core/result.dart';
import 'project.dart';

enum HugoSiteValidationError {
  pathDoesNotExist,
  notADirectory,
  missingContentDirectory,
  missingHugoConfig,
}

extension HugoSiteValidationErrorMessage on HugoSiteValidationError {
  String get message => switch (this) {
        HugoSiteValidationError.pathDoesNotExist =>
          'The selected folder does not exist.',
        HugoSiteValidationError.notADirectory =>
          'The selected path is not a folder.',
        HugoSiteValidationError.missingContentDirectory =>
          'The folder does not contain a "content/" directory.',
        HugoSiteValidationError.missingHugoConfig =>
          'The folder does not contain a Hugo configuration file '
              '(hugo.toml/yaml/json or legacy config.*).',
      };
}

/// Validates that [path] is a Hugo site root by checking for both a Hugo
/// config file and a `content/` directory.
Future<Result<HugoConfigKind, HugoSiteValidationError>> validateHugoSite({
  required FileSystem fileSystem,
  required String path,
}) async {
  if (!await fileSystem.directoryExists(path)) {
    return const Result.failure(HugoSiteValidationError.pathDoesNotExist);
  }

  final contentPath = p.join(path, 'content');
  if (!await fileSystem.directoryExists(contentPath)) {
    return const Result.failure(
      HugoSiteValidationError.missingContentDirectory,
    );
  }

  for (final kind in HugoConfigKind.values) {
    final configPath = p.join(path, kind.filename);
    if (await fileSystem.fileExists(configPath)) {
      return Result.success(kind);
    }
  }

  return const Result.failure(HugoSiteValidationError.missingHugoConfig);
}
