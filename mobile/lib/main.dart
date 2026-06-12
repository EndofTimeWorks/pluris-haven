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
          primary: Color(0xFF7D6AF2),
          secondary: Color(0xFFE4BE63),
          surface: Color(0xFF22242F),
          surfaceContainerHighest: Color(0xFF292C38),
          onSurface: Color(0xFFE9E6EF),
          onSurfaceVariant: Color(0xFFC7C3D0),
          outline: Color(0xFF343847),
        ),
        scaffoldBackgroundColor: const Color(0xFF191B24),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF22242F),
          foregroundColor: Color(0xFFE9E6EF),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF292C38),
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
