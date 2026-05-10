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

  /// No description provided for @previewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Live preview becomes available in Phase 5.'**
  String get previewPlaceholder;

  /// No description provided for @toolbarSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save (lands in Phase 3)'**
  String get toolbarSaveTooltip;

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
