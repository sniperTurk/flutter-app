import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';
import 'support/select_one_line.dart';

void main() {
  testWidgets('diag heights', (tester) async {
    final out = <String>[];
    for (final (w, s) in const [(390.0, 1.0), (320.0, 1.3)]) {
      tester.view.physicalSize = Size(w * 3, 2600 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = s;
      await tester.pumpWidget(const SizedBox());
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
      for (final k in [
        'profile-platform',
        'rifle-caliber',
        'profile-velocity-fps',
        'rifle-twist-rate',
        'rifle-twist-direction',
        'profile-zero',
        'profile-distance-unit',
        'scope-sight-height',
      ]) {
        out.add('$w/$s $k ${selectBox(tester, k).height}');
      }
      Navigator.of(tester.element(find.byKey(const Key('profile-zero')))).pop();
      await tester.pumpAndSettle();
    }
    fail('HEIGHTS ${out.join(' | ')}');
  });
}
