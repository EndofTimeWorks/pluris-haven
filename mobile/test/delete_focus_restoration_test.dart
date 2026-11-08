import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluris_haven/features/home/home_page.dart';
import 'package:pluris_haven/l10n/app_localizations.dart';

void main() {
  testWidgets('cancelled deletion returns keyboard focus to its action', (
    tester,
  ) async {
    final deleteFocus = FocusNode();
    addTearDown(deleteFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              focusNode: deleteFocus,
              onPressed: () => confirmDelete(
                context,
                title: 'Delete note?',
                body: 'Delete this note?',
                onDelete: () async {},
              ),
              child: const Text('Delete note'),
            ),
          ),
        ),
      ),
    );
    deleteFocus.requestFocus();
    await tester.pump();
    expect(deleteFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleteFocus.hasFocus, isTrue);
  });

  testWidgets(
    'deleting the focused action moves focus to a surviving control',
    (tester) async {
      final deleteFocus = FocusNode();
      final nextFocus = FocusNode();
      addTearDown(deleteFocus.dispose);
      addTearDown(nextFocus.dispose);
      var deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  if (!deleted)
                    TextButton(
                      key: const ValueKey('delete-note'),
                      focusNode: deleteFocus,
                      onPressed: () => confirmDelete(
                        context,
                        title: 'Delete note?',
                        body: 'Delete this note?',
                        onDelete: () async => setState(() => deleted = true),
                      ),
                      child: const Text('Delete note'),
                    ),
                  TextButton(
                    key: const ValueKey('next-note'),
                    focusNode: nextFocus,
                    onPressed: () {},
                    child: const Text('Next note'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      deleteFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Delete note'), findsNothing);
      expect(nextFocus.hasFocus, isTrue);
    },
  );
}
