import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'background/background_tasks.dart';
import 'data/local/app_database.dart';
import 'data/local/haven_repository.dart';
import 'data/local/supported_language.dart';
import 'debug/debug_log.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDebugLog('App startup');
  await initializeBackgroundTasks();

  final database = AppDatabase();
  final repository = LocalHavenRepository(database);
  await repository.ensureLocalSystem();
  appDebugLog('Local repository ready');

  runApp(PlurisHavenApp(repository: repository));
}

class PlurisHavenApp extends StatelessWidget {
  const PlurisHavenApp({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppCustomization>(
      stream: repository.watchCustomization(),
      initialData: AppCustomization.defaults,
      builder: (context, snapshot) {
        final customization = snapshot.data ?? AppCustomization.defaults;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pluris Haven',
          locale: _locale(customization.languageCode),
          supportedLocales: supportedLanguageLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          themeMode: _themeMode(customization.themeMode),
          theme: _buildTheme(customization, Brightness.light),
          darkTheme: _buildTheme(customization, Brightness.dark),
          home: HomePage(repository: repository),
        );
      },
    );
  }

  Locale? _locale(String languageCode) {
    if (languageCode == systemLanguageCode) {
      return null;
    }

    return supportedLanguageForCode(languageCode).locale;
  }

  ThemeMode _themeMode(HavenThemeMode mode) {
    return switch (mode) {
      HavenThemeMode.dark => ThemeMode.dark,
      HavenThemeMode.light => ThemeMode.light,
      HavenThemeMode.system => ThemeMode.system,
    };
  }

  ThemeData _buildTheme(AppCustomization customization, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = Color(customization.effectiveAccentArgb);
    final surface = isDark ? const Color(0xFF232532) : const Color(0xFFF7F4FC);
    final background = isDark
        ? const Color(0xFF171922)
        : const Color(0xFFF1EFF7);
    final card = isDark ? const Color(0xFF2B2E3D) : Colors.white;
    final onSurface = isDark
        ? const Color(0xFFECEAF2)
        : const Color(0xFF252334);
    final muted = isDark ? const Color(0xFFC4C0CE) : const Color(0xFF605C70);
    final outline = isDark ? const Color(0xFF3A3E50) : const Color(0xFFD6D0E3);

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: const Color(0xFFF2C75C),
        onSecondary: const Color(0xFF211B00),
        tertiary: const Color(0xFFF2C75C),
        onTertiary: const Color(0xFF211B00),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        surface: surface,
        surfaceContainerHighest: card,
        onSurface: onSurface,
        onSurfaceVariant: muted,
        outline: outline,
        outlineVariant: outline,
        shadow: Colors.black,
        inverseSurface: onSurface,
        onInverseSurface: surface,
        inversePrimary: accent,
        surfaceTint: accent,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        scrimColor: Colors.black.withValues(alpha: 0.6),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      useMaterial3: true,
    );
  }
}
