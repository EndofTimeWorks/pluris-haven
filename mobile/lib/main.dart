import 'package:flutter/material.dart';

void main() {
  runApp(const PlurisHavenApp());
}

class PlurisHavenApp extends StatelessWidget {
  const PlurisHavenApp({super.key});

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = <HomeModule>[
      const HomeModule('Members', '0 saved', Icons.groups_rounded),
      const HomeModule('Front History', '0 entries', Icons.history_rounded),
      const HomeModule('Groups', '0 groups', Icons.folder_rounded),
      const HomeModule('Notes', '0 notes', Icons.notes_rounded),
      const HomeModule(
        'Import / Export',
        'local archive',
        Icons.import_export_rounded,
      ),
      const HomeModule('Sync', 'off by default', Icons.sync_disabled_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pluris Haven',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'saved on device',
              style: TextStyle(fontSize: 13, color: Color(0xFFC7C3D0)),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const CurrentFrontPanel(),
          const SizedBox(height: 12),
          for (final module in modules) ...[
            ModuleRow(module: module),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class CurrentFrontPanel extends StatelessWidget {
  const CurrentFrontPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currently fronting',
                    style: TextStyle(
                      color: Color(0xFFC7C3D0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'None',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const StatusPill(text: 'none'),
          ],
        ),
      ),
    );
  }
}

class ModuleRow extends StatelessWidget {
  const ModuleRow({super.key, required this.module});

  final HomeModule module;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(module.icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC7C3D0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C3D0)),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFC7C3D0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomeModule {
  const HomeModule(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
