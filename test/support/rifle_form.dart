// Fills the profile editor's manual rifle form (Marka, Model, Kalibre, Namlu
// uzunluğu, Namlu yiv yönü, Yiv oranı).
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
  String caliber = '6,35',
  String barrel = '600',
  String twist = '16',
  String direction = 'Sağ',
  String? regulator = '120',
}) async {
  await enterRifleField(tester, 'rifle-brand', brand);
  await enterRifleField(tester, 'rifle-model', model);
  await enterRifleField(tester, 'rifle-caliber', caliber);
  await enterRifleField(tester, 'rifle-barrel', barrel);
  await enterRifleField(tester, 'rifle-twist-rate', twist);
  if (regulator != null) {
    await enterRifleField(tester, 'rifle-regulator', regulator);
  }
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
