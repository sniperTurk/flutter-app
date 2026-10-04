import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/catalog/manual_catalog_dialog.dart';

/// Opens the dialog from a button and records what it popped with.
Future<List<bool?>> _pumpHost(
  WidgetTester tester, {
  required Future<void> Function(Map<String, dynamic>) onSave,
  Map<String, dynamic>? existing,
}) async {
  final results = <bool?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<bool>(
                  context: context,
                  builder: (_) => ManualCatalogDialog(
                    existing: existing,
                    defaultPlatform: 'pcp',
                    onSave: onSave,
                  ),
                ),
              );
            },
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _fillRifle(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Marka *'),
    'Atölye',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Model *'), 'X1');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kalibre (mm) *'),
    '5,5',
  );
}

void main() {
  testWidgets('repeated taps while saving write exactly one record', (
    tester,
  ) async {
    final pending = Completer<void>();
    final saved = <Map<String, dynamic>>[];
    final results = await _pumpHost(
      tester,
      onSave: (entry) {
        saved.add(entry);
        return pending.future;
      },
    );
    await _fillRifle(tester);

    final save = find.byKey(const Key('manual-catalog-save'));
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();
    expect(saved, hasLength(1));
    expect(
      tester.widget<FilledButton>(save).onPressed,
      isNull,
      reason: 'Kaydet is disabled while the write is in flight',
    );

    pending.complete();
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single['caliberMm'], 5.5);
    expect(find.byType(ManualCatalogDialog), findsNothing);
    expect(results, [true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save keeps the dialog and every typed value; a retry '
      'targets the same record id', (tester) async {
    var calls = 0;
    final ids = <Object?>[];
    final results = await _pumpHost(
      tester,
      onSave: (entry) async {
        calls++;
        ids.add(entry['id']);
        if (calls == 1) throw StateError('disk dolu');
      },
    );
    await _fillRifle(tester);

    await tester.tap(find.byKey(const Key('manual-catalog-save')));
    await tester.pumpAndSettle();
    expect(find.byType(ManualCatalogDialog), findsOneWidget);
    expect(find.textContaining('Kayıt başarısız'), findsOneWidget);
    expect(find.text('Atölye'), findsOneWidget);
    expect(find.text('X1'), findsOneWidget);
    expect(find.text('5,5'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('manual-catalog-save')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('manual-catalog-save')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(ids[0], ids[1]);
    expect(results, [true]);
  });

  testWidgets('controllers outlive the exit animation (cancel and save)', (
    tester,
  ) async {
    await _pumpHost(tester, onSave: (_) async {});
    await _fillRifle(tester);
    await tester.tap(find.text('İptal'));
    // Step through the whole exit transition frame by frame: the old code
    // disposed the controllers here, while the fields were still painting.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(find.byType(ManualCatalogDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editing keeps the stored id and offers a click unit for scopes',
    (tester) async {
      final saved = <Map<String, dynamic>>[];
      await _pumpHost(
        tester,
        existing: const {
          'id': 'manual_scope_9',
          'kind': 'scope',
          'platform': 'pcp',
          'brand': 'Optik',
          'model': '3-12x40',
          'objectiveMm': 40,
          'click': 0.25,
        },
        onSave: (entry) async => saved.add(entry),
      );
      expect(find.text('Klik birimi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('manual-catalog-save')));
      await tester.pumpAndSettle();
      expect(saved.single['id'], 'manual_scope_9');
      expect(saved.single['clickUnit'], 'mrad');
      expect(saved.single['click'], 0.25);
    },
  );
}
