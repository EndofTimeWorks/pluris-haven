import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/features/home/home_page.dart';

void main() {
  testWidgets('an actionable settings row announces its text once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpSettingsRow('Theme', 'Dark', onTap: () => taps++),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Theme. Dark'), findsOneWidget);
    expect(find.bySemanticsLabel('Theme'), findsNothing);
    expect(find.bySemanticsLabel('Dark'), findsNothing);
    await tester.tap(find.text('Theme'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('an informational settings row has no dead-end action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpSettingsRow('Backups', 'Not available')),
      ),
    );

    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('>'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SpSettingsRow),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Backups'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    semantics.dispose();
  });

  testWidgets('static row keeps its real trailing action accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpSettingsRow(
            'Day crew',
            'Named front',
            trailing: IconButton(
              tooltip: 'Delete Day crew',
              onPressed: () => deletes++,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.byTooltip('Delete Day crew'))
          .getSemanticsData()
          .tooltip,
      'Delete Day crew',
    );
    await tester.tap(find.byTooltip('Delete Day crew'));
    expect(deletes, 1);
    semantics.dispose();
  });
}
