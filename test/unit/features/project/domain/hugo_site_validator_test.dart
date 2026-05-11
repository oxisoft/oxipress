import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/features/project/domain/hugo_site_validator.dart';
import 'package:oxipress/features/project/domain/project.dart';
import 'package:path/path.dart' as p;

void main() {
  group('validateHugoSite', () {
    test('accepts a folder with hugo.toml + content/', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'))
        ..addFile(p.join('site', 'hugo.toml'));

      final result =
          await validateHugoSite(fileSystem: fs, path: 'site');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, HugoConfigKind.toml);
    });

    test('accepts hugo.yaml and hugo.json', () async {
      final fsYaml = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'))
        ..addFile(p.join('site', 'hugo.yaml'));
      final fsJson = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'))
        ..addFile(p.join('site', 'hugo.json'));

      expect(
        (await validateHugoSite(fileSystem: fsYaml, path: 'site'))
            .valueOrNull,
        HugoConfigKind.yaml,
      );
      expect(
        (await validateHugoSite(fileSystem: fsJson, path: 'site'))
            .valueOrNull,
        HugoConfigKind.json,
      );
    });

    test('accepts legacy config.toml/yaml/json', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'))
        ..addFile(p.join('site', 'config.toml'));
      final result =
          await validateHugoSite(fileSystem: fs, path: 'site');
      expect(result.valueOrNull, HugoConfigKind.legacyToml);
      expect(HugoConfigKind.legacyToml.isLegacy, isTrue);
    });

    test('fails when path does not exist', () async {
      final fs = InMemoryFileSystem();
      final result =
          await validateHugoSite(fileSystem: fs, path: 'nope');
      expect(
        result.errorOrNull,
        HugoSiteValidationError.pathDoesNotExist,
      );
    });

    test('fails when content/ is missing', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory('site')
        ..addFile(p.join('site', 'hugo.toml'));
      final result =
          await validateHugoSite(fileSystem: fs, path: 'site');
      expect(
        result.errorOrNull,
        HugoSiteValidationError.missingContentDirectory,
      );
    });

    test('fails when no Hugo config file is present', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'));
      final result =
          await validateHugoSite(fileSystem: fs, path: 'site');
      expect(
        result.errorOrNull,
        HugoSiteValidationError.missingHugoConfig,
      );
    });
  });
}
