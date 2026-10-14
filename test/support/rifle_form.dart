// Fills the profile editor's manual rifle form (Marka, Model, Kalibre, Namlu
// yiv yönü, Yiv oranı). Regülatör basıncı and Namlu uzunluğu are not asked.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

Future<void> enterRifleField(
  WidgetTester tester,
  String key,
  String text,
) async {
  final field = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> chooseTwistDirection(WidgetTester tester, String label) async {
  final select = find.byKey(const Key('rifle-twist-direction'));
  await tester.ensureVisible(select);
  await tester.tap(select);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> fillRifleForm(
  WidgetTester tester, {
  String brand = 'Test Marka',
  String model = 'Test Model',
  String caliber = '6.35 mm (.25)',
  String twist = '16',
  String direction = 'Sağ',
}) async {
  // A new profile starts on Ateşli Tüfek (owner, 2026-10-11): a PCP
  // caliber ("6.35 mm (.25)") needs Tür = PCP Tüfek first.
  if (caliber.contains(' mm (') &&
      find.byKey(const Key('profile-platform')).evaluate().isNotEmpty) {
    await chooseInSelect(tester, 'profile-platform', 'PCP Tüfek');
  }
  // Marka / Model come from the lists; typed names open from the link
  // "Aradığın tüfek listede yok mu?" (owner, 2026-10-11, 2026-10-14).
  if (find.byKey(const Key('rifle-brand-select')).evaluate().isNotEmpty) {
    await openRifleManual(tester);
  }
  await enterRifleField(tester, 'rifle-brand', brand);
  await enterRifleField(tester, 'rifle-model', model);
  // Kalibre is picked from a list (owner, 2026-10-09).
  await chooseInSelect(tester, 'rifle-caliber', caliber);
  await enterRifleField(tester, 'rifle-twist-rate', twist);
  await chooseTwistDirection(tester, direction);
}

Future<void> chooseFocalPlane(WidgetTester tester, String label) async {
  final select = find.byKey(const Key('scope-focal-plane'));
  await tester.ensureVisible(select);
  await tester.tap(select);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> chooseInSelect(
  WidgetTester tester,
  String key,
  String label,
) async {
  final select = find.byKey(Key(key));
  await tester.ensureVisible(select);
  await tester.tap(select);
  await tester.pumpAndSettle();
  // Long lists ("Listede yok" is the last item): scroll the open menu.
  // The menu opens at the selected item, so the wanted one may be above it
  // (a smaller büyütme) or below it: try down first, then up.
  final item = find.text(label);
  // The open menu's own item, not the closed field that shows the same text
  // under the menu (a new first brand, Aguila, sat on top of it).
  final inMenu = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
    ),
    matching: item,
  );
  for (final dy in const [-300.0, 300.0]) {
    for (var i = 0; i < 20 && inMenu.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).last, Offset(0, dy));
      await tester.pumpAndSettle();
    }
  }
  final target = inMenu.evaluate().isEmpty ? item.last : inMenu.last;
  // Built but below the menu's visible part: scroll it into view.
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Fills the profile editor's manual ammunition form (PCP slug by default).
Future<void> fillAmmoForm(
  WidgetTester tester, {
  String brand = 'Test Mühimmat',
  String model = 'Test Slug',
  String? type = 'Slug',
  String grain = '33,95',
  String bc = '0,08',
  String bcModel = 'G1',
}) async {
  // Mühimmat türü starts on "Seçiniz" for a firearm (owner, 2026-10-11).
  if (find.byKey(const Key('ammo-source')).evaluate().isNotEmpty) {
    await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
  }
  // Marka and Model are separate boxes again and come from the library
  // lists; a typed name needs "Listede yok" first (owner, 2026-10-11).
  if (find.byKey(const Key('ammo-brand-select')).evaluate().isNotEmpty) {
    await chooseInSelect(tester, 'ammo-brand-select', 'Listede yok');
  }
  // PCP asks no Marka/Model (owner, 2026-10-13).
  if (find.byKey(const Key('ammo-brand')).evaluate().isNotEmpty) {
    await enterRifleField(tester, 'ammo-brand', brand);
    await enterRifleField(tester, 'ammo-model', model);
  }
  if (type != null) await chooseInSelect(tester, 'ammo-type', type);
  await enterRifleField(tester, 'ammo-grain', grain);
  await enterRifleField(tester, 'ammo-bc', bc);
  await chooseBcModel(tester, bcModel);
}

/// BC modeli is asked on firearms only; PCP is always G1 (owner,
/// 2026-10-12).
Future<void> chooseBcModel(WidgetTester tester, String label) async {
  if (find.byKey(const Key('ammo-bc-model')).evaluate().isEmpty) return;
  await chooseInSelect(tester, 'ammo-bc-model', label);
}

/// Fills Atış değerleri: muzzle velocity (fps), zero (m) and sight height (mm).
Future<void> fillShotValues(
  WidgetTester tester, {
  String velocityFps = '900',
  String zero = '25',
  String sight = '60',
}) async {
  await enterRifleField(tester, 'profile-velocity-fps', velocityFps);
  await chooseInSelect(tester, 'profile-distance-unit', 'Metre');
  await enterRifleField(tester, 'profile-zero', zero);
  await enterRifleField(tester, 'scope-sight-height', sight);
}

/// Taps "Aradığın tüfek listede yok mu?" under Tüfek Marka | Model: the
/// typed rifle entry (owner, 2026-10-14: no "Listede yok" in the list).
Future<void> openRifleManual(WidgetTester tester) async {
  final link = find.byKey(const Key('rifle-not-listed'));
  // Mid-screen: at the bottom edge a save bar can cover it.
  await Scrollable.ensureVisible(tester.element(link), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

/// Taps "Aradığın dürbün listede yok mu?" under the Dürbün card: the
/// typed scope entry (owner, 2026-10-13: no "Listede yok" in the list).
Future<void> openScopeManual(WidgetTester tester) async {
  final link = find.byKey(const Key('scope-not-listed'));
  // Mid-screen: at the bottom edge a save bar can cover it.
  await Scrollable.ensureVisible(tester.element(link), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

/// Fills the profile editor's manual scope form.
Future<void> fillScopeForm(
  WidgetTester tester, {
  String brand = 'Test Optik',
  String minMag = '6',
  String maxMag = '24',
  String objective = '56',
  String plane = 'FFP',
  String unit = 'MRAD',
  String click = '0,1 MRAD',
}) async {
  if (find.byKey(const Key('scope-brand-select')).evaluate().isNotEmpty) {
    await openScopeManual(tester);
  }
  await enterRifleField(tester, 'scope-brand', brand);
  // Büyütme and Mercek çapı are picked from lists (owner, 2026-10-11).
  await chooseInSelect(tester, 'scope-min-mag', '${minMag}x');
  await chooseInSelect(tester, 'scope-max-mag', '${maxMag}x');
  await chooseInSelect(tester, 'scope-objective', '$objective mm');
  await chooseFocalPlane(tester, plane);
  // Every list box starts on "Seçiniz" (owner, 2026-10-11).
  await chooseInSelect(tester, 'scope-unit', unit);
  // A typed scope picks its Klik değeri from the unit's list.
  await chooseInSelect(tester, 'scope-click', click);
  await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
}

/// The value picked in the list box under [key] (null: "Seçiniz").
T? selectedValue<T>(WidgetTester tester, String key) => tester
    .state<MenzilSelectState<T>>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(MenzilSelect<T>),
        matchRoot: true,
      ),
    )
    .value;
