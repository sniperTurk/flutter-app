// TEMPORARY diagnostic (scratch branch only): why is the Kalibre entry's
// centre not hittable at 320 pt × 1.3?
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

void main() {
  for (final (w, s, label) in const [
    (320.0, 1.3, '.338-378 Weatherby Mag'),
    (320.0, 1.3, '.308 Win'),
    (430.0, 1.0, '.338-378 Weatherby Mag'),
  ]) {
    testWidgets('DIAG $w x$s $label', (tester) async {
      tester.view.physicalSize = Size(w * 3, 2600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = s;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(store: MemoryProfileStore()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Yeni profil'));
      await tester.pumpAndSettle();
      await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
      await tester.ensureVisible(find.byKey(const Key('rifle-caliber')));
      await tester.tap(find.byKey(const Key('rifle-caliber')));
      await tester.pumpAndSettle();
      final btn = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
      );
      final inMenu = find.descendant(of: btn, matching: find.text(label));
      await tester.dragUntilVisible(
        inMenu,
        find.byType(Scrollable).last,
        const Offset(0, -300),
        maxIteration: 400,
      );
      await tester.ensureVisible(inMenu.last);
      await tester.pumpAndSettle();
      final t = tester.getRect(inMenu.last);
      final item = tester.getRect(
        find.ancestor(of: inMenu.last, matching: btn).first,
      );
      final view = tester.getRect(find.byType(Scrollable).last);
      final c = t.center;
      final r = HitTestResult();
      tester.binding.hitTestInView(r, c, tester.view.viewId);
      final path = r.path
          .take(6)
          .map((e) => e.target.runtimeType.toString().replaceAll('Render', ''))
          .join('>');
      String f(Rect x) =>
          '${x.left.toStringAsFixed(0)},${x.top.toStringAsFixed(0)},'
          '${x.width.toStringAsFixed(0)}x${x.height.toStringAsFixed(0)}';
      expect(
        'txt ${f(t)} item ${f(item)} view ${f(view)} '
        'hit ${inMenu.last.hitTestable().evaluate().length} path $path',
        'x',
      );
    });
  }
}
