// PRF-7 / PRF-8 (2026-10-15): picking Tür keeps the chosen Kalibre exactly.
//
// Every firearm cartridge of lib/data/cartridges.dart, in both orders on a
// new profile (Tür first then Kalibre; Kalibre first then Tür): the Kalibre
// box keeps that cartridge (not the first cartridge of the same diameter)
// and the Fabrika fişeği lists hold only that cartridge's factory rounds.
//
// The list boxes are driven through their own onChanged (what a tap on an
// item calls), so 168 × 2 runs need no menu scrolling.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

Future<void> _openNewProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
}

MenzilSelect<T> _select<T>(WidgetTester tester, String key) =>
    tester.widget<MenzilSelect<T>>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(MenzilSelect<T>),
        matchRoot: true,
      ),
    );

/// Picks [value] in the list box under [key], as a tap on its item does.
Future<void> _pick<T>(WidgetTester tester, String key, T value) async {
  final select = _select<T>(tester, key);
  expect(
    select.items.any((i) => i.value == value && i.enabled),
    isTrue,
    reason: '"$value" is not a choice of $key',
  );
  select.onChanged!(value);
  await tester.pumpAndSettle();
}

/// The factory rounds the Fabrika fişeği lists show, by brand: every
/// brand's Model list is opened in turn.
Future<Map<String, int>> _factoryListed(WidgetTester tester) async {
  final out = <String, int>{};
  final brands = [
    for (final i in _select<String>(tester, 'ammo-brand-select').items)
      // "Diğer marka" (__other, owner 2026-10-17) has no Model list.
      if (i.value != null && !i.value!.startsWith('!') && i.value != '__other')
        i.value!,
  ];
  for (final b in brands) {
    await _pick<String>(tester, 'ammo-brand-select', b);
    out[b] = _select<int>(tester, 'ammo-model-select').items.length;
  }
  return out;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the list holds all 168 firearm cartridges, each name once', () {
    final names = [for (final (n, _) in Cartridges.firearm) n];
    expect(names, hasLength(168));
    expect(names.toSet(), hasLength(168));
  });

  for (final tureFirst in const [true, false]) {
    final order = tureFirst ? 'Tür → Kalibre' : 'Kalibre → Tür';
    group('$order keeps the cartridge and its own ammunition', () {
      for (final (name, _) in Cartridges.firearm) {
        testWidgets(name, (tester) async {
          await _openNewProfile(tester);
          if (tureFirst) {
            await _pick(tester, 'profile-platform', WeaponPlatform.firearm);
            await _pick(tester, 'rifle-caliber', name);
          } else {
            await _pick(tester, 'rifle-caliber', name);
            expect(selectedValue<String>(tester, 'rifle-caliber'), name);
            await _pick(tester, 'profile-platform', WeaponPlatform.firearm);
          }
          expect(
            selectedValue<String>(tester, 'rifle-caliber'),
            name,
            reason: 'Kalibre changed',
          );

          await _pick(tester, 'ammo-source', true); // Fabrika fişeği
          expect(
            selectedValue<String>(tester, 'rifle-caliber'),
            name,
            reason: 'Kalibre changed with Mühimmat türü',
          );
          final expected = <String, int>{};
          for (final a in FactoryAmmoLibrary.all) {
            if (a.cartridge == name) {
              expected[a.brand] = (expected[a.brand] ?? 0) + 1;
            }
          }
          if (expected.isEmpty) {
            // No listed round of this cartridge: only "Diğer marka"
            // (owner, 2026-10-17).
            expect(
              [
                for (final i in _select<String>(
                  tester,
                  'ammo-brand-select',
                ).items)
                  i.value,
              ],
              ['__other'],
            );
          } else {
            expect(await _factoryListed(tester), expected);
          }
          expect(selectedValue<String>(tester, 'rifle-caliber'), name);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
