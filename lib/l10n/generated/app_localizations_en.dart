// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OxiPress';

  @override
  String get welcomeTagline => 'Edit Hugo sites with live preview.';

  @override
  String get openProject => 'Open Project';

  @override
  String get openingProject => 'Opening project…';

  @override
  String get recentProjects => 'Recent projects';

  @override
  String get noRecentProjects => 'No recent projects yet.';

  @override
  String get documentation => 'Documentation';

  @override
  String get documentationComingSoon =>
      'Documentation site is not yet published.';

  @override
  String get removeFromRecents => 'Remove from recents';

  @override
  String get errorPathDoesNotExist => 'The selected folder does not exist.';

  @override
  String get errorMissingContentDirectory =>
      'The selected folder is not a Hugo site (missing content/ directory).';

  @override
  String get errorMissingHugoConfig =>
      'The selected folder is not a Hugo site (no hugo.toml/yaml/json or legacy config.* found).';

  @override
  String get errorNotADirectory => 'The selected path is not a folder.';

  @override
  String get panelTitleFiles => 'Files';

  @override
  String get panelTitleEditor => 'Editor';

  @override
  String get panelTitlePreview => 'Preview';

  @override
  String get collapsePanel => 'Collapse panel';

  @override
  String get expandPanel => 'Expand panel';

  @override
  String get treeRootContent => 'Show content folder';

  @override
  String get treeRootProjectRoot => 'Show project root';

  @override
  String get treeEmpty => 'This directory is empty.';

  @override
  String get treeNoProject => 'No project open.';

  @override
  String get editorPlaceholder => 'Open a markdown file from the tree.';

  @override
  String get editorEmptyBody => '(empty body)';

  @override
  String get editorModeRaw => 'Raw';

  @override
  String get editorModeRich => 'Rich';

  @override
  String get editorModeRichComingSoon => 'Rich-text mode arrives in Phase 9.';

  @override
  String get editorTabListTooltip => 'Show all open tabs';

  @override
  String get externalChangeTitle => 'File changed on disk';

  @override
  String externalChangeBody(String path) {
    return '$path changed externally while you have unsaved edits. What do you want to do?';
  }

  @override
  String get externalChangeKeepMine => 'Keep my changes';

  @override
  String get externalChangeReloadDisk => 'Reload from disk (lose changes)';

  @override
  String get findReplaceTitle => 'Find / Replace';

  @override
  String get findHint => 'Find';

  @override
  String get replaceHint => 'Replace';

  @override
  String get findCaseSensitive => 'Case sensitive';

  @override
  String get findWholeWord => 'Whole word';

  @override
  String get findRegex => 'Regex';

  @override
  String get findPrev => 'Previous match';

  @override
  String get findNext => 'Next match';

  @override
  String get findReplaceOne => 'Replace';

  @override
  String get findReplaceAll => 'Replace all';

  @override
  String get findClose => 'Close find/replace';

  @override
  String findMatchCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get findNoMatches => 'No matches';

  @override
  String get closeTabUnsavedTitle => 'Save changes before closing?';

  @override
  String closeTabUnsavedBody(String basename) {
    return '$basename has unsaved changes.';
  }

  @override
  String get closeTabSave => 'Save';

  @override
  String get closeTabDontSave => 'Don\'t save';

  @override
  String get closeTabCancel => 'Cancel';

  @override
  String get frontmatterEmpty => 'No frontmatter detected.';

  @override
  String frontmatterFormatLabel(String format) {
    return 'Frontmatter · $format';
  }

  @override
  String get frontmatterSectionTitle => 'Frontmatter';

  @override
  String get frontmatterExpand => 'Expand frontmatter';

  @override
  String get frontmatterCollapse => 'Collapse frontmatter';

  @override
  String get previewPlaceholder => 'Live preview becomes available in Phase 5.';

  @override
  String get toolbarSaveTooltip => 'Save (Ctrl/Cmd+S)';

  @override
  String get toolbarSaveDisabledTooltip => 'No unsaved changes';

  @override
  String get toolbarSettingsTooltip => 'Settings (lands in Phase 10)';

  @override
  String get toolbarCloseProject => 'Close project';

  @override
  String get toolbarHugoStopped => 'Hugo: stopped';

  @override
  String get toolbarBranchPlaceholder => 'branch —';

  @override
  String get statusBarReady => 'Ready';

  @override
  String get statusBarCursorPlaceholder => 'Ln —, Col —';

  @override
  String get statusBarLastSavedPlaceholder => 'Last saved: —';
}
