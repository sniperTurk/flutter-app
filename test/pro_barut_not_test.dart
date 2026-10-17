// Pro barut notu (owner, 2026-10-17 10:28–10:35, TestFlight 112): the
// powder note under the Mühimmat sıcaklığı box (its own Pro box since
// 2026-10-17 11:41) reads exactly the owner-approved texts for its three
// cases.
// Report: docs/reports/pro_barut_not.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_pn',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_pn',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

RifleProfile _firearm({double? k, double? t0}) => RifleProfile(
  id: 'p-pn',
  name: 'PN',
  rifleId: 'manual_rifle_pn',
  ammunitionId: 'manual_ammo_pn',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: k,
  powderTempReferenceC: t0,
);

const _missing =
    'Mühimmat sıcaklığının hesaba girmesi için Profil → Mühimmat\'ta Barut '
    'katsayısı ve Hız ölçüm sıcaklığı kutularını doldurun. Bu iki kutu boşsa '
    'buraya yazılan sıcaklık hesabı değiştirmez.';

const _note = Key('pro-powder-source');

Widget _app(RifleProfile p, {double scale = 1}) => MaterialApp(
  theme: MenzilTheme.light(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: BallisticsView.pro),
  ),
);

Future<String> _noteText(
  WidgetTester tester,
  RifleProfile p, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(p, scale: scale));
  await tester.pumpAndSettle();
  await openProFor(tester, _note);
  expect(tester.takeException(), isNull);
  return tester.widget<Text>(find.byKey(_note)).data!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('note case 1: Barut katsayısı or Hız ölçüm sıcaklığı missing', () {
    testWidgets('both empty', (tester) async {
      expect(await _noteText(tester, _firearm()), _missing);
    });
    testWidgets('only Barut katsayısı', (tester) async {
      expect(await _noteText(tester, _firearm(k: 1.5)), _missing);
    });
    testWidgets('only Hız ölçüm sıcaklığı', (tester) async {
      expect(await _noteText(tester, _firearm(t0: 20)), _missing);
    });
  });

  testWidgets('note case 2: both from the profile', (tester) async {
    expect(
      await _noteText(tester, _firearm(k: 1.5, t0: 20)),
      'Hesapta kullanılan: Barut katsayısı %1,5 / 15 °C, Hız ölçüm '
      'sıcaklığı 20 °C. Değiştirmek için Profil → Mühimmat.',
    );
  });

  testWidgets('note case 3: entered on Pro in an older version', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor('p-pn'): jsonEncode(
        const ShotSettings(
          powderCoefText: '1,2',
          powderTempText: '21',
        ).toJson(),
      ),
    });
    expect(
      await _noteText(tester, _firearm()),
      'Hesapta kullanılan: Barut katsayısı %1,2 / 15 °C, Hız ölçüm '
      'sıcaklığı 21 °C. Bu değerler eski sürümde burada girilmişti; artık '
      'Profil → Mühimmat\'ta değiştirilir.',
    );
  });

  testWidgets('the old note texts are gone', (tester) async {
    await _noteText(tester, _firearm());
    expect(find.textContaining('girilmezse hız'), findsNothing);
    expect(find.textContaining('Profil > Mühimmat'), findsNothing);
    expect(find.text('isteğe bağlı'), findsNothing);
  });

  testWidgets('320 pt, text scale 1.3: the note is laid out without '
      'overflow', (tester) async {
    final text = await _noteText(tester, _firearm(), width: 320, scale: 1.3);
    expect(text, _missing);
    await tester.ensureVisible(find.byKey(_note));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byKey(_note)).right, lessThanOrEqualTo(320));
  });

  testWidgets('320 pt, text scale 1: the Mühimmat sıcaklığı box sits in '
      'the column of Yukarı + / aşağı −', (tester) async {
    await _noteText(tester, _firearm(), width: 320);
    Rect r(String k) => tester.getRect(
      find.descendant(of: find.byKey(Key(k)), matching: find.byType(TextField)),
    );
    final temp = r('env-ammo-temp');
    await openProFor(tester, const Key('pro-zero-up'));
    final up = r('pro-zero-up');
    expect(temp.left, moreOrLessEquals(up.left, epsilon: 0.5));
    expect(temp.width, moreOrLessEquals(up.width, epsilon: 0.5));
    expect(tester.takeException(), isNull);
  });
}
