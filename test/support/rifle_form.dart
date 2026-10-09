// Fills the profile editor's manual rifle form (Marka, Model, Kalibre, Namlu
// yiv yönü, Yiv oranı). Regülatör basıncı and Namlu uzunluğu are not asked.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  String caliber = '6.35 mm',
  String twist = '16',
  String direction = 'Sağ',
}) async {
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
  await tester.tap(find.text(label).last);
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
  // One "Marka Model" field since 2026-10-09.
  await enterRifleField(tester, 'ammo-brand', '$brand $model');
  if (type != null) await chooseInSelect(tester, 'ammo-type', type);
  await enterRifleField(tester, 'ammo-grain', grain);
  await enterRifleField(tester, 'ammo-bc', bc);
  await chooseInSelect(tester, 'ammo-bc-model', bcModel);
}

/// Fills Atış değerleri: muzzle velocity (fps), zero (m) and sight height (mm).
Future<void> fillShotValues(
  WidgetTester tester, {
  String velocityFps = '900',
  String zero = '25',
  String sight = '60',
}) async {
  await enterRifleField(tester, 'profile-velocity-fps', velocityFps);
  await enterRifleField(tester, 'profile-zero', zero);
  await enterRifleField(tester, 'scope-sight-height', sight);
}

/// Fills the profile editor's manual scope form.
Future<void> fillScopeForm(
  WidgetTester tester, {
  String brand = 'Test Optik',
  String minMag = '6',
  String maxMag = '24',
  String objective = '56',
  String plane = 'FFP',
}) async {
  await enterRifleField(tester, 'scope-brand', brand);
  await enterRifleField(tester, 'scope-min-mag', minMag);
  await enterRifleField(tester, 'scope-max-mag', maxMag);
  await enterRifleField(tester, 'scope-objective', objective);
  await chooseFocalPlane(tester, plane);
}
