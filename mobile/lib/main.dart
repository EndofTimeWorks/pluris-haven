import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'background/background_tasks.dart';
import 'data/local/app_database.dart';
import 'data/local/haven_repository.dart';
import 'data/local/supported_language.dart';
import 'data/notifications/notification_service.dart';
import 'data/security/master_key_store.dart';
import 'data/server/server_account_controller.dart';
import 'debug/debug_log.dart';
import 'features/home/home_page.dart';
import 'l10n/app_localizations_fallback.dart';
import 'platform/native_file_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDebugLog('App startup');
  final staleExports =
      await NativeFileDialog.clearStaleExportTemporaryDirectories();
  if (staleExports > 0) {
    appDebugLog('Removed stale export staging directories count=$staleExports');
  }
  await initializeBackgroundTasks();
  await NotificationService.instance.initialize();

  final database = AppDatabase();
  final crypto = await HavenMasterKeyStore().loadOrCreateCrypto();
  final repository = LocalHavenRepository(database, crypto: crypto);
  await repository.ensureLocalSystem();
  await repository.migrateMemberNamesToEncryption();
  await repository.migrateLocalPrivateContentToEncryption();
  final serverAccount = ServerAccountController();
  appDebugLog('Local repository ready');

  runApp(PlurisHavenApp(repository: repository, serverAccount: serverAccount));
  unawaited(serverAccount.initialize());
}

class PlurisHavenApp extends StatelessWidget {
  const PlurisHavenApp({
    super.key,
    required this.repository,
    this.serverAccount,
  });

  final HavenRepository repository;
  final ServerAccountController? serverAccount;

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
            FallbackAppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          themeMode: _themeMode(customization.themeMode),
          theme: _buildTheme(customization, Brightness.light),
          darkTheme: _buildTheme(customization, Brightness.dark),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                accessibleNavigation:
                    customization.reducedMotion ||
                    mediaQuery.accessibleNavigation,
                disableAnimations:
                    customization.reducedMotion || mediaQuery.disableAnimations,
                textScaler: customization.largeText
                    ? mediaQuery.textScaler.clamp(minScaleFactor: 1.12)
                    : mediaQuery.textScaler,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: HomePage(repository: repository, serverAccount: serverAccount),
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
    final highContrast = customization.highContrast;
    final surface = highContrast
        ? (isDark ? const Color(0xFF11131A) : Colors.white)
        : (isDark ? const Color(0xFF232532) : const Color(0xFFF7F4FC));
    final background = highContrast
        ? (isDark ? Colors.black : const Color(0xFFF8F8FC))
        : (isDark ? const Color(0xFF171922) : const Color(0xFFF1EFF7));
    final card = highContrast
        ? (isDark ? const Color(0xFF1E2230) : Colors.white)
        : (isDark ? const Color(0xFF2B2E3D) : Colors.white);
    final onSurface = highContrast
        ? (isDark ? Colors.white : const Color(0xFF11111A))
        : (isDark ? const Color(0xFFECEAF2) : const Color(0xFF252334));
    final muted = highContrast
        ? (isDark ? const Color(0xFFE1DDF0) : const Color(0xFF3B3748))
        : (isDark ? const Color(0xFFC4C0CE) : const Color(0xFF605C70));
    final outline = highContrast
        ? (isDark ? const Color(0xFF747991) : const Color(0xFF6D6680))
        : (isDark ? const Color(0xFF3A3E50) : const Color(0xFFD6D0E3));
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
      visualDensity: customization.compactLists
          ? VisualDensity.compact
          : VisualDensity.standard,
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
