import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/features/file_tree/domain/file_tree_node.dart';

FileTreeNode _file(String name) =>
    FileTreeNode(path: '/site/content/$name', name: name, isDirectory: false);
FileTreeNode _dir(String name) =>
    FileTreeNode(path: '/site/content/$name', name: name, isDirectory: true);

void main() {
  group('FileTreeNode', () {
    test('isMarkdown is true for .md and .markdown', () {
      expect(_file('a.md').isMarkdown, isTrue);
      expect(_file('a.markdown').isMarkdown, isTrue);
      expect(_file('a.txt').isMarkdown, isFalse);
      expect(_dir('posts').isMarkdown, isFalse);
    });

    test('compare puts directories before files', () {
      final nodes = <FileTreeNode>[
        _file('about.md'),
        _dir('posts'),
        _file('z.md'),
        _dir('docs'),
      ]..sort(FileTreeNode.compare);
      expect(
        nodes.map((n) => n.name).toList(),
        ['docs', 'posts', 'about.md', 'z.md'],
      );
    });

    test('compare uses case-insensitive name within each kind', () {
      final nodes = <FileTreeNode>[
        _file('Banana.md'),
        _file('apple.md'),
        _file('cherry.md'),
      ]..sort(FileTreeNode.compare);
      expect(
        nodes.map((n) => n.name).toList(),
        ['apple.md', 'Banana.md', 'cherry.md'],
      );
    });
  });
}
