import 'package:flutter/material.dart';

import 'data/local/app_database.dart';
import 'data/local/haven_repository.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = LocalHavenRepository(database);
  await repository.ensureLocalSystem();

  runApp(PlurisHavenApp(repository: repository));
}

class PlurisHavenApp extends StatelessWidget {
  const PlurisHavenApp({super.key, required this.repository});

  final HavenRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pluris Haven',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B61FF),
          secondary: Color(0xFFF2C75C),
          surface: Color(0xFF232532),
          surfaceContainerHighest: Color(0xFF2B2E3D),
          onSurface: Color(0xFFECEAF2),
          onSurfaceVariant: Color(0xFFC4C0CE),
          outline: Color(0xFF3A3E50),
        ),
        scaffoldBackgroundColor: const Color(0xFF171922),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF232532),
          foregroundColor: Color(0xFFECEAF2),
          elevation: 0,
          centerTitle: false,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF232532),
          scrimColor: Color(0x99000000),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF3A3E50),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171922),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2B2E3D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
      ),
      home: HomePage(repository: repository),
    );
  }
}
