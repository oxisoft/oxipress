import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/project/ui/project_controller.dart';
import '../features/project/ui/welcome_screen.dart';
import '../features/project/ui/workspace_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_info.dart';
import 'theme_runtime.dart';

class OxiPressApp extends ConsumerWidget {
  const OxiPressApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppInfo.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      darkTheme: AppThemes.dark(),
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _HomeRouter(),
    );
  }
}

class _HomeRouter extends ConsumerWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = ref.watch(projectControllerProvider);
    return switch (lifecycle) {
      OpenProject() => const WorkspaceScreen(),
      _ => const WelcomeScreen(),
    };
  }
}
