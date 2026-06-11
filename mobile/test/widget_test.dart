import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/main.dart';

void main() {
  testWidgets('shows the offline home dashboard', (tester) async {
    await tester.pumpWidget(const PlurisHavenApp());

    expect(find.text('Pluris Haven'), findsOneWidget);
    expect(find.text('Currently fronting'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Import / Export'), findsOneWidget);
  });
}
