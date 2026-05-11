import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/features/file_tree/data/file_tree_mutations.dart';
import 'package:path/path.dart' as p;

const _root = '/site';

InMemoryFileSystem _site() {
  return InMemoryFileSystem()
    ..addDirectory(p.join(_root, 'content'))
    ..addFile(p.join(_root, 'content', 'about.md'), content: '# About')
    ..addDirectory(p.join(_root, 'content', 'posts'))
    ..addFile(
      p.join(_root, 'content', 'posts', 'first.md'),
      content: 'first',
    );
}

void main() {
  group('createFile', () {
    test('writes content + returns the new path', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final result = await m.createFile(
        parentDir: p.join(_root, 'content'),
        name: 'new.md',
        content: 'hello',
      );
      expect(result.isSuccess, isTrue);
      final path = result.valueOrNull!;
      expect(path, p.join(_root, 'content', 'new.md'));
      expect(await fs.readFileAsString(path), 'hello');
    });

    test('refuses to overwrite an existing file', () async {
      final m = FileTreeMutations(_site());
      final result = await m.createFile(
        parentDir: p.join(_root, 'content'),
        name: 'about.md',
      );
      expect(result.errorOrNull, isA<AlreadyExistsError>());
    });

    test('rejects invalid names', () async {
      final m = FileTreeMutations(_site());
      expect(
        (await m.createFile(parentDir: _root, name: '')).errorOrNull,
        isA<InvalidNameError>(),
      );
      expect(
        (await m.createFile(parentDir: _root, name: 'foo/bar'))
            .errorOrNull,
        isA<InvalidNameError>(),
      );
      expect(
        (await m.createFile(parentDir: _root, name: 'CON.md'))
            .errorOrNull,
        isA<InvalidNameError>(),
      );
    });
  });

  group('createFolder', () {
    test('creates a new directory', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final result = await m.createFolder(
        parentDir: p.join(_root, 'content'),
        name: 'docs',
      );
      expect(result.isSuccess, isTrue);
      expect(
        await fs.directoryExists(p.join(_root, 'content', 'docs')),
        isTrue,
      );
    });

    test('refuses to overwrite an existing entry', () async {
      final m = FileTreeMutations(_site());
      final result = await m.createFolder(
        parentDir: _root,
        name: 'content',
      );
      expect(result.errorOrNull, isA<AlreadyExistsError>());
    });
  });

  group('rename', () {
    test('renames a file and returns the new path', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final old = p.join(_root, 'content', 'about.md');
      final result = await m.rename(
        absolutePath: old,
        newName: 'team.md',
      );
      expect(result.isSuccess, isTrue);
      final newPath = result.valueOrNull!;
      expect(await fs.fileExists(old), isFalse);
      expect(await fs.fileExists(newPath), isTrue);
      expect(await fs.readFileAsString(newPath), '# About');
    });

    test('renames a directory recursively', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final old = p.join(_root, 'content', 'posts');
      final result = await m.rename(
        absolutePath: old,
        newName: 'articles',
      );
      expect(result.isSuccess, isTrue);
      expect(
        await fs.directoryExists(p.join(_root, 'content', 'articles')),
        isTrue,
      );
      expect(
        await fs.fileExists(p.join(_root, 'content', 'articles', 'first.md')),
        isTrue,
      );
      expect(await fs.directoryExists(old), isFalse);
    });

    test('refuses to overwrite an existing entry', () async {
      final fs = _site()
        ..addFile(p.join(_root, 'content', 'team.md'));
      final m = FileTreeMutations(fs);
      final result = await m.rename(
        absolutePath: p.join(_root, 'content', 'about.md'),
        newName: 'team.md',
      );
      expect(result.errorOrNull, isA<AlreadyExistsError>());
    });

    test('no-op when renaming to the same name', () async {
      final m = FileTreeMutations(_site());
      final old = p.join(_root, 'content', 'about.md');
      final result = await m.rename(absolutePath: old, newName: 'about.md');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, old);
    });
  });

  group('delete', () {
    test('deletes a file', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final target = p.join(_root, 'content', 'about.md');
      final result = await m.delete(absolutePath: target);
      expect(result.isSuccess, isTrue);
      expect(await fs.fileExists(target), isFalse);
    });

    test('deletes a directory recursively', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final result = await m.delete(
        absolutePath: p.join(_root, 'content', 'posts'),
      );
      expect(result.isSuccess, isTrue);
      expect(
        await fs.directoryExists(p.join(_root, 'content', 'posts')),
        isFalse,
      );
      expect(
        await fs.fileExists(
          p.join(_root, 'content', 'posts', 'first.md'),
        ),
        isFalse,
      );
    });

    test('returns NotFound when the path does not exist', () async {
      final m = FileTreeMutations(_site());
      final result = await m.delete(absolutePath: '/site/nope.md');
      expect(result.errorOrNull, isA<NotFoundError>());
    });
  });

  group('duplicate', () {
    test('creates `<name>-copy.md` for a file', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final result = await m.duplicate(
        absolutePath: p.join(_root, 'content', 'about.md'),
      );
      expect(result.isSuccess, isTrue);
      expect(
        result.valueOrNull,
        p.join(_root, 'content', 'about-copy.md'),
      );
      expect(
        await fs.readFileAsString(p.join(_root, 'content', 'about-copy.md')),
        '# About',
      );
    });

    test('auto-suffixes on subsequent duplicates', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      await m.duplicate(absolutePath: p.join(_root, 'content', 'about.md'));
      final result = await m.duplicate(
        absolutePath: p.join(_root, 'content', 'about.md'),
      );
      expect(
        result.valueOrNull,
        p.join(_root, 'content', 'about-copy-2.md'),
      );
    });

    test('duplicates a directory recursively', () async {
      final fs = _site();
      final m = FileTreeMutations(fs);
      final result = await m.duplicate(
        absolutePath: p.join(_root, 'content', 'posts'),
      );
      expect(result.isSuccess, isTrue);
      final dup = p.join(_root, 'content', 'posts-copy');
      expect(await fs.directoryExists(dup), isTrue);
      expect(await fs.readFileAsString(p.join(dup, 'first.md')), 'first');
    });
  });
}
