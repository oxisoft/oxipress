import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:path/path.dart' as p;

void main() {
  group('InMemoryFileSystem', () {
    test('reports added directory and file existence', () async {
      final fs = InMemoryFileSystem()
        ..addDirectory(p.join('site', 'content'))
        ..addFile(p.join('site', 'content', 'about.md'));

      expect(await fs.directoryExists(p.join('site', 'content')), isTrue);
      expect(
        await fs.fileExists(p.join('site', 'content', 'about.md')),
        isTrue,
      );
      expect(await fs.fileExists(p.join('site', 'content')), isFalse);
      expect(
        await fs.directoryExists(p.join('site', 'missing')),
        isFalse,
      );
    });

    test('auto-creates parent directories on addFile', () async {
      final fs = InMemoryFileSystem()
        ..addFile(p.join('a', 'b', 'c', 'file.md'));
      expect(await fs.directoryExists('a'), isTrue);
      expect(await fs.directoryExists(p.join('a', 'b')), isTrue);
      expect(await fs.directoryExists(p.join('a', 'b', 'c')), isTrue);
    });

    test('listDirectory returns only direct children', () async {
      final fs = InMemoryFileSystem()
        ..addFile(p.join('site', 'content', 'a.md'))
        ..addFile(p.join('site', 'content', 'b.md'))
        ..addFile(p.join('site', 'content', 'posts', 'p1.md'))
        ..addDirectory(p.join('site', 'content', 'docs'));

      final entries =
          await fs.listDirectory(p.join('site', 'content'));
      final names = entries.map((e) => e.name).toList()..sort();
      expect(names, ['a.md', 'b.md', 'docs', 'posts']);

      final aEntry = entries.firstWhere((e) => e.name == 'a.md');
      expect(aEntry.isFile, isTrue);
      expect(aEntry.isDirectory, isFalse);
      final postsEntry = entries.firstWhere((e) => e.name == 'posts');
      expect(postsEntry.isDirectory, isTrue);
    });

    test('listDirectory throws on non-existent path', () async {
      final fs = InMemoryFileSystem();
      expect(
        () => fs.listDirectory('nope'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('removeEntry deletes a file', () async {
      final fs = InMemoryFileSystem()
        ..addFile('foo.md')
        ..removeEntry('foo.md');
      expect(await fs.fileExists('foo.md'), isFalse);
    });

    test('readFileAsString returns stored content', () async {
      final fs = InMemoryFileSystem()
        ..addFile('hello.md', content: '# Hello');
      expect(await fs.readFileAsString('hello.md'), '# Hello');
    });

    test('readFileAsString throws when file is missing', () async {
      final fs = InMemoryFileSystem();
      expect(
        () => fs.readFileAsString('nope.md'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('writeFileAsString creates the file (and parent dirs)', () async {
      final fs = InMemoryFileSystem();
      await fs.writeFileAsString(
        p.join('a', 'b', 'note.md'),
        'body',
      );
      expect(await fs.fileExists(p.join('a', 'b', 'note.md')), isTrue);
      expect(await fs.directoryExists(p.join('a', 'b')), isTrue);
      expect(
        await fs.readFileAsString(p.join('a', 'b', 'note.md')),
        'body',
      );
    });

    test('createDirectory(recursive) creates intermediate dirs', () async {
      final fs = InMemoryFileSystem();
      await fs.createDirectory(p.join('x', 'y', 'z'), recursive: true);
      expect(await fs.directoryExists('x'), isTrue);
      expect(await fs.directoryExists(p.join('x', 'y')), isTrue);
      expect(await fs.directoryExists(p.join('x', 'y', 'z')), isTrue);
    });

    test('createDirectory non-recursive throws if parent missing',
        () async {
      final fs = InMemoryFileSystem();
      expect(
        () => fs.createDirectory(p.join('x', 'y')),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('deleteFile removes the file', () async {
      final fs = InMemoryFileSystem()..addFile('a.md');
      await fs.deleteFile('a.md');
      expect(await fs.fileExists('a.md'), isFalse);
    });
  });
}
