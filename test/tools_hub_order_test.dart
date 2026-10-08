// Araçlar tab (owner, 2026-10-08): the top bar says "Araçlar" instead of
// Menzil, and Haritadan mesafe sits under Sight Height with Hava & Rüzgâr
// right below it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  testWidgets('Araçlar: title, map tool under Sight Height, weather next', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: MemoryProfileStore(),
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('top-bar-title')), findsNothing);

    await tester.tap(find.text('Araçlar'));
    await tester.pumpAndSettle();

    final title = find.byKey(const Key('top-bar-title'));
    expect(tester.widget<Text>(title).data, 'Araçlar');
    expect(find.text('Menzil'), findsNothing);

    double y(String key) => tester.getTopLeft(find.byKey(Key(key))).dy;
    final order = [
      'tool-chronograph',
      'tool-sight-height',
      'tool-map-distance',
      'tool-weather',
      'tool-compass',
      'tool-level',
    ];
    for (var i = 1; i < order.length; i++) {
      expect(y(order[i]), greaterThan(y(order[i - 1])), reason: order[i]);
    }
    expect(find.byKey(const Key('tool-catalog')), findsNothing);
    expect(find.text('Katalog'), findsNothing);
  });
}
