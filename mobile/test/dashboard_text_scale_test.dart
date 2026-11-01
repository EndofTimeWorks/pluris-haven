import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/data/local/app_customization.dart';
import 'package:pluris_haven/features/home/home_page.dart';

void main() {
  testWidgets('dashboard tiles keep device text scale in a narrow layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(412, 915),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ListView(
              children: [
                DashboardActionGrid(
                  items: const [
                    HomeNavigationItem(
                      'Front History',
                      'Review local fronting history',
                      SpSection.frontHistory,
                      Icons.history,
                    ),
                    HomeNavigationItem(
                      'Import and Export',
                      'Keep a portable archive',
                      SpSection.importExport,
                      Icons.import_export,
                    ),
                  ],
                  customization: AppCustomization.defaults,
                  onSelect: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final title = find.text('Front History');
    expect(MediaQuery.textScalerOf(tester.element(title)).scale(12), 24);
    expect(
      tester.getSize(find.byType(SpDashboardTile).first).height,
      greaterThan(170),
    );
  });
}
