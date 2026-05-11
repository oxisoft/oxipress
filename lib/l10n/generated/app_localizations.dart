import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'OxiPress'**
  String get appName;

  /// Tagline shown on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Edit Hugo sites with live preview.'**
  String get welcomeTagline;

  /// Open Project button on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProject;

  /// Status while a project is being opened
  ///
  /// In en, this message translates to:
  /// **'Opening project…'**
  String get openingProject;

  /// Header for the recent projects list on welcome
  ///
  /// In en, this message translates to:
  /// **'Recent projects'**
  String get recentProjects;

  /// Empty state under recent projects
  ///
  /// In en, this message translates to:
  /// **'No recent projects yet.'**
  String get noRecentProjects;

  /// Documentation link label
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// Snackbar shown when the documentation link is tapped
  ///
  /// In en, this message translates to:
  /// **'Documentation site is not yet published.'**
  String get documentationComingSoon;

  /// Tooltip on the remove icon next to a recent entry
  ///
  /// In en, this message translates to:
  /// **'Remove from recents'**
  String get removeFromRecents;

  /// No description provided for @errorPathDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'The selected folder does not exist.'**
  String get errorPathDoesNotExist;

  /// No description provided for @errorMissingContentDirectory.
  ///
  /// In en, this message translates to:
  /// **'The selected folder is not a Hugo site (missing content/ directory).'**
  String get errorMissingContentDirectory;

  /// No description provided for @errorMissingHugoConfig.
  ///
  /// In en, this message translates to:
  /// **'The selected folder is not a Hugo site (no hugo.toml/yaml/json or legacy config.* found).'**
  String get errorMissingHugoConfig;

  /// No description provided for @errorNotADirectory.
  ///
  /// In en, this message translates to:
  /// **'The selected path is not a folder.'**
  String get errorNotADirectory;

  /// No description provided for @panelTitleFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get panelTitleFiles;

  /// No description provided for @panelTitleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get panelTitleEditor;

  /// No description provided for @panelTitlePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get panelTitlePreview;

  /// No description provided for @collapsePanel.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get collapsePanel;

  /// No description provided for @expandPanel.
  ///
  /// In en, this message translates to:
  /// **'Expand panel'**
  String get expandPanel;

  /// No description provided for @treeRootContent.
  ///
  /// In en, this message translates to:
  /// **'Show content folder'**
  String get treeRootContent;

  /// No description provided for @treeRootProjectRoot.
  ///
  /// In en, this message translates to:
  /// **'Show project root'**
  String get treeRootProjectRoot;

  /// No description provided for @treeEmpty.
  ///
  /// In en, this message translates to:
  /// **'This directory is empty.'**
  String get treeEmpty;

  /// No description provided for @treeNoProject.
  ///
  /// In en, this message translates to:
  /// **'No project open.'**
  String get treeNoProject;

  /// No description provided for @treeMenuNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file…'**
  String get treeMenuNewFile;

  /// No description provided for @treeMenuNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder…'**
  String get treeMenuNewFolder;

  /// No description provided for @treeMenuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get treeMenuOpen;

  /// No description provided for @treeMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get treeMenuRename;

  /// No description provided for @treeMenuDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get treeMenuDuplicate;

  /// No description provided for @treeMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete…'**
  String get treeMenuDelete;

  /// No description provided for @treeMenuReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal in file manager'**
  String get treeMenuReveal;

  /// No description provided for @treeMenuWriteRestricted.
  ///
  /// In en, this message translates to:
  /// **'Read-only outside content/, static/, assets/, data/, layouts/'**
  String get treeMenuWriteRestricted;

  /// No description provided for @newFileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFileDialogTitle;

  /// No description provided for @newFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolderDialogTitle;

  /// No description provided for @newFileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Filename (e.g. my-post.md)'**
  String get newFileNameHint;

  /// No description provided for @newFolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get newFolderNameHint;

  /// No description provided for @newFileUseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Insert Hugo frontmatter template'**
  String get newFileUseTemplate;

  /// No description provided for @renameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameDialogTitle;

  /// No description provided for @renameDialogHint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get renameDialogHint;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmFile.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This can\'t be undone.'**
  String deleteConfirmFile(String name);

  /// No description provided for @deleteConfirmFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder {name} and everything in it? This can\'t be undone.'**
  String deleteConfirmFolder(String name);

  /// No description provided for @dialogCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get dialogCreate;

  /// No description provided for @dialogRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get dialogRename;

  /// No description provided for @dialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @mutationErrorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A file or folder with that name already exists here.'**
  String get mutationErrorAlreadyExists;

  /// No description provided for @mutationErrorInvalidName.
  ///
  /// In en, this message translates to:
  /// **'That name isn\'t allowed.'**
  String get mutationErrorInvalidName;

  /// No description provided for @mutationErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The file or folder no longer exists.'**
  String get mutationErrorNotFound;

  /// No description provided for @mutationErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {detail}'**
  String mutationErrorGeneric(String detail);

  /// No description provided for @editorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Open a markdown file from the tree.'**
  String get editorPlaceholder;

  /// No description provided for @editorEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'(empty body)'**
  String get editorEmptyBody;

  /// No description provided for @editorModeRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get editorModeRaw;

  /// No description provided for @editorModeRich.
  ///
  /// In en, this message translates to:
  /// **'Rich'**
  String get editorModeRich;

  /// No description provided for @editorModeRichComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rich-text mode arrives in Phase 9.'**
  String get editorModeRichComingSoon;

  /// No description provided for @editorTabListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show all open tabs'**
  String get editorTabListTooltip;

  /// No description provided for @externalChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'File changed on disk'**
  String get externalChangeTitle;

  /// No description provided for @externalChangeBody.
  ///
  /// In en, this message translates to:
  /// **'{path} changed externally while you have unsaved edits. What do you want to do?'**
  String externalChangeBody(String path);

  /// No description provided for @externalChangeKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep my changes'**
  String get externalChangeKeepMine;

  /// No description provided for @externalChangeReloadDisk.
  ///
  /// In en, this message translates to:
  /// **'Reload from disk (lose changes)'**
  String get externalChangeReloadDisk;

  /// No description provided for @findReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Find / Replace'**
  String get findReplaceTitle;

  /// No description provided for @findHint.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findHint;

  /// No description provided for @replaceHint.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceHint;

  /// No description provided for @findCaseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get findCaseSensitive;

  /// No description provided for @findWholeWord.
  ///
  /// In en, this message translates to:
  /// **'Whole word'**
  String get findWholeWord;

  /// No description provided for @findRegex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get findRegex;

  /// No description provided for @findPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get findPrev;

  /// No description provided for @findNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get findNext;

  /// No description provided for @findReplaceOne.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get findReplaceOne;

  /// No description provided for @findReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get findReplaceAll;

  /// No description provided for @findClose.
  ///
  /// In en, this message translates to:
  /// **'Close find/replace'**
  String get findClose;

  /// No description provided for @findMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String findMatchCount(int current, int total);

  /// No description provided for @findNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get findNoMatches;

  /// No description provided for @closeTabUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes before closing?'**
  String get closeTabUnsavedTitle;

  /// No description provided for @closeTabUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'{basename} has unsaved changes.'**
  String closeTabUnsavedBody(String basename);

  /// No description provided for @closeTabSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get closeTabSave;

  /// No description provided for @closeTabDontSave.
  ///
  /// In en, this message translates to:
  /// **'Don\'t save'**
  String get closeTabDontSave;

  /// No description provided for @closeTabCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get closeTabCancel;

  /// No description provided for @frontmatterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No frontmatter detected.'**
  String get frontmatterEmpty;

  /// No description provided for @frontmatterFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Frontmatter · {format}'**
  String frontmatterFormatLabel(String format);

  /// No description provided for @frontmatterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Frontmatter'**
  String get frontmatterSectionTitle;

  /// No description provided for @frontmatterExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand frontmatter'**
  String get frontmatterExpand;

  /// No description provided for @frontmatterCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse frontmatter'**
  String get frontmatterCollapse;

  /// No description provided for @previewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Live preview becomes available in Phase 5.'**
  String get previewPlaceholder;

  /// No description provided for @toolbarSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save (Ctrl/Cmd+S)'**
  String get toolbarSaveTooltip;

  /// No description provided for @toolbarSaveDisabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'No unsaved changes'**
  String get toolbarSaveDisabledTooltip;

  /// No description provided for @toolbarSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings (lands in Phase 10)'**
  String get toolbarSettingsTooltip;

  /// No description provided for @toolbarCloseProject.
  ///
  /// In en, this message translates to:
  /// **'Close project'**
  String get toolbarCloseProject;

  /// No description provided for @toolbarHugoStopped.
  ///
  /// In en, this message translates to:
  /// **'Hugo: stopped'**
  String get toolbarHugoStopped;

  /// No description provided for @hugoStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Hugo: stopped'**
  String get hugoStatusStopped;

  /// No description provided for @hugoStatusStarting.
  ///
  /// In en, this message translates to:
  /// **'Hugo: starting…'**
  String get hugoStatusStarting;

  /// No description provided for @hugoStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Hugo: :{port}'**
  String hugoStatusRunning(int port);

  /// No description provided for @hugoStatusError.
  ///
  /// In en, this message translates to:
  /// **'Hugo: error'**
  String get hugoStatusError;

  /// No description provided for @hugoActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start Hugo serve'**
  String get hugoActionStart;

  /// No description provided for @hugoActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Hugo serve'**
  String get hugoActionStop;

  /// No description provided for @hugoActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart Hugo serve'**
  String get hugoActionRestart;

  /// No description provided for @previewAddressBar.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get previewAddressBar;

  /// No description provided for @previewActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previewActionBack;

  /// No description provided for @previewActionForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get previewActionForward;

  /// No description provided for @previewActionReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get previewActionReload;

  /// No description provided for @previewActionOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get previewActionOpenInBrowser;

  /// No description provided for @previewWaitingForHugo.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Hugo to start…'**
  String get previewWaitingForHugo;

  /// No description provided for @previewHugoNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Hugo isn\'t running yet. Start it from the toolbar.'**
  String get previewHugoNotRunning;

  /// No description provided for @previewHugoError.
  ///
  /// In en, this message translates to:
  /// **'Hugo encountered an error. See logs and toolbar status.'**
  String get previewHugoError;

  /// No description provided for @previewWebviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Embedded preview is available on macOS for now; use Open in browser on other platforms.'**
  String get previewWebviewUnavailable;

  /// No description provided for @toolbarBranchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'branch —'**
  String get toolbarBranchPlaceholder;

  /// No description provided for @statusBarReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusBarReady;

  /// No description provided for @statusBarCursorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ln —, Col —'**
  String get statusBarCursorPlaceholder;

  /// No description provided for @statusBarLastSavedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Last saved: —'**
  String get statusBarLastSavedPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
