import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oxipress/core/file_system.dart';
import 'package:oxipress/core/providers.dart';
import 'package:oxipress/core/storage.dart';
import 'package:oxipress/features/project/domain/recent_project.dart';
import 'package:oxipress/features/project/ui/folder_picker.dart';
import 'package:oxipress/features/project/ui/project_controller.dart';
import 'package:oxipress/features/project/ui/welcome_screen.dart';

import '../../../helpers/fake_folder_picker.dart';
import '../../../helpers/pump_app.dart';

InMemoryFileSystem _validHugoSite() {
  return InMemoryFileSystem()
    ..addDirectory('/sites/sample/content')
    ..addFile('/sites/sample/hugo.toml');
}

InMemoryStorage _storageWithRecents(List<RecentProject> recents) {
  return InMemoryStorage({
    'recents.v1':
        jsonEncode(recents.map((r) => r.toJson()).toList()),
  });
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows app name, tagline, and Open Project button',
        (tester) async {
      await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage()),
          fileSystemProvider.overrideWithValue(InMemoryFileSystem()),
          folderPickerProvider.overrideWithValue(FakeFolderPicker()),
        ],
      );

      expect(find.text('OxiPress'), findsOneWidget);
      expect(
        find.text('Edit Hugo sites with live preview.'),
        findsOneWidget,
      );
      expect(find.text('Open Project'), findsOneWidget);
    });

    testWidgets('shows "No recent projects" when storage is empty',
        (tester) async {
      await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage()),
          fileSystemProvider.overrideWithValue(InMemoryFileSystem()),
          folderPickerProvider.overrideWithValue(FakeFolderPicker()),
        ],
      );

      expect(find.text('No recent projects yet.'), findsOneWidget);
    });

    testWidgets('lists recent projects from storage', (tester) async {
      final fs = InMemoryFileSystem()
        ..addDirectory('/sites/alpha')
        ..addDirectory('/sites/beta');
      final storage = _storageWithRecents([
        RecentProject(
          path: '/sites/alpha',
          name: 'alpha',
          lastOpenedAt: DateTime.now(),
        ),
        RecentProject(
          path: '/sites/beta',
          name: 'beta',
          lastOpenedAt: DateTime.now(),
        ),
      ]);

      await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(storage),
          fileSystemProvider.overrideWithValue(fs),
          folderPickerProvider.overrideWithValue(FakeFolderPicker()),
        ],
      );

      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(find.text('No recent projects yet.'), findsNothing);
    });

    testWidgets('Open Project calls the folder picker', (tester) async {
      final picker = FakeFolderPicker(); // returns null by default

      await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage()),
          fileSystemProvider.overrideWithValue(InMemoryFileSystem()),
          folderPickerProvider.overrideWithValue(picker),
        ],
      );

      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      expect(picker.callCount, 1);
    });

    testWidgets('opening a valid Hugo site transitions lifecycle to OpenProject',
        (tester) async {
      final fs = _validHugoSite();
      final picker = FakeFolderPicker(nextResult: '/sites/sample');

      final container = await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage()),
          fileSystemProvider.overrideWithValue(fs),
          folderPickerProvider.overrideWithValue(picker),
        ],
      );

      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      expect(
        container.read(projectControllerProvider),
        isA<OpenProject>(),
      );
    });

    testWidgets(
        'opening an invalid folder shows an error and stays on welcome',
        (tester) async {
      final fs = InMemoryFileSystem()..addDirectory('/sites/bad');
      final picker = FakeFolderPicker(nextResult: '/sites/bad');

      final container = await pumpAppWith(
        tester,
        const WelcomeScreen(),
        overrides: [
          storageProvider.overrideWithValue(InMemoryStorage()),
          fileSystemProvider.overrideWithValue(fs),
          folderPickerProvider.overrideWithValue(picker),
        ],
      );

      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      // Lifecycle should have been cleared back to idle by clearError().
      expect(
        container.read(projectControllerProvider),
        isA<IdleProject>(),
      );
      expect(
        find.textContaining('not a Hugo site'),
        findsOneWidget,
      );
    });
  });
}
