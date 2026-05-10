import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal Phase 0 theme runtime. Phase 10 replaces this with a JSON-driven
/// runtime that loads themes from `assets/themes/` and the user themes dir.
class AppThemes {
  AppThemes._();

  static const Color _seed = Color(0xFF1177BB);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
