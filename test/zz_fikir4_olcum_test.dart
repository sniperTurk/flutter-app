// TEMPORARY measurement (branch tmp/fikir4-olcum only, never merged).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('olcum $scale', (tester) async {
      tester.view.physicalSize = const Size(430, 900) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final a = TextEditingController(), b = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Column(
                children: [
                  MenzilInput(key: const Key('old'), controller: a, label: 'Sıcaklık', unit: '°C', info: 'x'),
                  MenzilInput(key: const Key('new'), controller: b, label: 'Nem', unit: '%', info: 'x', compact: true),
                ],
              ),
            ),
          ),
        ),
      );
      String m(String k, String l) {
        final f = find.descendant(of: find.byKey(Key(k)), matching: find.byType(TextField));
        final box = tester.getRect(f);
        final whole = tester.getRect(find.byKey(Key(k)));
        final lab = tester.getRect(find.text(l));
        return '$k gap=${(box.top - lab.bottom).toStringAsFixed(1)} labelRow=${(box.top - whole.top).toStringAsFixed(1)} box=${box.height.toStringAsFixed(1)} field=${whole.height.toStringAsFixed(1)}';
      }
      expect('FIKIR4 s=$scale ${m('old', 'Sıcaklık')} | ${m('new', 'Nem')}', 'olcum');
    });
  }
}
