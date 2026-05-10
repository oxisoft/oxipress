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
  String get openProjectComingSoon => 'Project loading lands in Phase 1.';
}
