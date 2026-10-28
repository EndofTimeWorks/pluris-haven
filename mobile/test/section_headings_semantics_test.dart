import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/features/home/home_page.dart';

void main() {
  testWidgets('section titles are individually marked as headings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SpSectionHeader(title: 'Notes'),
              DashboardSectionTitle('Main'),
              SpSettingsGroup(title: 'Privacy', rows: []),
            ],
          ),
        ),
      ),
    );

    for (final title in ['Notes', 'Main', 'Privacy']) {
      expect(
        tester
            .getSemantics(find.text(title))
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
    }
    semantics.dispose();
  });
}
