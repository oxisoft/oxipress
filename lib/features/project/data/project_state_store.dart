import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';
import '../domain/workspace_state.dart';

/// Per-project persistence of [WorkspaceState] (panel sizes, collapsed flags,
/// expanded folders, tree root mode).
///
/// Each project gets its own `<projectPath>/.oxipress/workspace.json` so the
/// state travels with the project and is easy to inspect or reset. A sibling
/// `.gitignore` (containing `*`) is created so `.oxipress/` contents never
/// accidentally get committed.
class ProjectStateStore {
  ProjectStateStore(this._fileSystem);

  static const String dirName = '.oxipress';
  static const String _workspaceFile = 'workspace.json';
  static const String _gitignoreFile = '.gitignore';
  static const String _gitignoreBody = '*\n';

  final FileSystem _fileSystem;

  String _dirFor(String projectPath) => p.join(projectPath, dirName);

  String _workspacePath(String projectPath) =>
      p.join(_dirFor(projectPath), _workspaceFile);

  String _gitignorePath(String projectPath) =>
      p.join(_dirFor(projectPath), _gitignoreFile);

  Future<WorkspaceState> load(String projectPath) async {
    final path = _workspacePath(projectPath);
    if (!await _fileSystem.fileExists(path)) {
      return WorkspaceState.defaults;
    }
    try {
      final raw = await _fileSystem.readFileAsString(path);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return WorkspaceState.fromJson(decoded);
      }
    } on FormatException catch (_) {
      // fall through
    } on TypeError catch (_) {
      // fall through
    } on FileSystemException catch (_) {
      // fall through
    }
    return WorkspaceState.defaults;
  }

  Future<void> save(String projectPath, WorkspaceState state) async {
    final dir = _dirFor(projectPath);
    if (!await _fileSystem.directoryExists(dir)) {
      await _fileSystem.createDirectory(dir, recursive: true);
    }
    final gitignore = _gitignorePath(projectPath);
    if (!await _fileSystem.fileExists(gitignore)) {
      await _fileSystem.writeFileAsString(gitignore, _gitignoreBody);
    }
    await _fileSystem.writeFileAsString(
      _workspacePath(projectPath),
      jsonEncode(state.toJson()),
    );
  }

  Future<void> clear(String projectPath) async {
    final path = _workspacePath(projectPath);
    if (await _fileSystem.fileExists(path)) {
      await _fileSystem.deleteFile(path);
    }
  }
}
