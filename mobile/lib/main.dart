import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'background/background_tasks.dart';
import 'data/local/app_database.dart';
import 'data/local/haven_repository.dart';
import 'data/local/supported_language.dart';
import 'data/notifications/notification_service.dart';
import 'data/security/haven_crypto.dart';
import 'data/security/master_key_store.dart';
import 'data/server/server_account_controller.dart';
import 'debug/debug_log.dart';
import 'features/app_lock_gate.dart';
import 'features/home/home_page.dart';
import 'l10n/app_localizations_fallback.dart';
import 'platform/native_file_dialog.dart';
import 'platform/screen_capture_protection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appDebugLog('App startup');
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  LocalHavenRepository? _repository;
  ServerAccountController? _serverAccount;
  var _missingMasterKey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openLocalArchive());
    });
  }

  Future<void> _openLocalArchive() async {
    final database = AppDatabase();
    late final HavenCrypto crypto;
    try {
      crypto = await HavenMasterKeyStore().loadOrCreateCrypto();
    } on MissingMasterKeyException {
      if (mounted) setState(() => _missingMasterKey = true);
      return;
    }
    final repository = LocalHavenRepository(database, crypto: crypto);
    await repository.ensureLocalSystem();
    await repository.migrateUnauthenticatedEmptyCiphertexts();
    await repository.migrateMemberNamesToEncryption();
    await repository.migrateBlindIndexesToUnicodeNormalization();
    final serverAccount = ServerAccountController();
    appDebugLog('Local repository ready');

    if (!mounted) return;
    setState(() {
      _repository = repository;
      _serverAccount = serverAccount;
    });
    unawaited(_completeStartup());
    unawaited(repository.repairRemoteAvatars());
    unawaited(serverAccount.initialize());
  }

  @override
  Widget build(BuildContext context) {
    if (_missingMasterKey) return const MissingMasterKeyApp();
    final repository = _repository;
    if (repository != null) {
      return PlurisHavenApp(
        repository: repository,
        serverAccount: _serverAccount,
      );
    }
    return const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

Future<void> _completeStartup() async {
  final staleExports =
      await NativeFileDialog.clearStaleExportTemporaryDirectories();
  if (staleExports > 0) {
    appDebugLog('Removed stale export staging directories count=$staleExports');
  }
  try {
    await initializeBackgroundTasks();
  } on Object catch (error, stackTrace) {
    appDebugLog(
      'Background task setup unavailable',
      error: error,
      stackTrace: stackTrace,
    );
  }
  try {
    await NotificationService.instance.initialize();
  } on Object catch (error, stackTrace) {
    appDebugLog(
      'Notification setup unavailable',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class MissingMasterKeyApp extends StatelessWidget {
  const MissingMasterKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Encryption key missing',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'This device no longer has the key that decrypts your local data. '
                  'Pluris Haven will not replace it. Restore an encrypted backup on '
                  'a device that still has the original key.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        unawaited(
          ScreenCaptureProtection.setEnabled(
            customization.screenshotBlockingEnabled,
          ),
        );

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) => _buildApp(
            customization,
            lightDynamic: lightDynamic,
            darkDynamic: darkDynamic,
          ),
        );
      },
    );
  }

  Widget _buildApp(
    AppCustomization customization, {
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  }) {
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
      theme: _buildTheme(
        customization,
        Brightness.light,
        dynamicScheme: lightDynamic,
      ),
      darkTheme: _buildTheme(
        customization,
        Brightness.dark,
        dynamicScheme: darkDynamic,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final baseTextScaler = customization.largeText
            ? mediaQuery.textScaler.clamp(minScaleFactor: 1.12)
            : mediaQuery.textScaler;
        final appearanceTextScale = customization.appearance.textScale ?? 1;
        return AppLockGate(
          enabled: customization.appLockEnabled,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              accessibleNavigation:
                  customization.reducedMotion ||
                  mediaQuery.accessibleNavigation,
              disableAnimations:
                  customization.reducedMotion || mediaQuery.disableAnimations,
              textScaler: appearanceTextScale == 1
                  ? baseTextScaler
                  : TextScaler.linear(
                      baseTextScaler.scale(1) * appearanceTextScale,
                    ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: HomePage(repository: repository, serverAccount: serverAccount),
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

  ThemeData _buildTheme(
    AppCustomization customization,
    Brightness brightness, {
    ColorScheme? dynamicScheme,
  }) {
    final appearance = customization.appearance;
    final spacingScale = appearance.spacingScale ?? 1;
    final borderWidth = appearance.borderWidth ?? 1;
    final cardElevation = appearance.cardElevation ?? 0;
    final visualDensity = VisualDensity(
      vertical: (customization.compactLists ? -1 : 0) + (1 - spacingScale) * 4,
      horizontal: (1 - spacingScale) * 4,
    );
    if (customization.visualTheme == HavenVisualTheme.materialYou &&
        dynamicScheme != null) {
      final scheme = dynamicScheme.copyWith(
        surface: appearance.surfaceColor ?? dynamicScheme.surface,
        surfaceContainerHighest:
            appearance.cardColor ?? dynamicScheme.surfaceContainerHighest,
        onSurface: appearance.textColor ?? dynamicScheme.onSurface,
        onSurfaceVariant:
            appearance.mutedTextColor ?? dynamicScheme.onSurfaceVariant,
        outline: appearance.outlineColor ?? dynamicScheme.outline,
        outlineVariant: appearance.outlineColor ?? dynamicScheme.outlineVariant,
      );
      return ThemeData.from(colorScheme: scheme, useMaterial3: true).copyWith(
        extensions: [HavenVisualThemeExtension(customization.visualTheme)],
        scaffoldBackgroundColor: appearance.backgroundColor ?? scheme.surface,
        visualDensity: visualDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
        ),
        dividerTheme: DividerThemeData(
          color: scheme.outline,
          thickness: borderWidth,
        ),
        cardTheme: CardThemeData(
          color: scheme.surfaceContainerHighest,
          elevation: cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appearance.cardRadius ?? 14),
          ),
          margin: EdgeInsets.zero,
        ),
      );
    }
    final isDark = brightness == Brightness.dark;
    final simplyPlural =
        customization.visualTheme == HavenVisualTheme.simplyPlural;
    final accent = simplyPlural
        ? const Color(0xFFD9B45B)
        : Color(customization.effectiveAccentArgb);
    final highContrast = customization.highContrast;
    final surface = simplyPlural
        ? (isDark ? const Color(0xFF20242B) : const Color(0xFFF5F5F2))
        : highContrast
        ? (isDark ? const Color(0xFF11131A) : Colors.white)
        : (isDark ? const Color(0xFF232532) : const Color(0xFFF7F4FC));
    final background = simplyPlural
        ? (isDark ? const Color(0xFF171A20) : const Color(0xFFEAEBE8))
        : highContrast
        ? (isDark ? Colors.black : const Color(0xFFF8F8FC))
        : (isDark ? const Color(0xFF171922) : const Color(0xFFF1EFF7));
    final card = simplyPlural
        ? (isDark ? const Color(0xFF252A32) : Colors.white)
        : highContrast
        ? (isDark ? const Color(0xFF1E2230) : Colors.white)
        : (isDark ? const Color(0xFF2B2E3D) : Colors.white);
    final onSurface = simplyPlural
        ? (isDark ? const Color(0xFFE7E9EC) : const Color(0xFF20242B))
        : highContrast
        ? (isDark ? Colors.white : const Color(0xFF11111A))
        : (isDark ? const Color(0xFFECEAF2) : const Color(0xFF252334));
    final muted = simplyPlural
        ? (isDark ? const Color(0xFFB5BBC4) : const Color(0xFF646A72))
        : highContrast
        ? (isDark ? const Color(0xFFE1DDF0) : const Color(0xFF3B3748))
        : (isDark ? const Color(0xFFC4C0CE) : const Color(0xFF605C70));
    final outline = simplyPlural
        ? (isDark ? const Color(0xFF3A414B) : const Color(0xFFD1D4D0))
        : highContrast
        ? (isDark ? const Color(0xFF747991) : const Color(0xFF6D6680))
        : (isDark ? const Color(0xFF3A3E50) : const Color(0xFFD6D0E3));
    final effectiveSurface = appearance.surfaceColor ?? surface;
    final effectiveBackground = appearance.backgroundColor ?? background;
    final effectiveCard = appearance.cardColor ?? card;
    final effectiveOnSurface = appearance.textColor ?? onSurface;
    final effectiveMuted = appearance.mutedTextColor ?? muted;
    final effectiveOutline = appearance.outlineColor ?? outline;
    final cardRadius = appearance.cardRadius ?? (simplyPlural ? 16 : 12);
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: simplyPlural
            ? const Color(0xFFD9B45B)
            : const Color(0xFFF2C75C),
        onSecondary: const Color(0xFF211B00),
        tertiary: const Color(0xFFF2C75C),
        onTertiary: const Color(0xFF211B00),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        surface: effectiveSurface,
        surfaceContainerHighest: effectiveCard,
        onSurface: effectiveOnSurface,
        onSurfaceVariant: effectiveMuted,
        outline: effectiveOutline,
        outlineVariant: effectiveOutline,
        shadow: Colors.black,
        inverseSurface: onSurface,
        onInverseSurface: surface,
        inversePrimary: accent,
        surfaceTint: accent,
      ),
      scaffoldBackgroundColor: effectiveBackground,
      visualDensity: visualDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: effectiveSurface,
        foregroundColor: effectiveOnSurface,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: effectiveSurface,
        scrimColor: Colors.black.withValues(alpha: 0.6),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveOutline,
        thickness: borderWidth,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: effectiveBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      extensions: [HavenVisualThemeExtension(customization.visualTheme)],
      useMaterial3: true,
    );
  }
}
