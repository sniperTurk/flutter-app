// Pro sıcaklık notu (owner, 2026-10-18 01:32–01:34, TestFlight 115): the
// explanation lines under the Mühimmat sıcaklığı box ("Hesapta kullanılan…"
// / "Mühimmat sıcaklığının hesaba girmesi için…" and "Bugünkü hız…") use the
// small status-note style of the Coriolis/Yerçekimi notes:
// MenzilType.caption(ink2), not the bold body style. Text unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sn',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sn',
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
  id: 'p-sn',
  name: 'SN',
  rifleId: 'manual_rifle_sn',
  ammunitionId: 'manual_ammo_sn',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: k,
  powderTempReferenceC: t0,
);

const _source = Key('pro-powder-source');
const _today = Key('pro-powder-today');
Widget _app(
  RifleProfile p,
  double scale, {
  BallisticsView view = BallisticsView.pro,
}) => MaterialApp(
  theme: MenzilTheme.light(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

Future<void> _open(
  WidgetTester tester,
  RifleProfile p, {
  required double width,
  required double scale,
  String? airTemp,
}) async {
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (airTemp != null) {
    // "Bugünkü hız" needs Hava sıcaklığı (Hava Durumu); the cartridge
    // temperature follows it while Mühimmat sıcaklığı is empty.
    await tester.pumpWidget(_app(p, scale, view: BallisticsView.environment));
    await tester.pumpAndSettle();
    final f = find.descendant(
      of: find.byKey(BallisticsFieldKeys.temperature),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(f);
    await tester.enterText(f, airTemp);
    await tester.pumpAndSettle();
  }
  await tester.pumpWidget(_app(p, scale));
  await tester.pumpAndSettle();
  await openProFor(tester, _source);
  expect(tester.takeException(), isNull);
}

void _expectCaption(WidgetTester tester, Key key) {
  final ctx = tester.element(find.byKey(key));
  final want = MenzilType.caption(MenzilColors.of(ctx).ink2);
  final style = tester.widget<Text>(find.byKey(key)).style!;
  expect(style.fontSize, want.fontSize, reason: '$key size');
  expect(style.fontSize, 12.5, reason: '$key size');
  expect(style.fontWeight, want.fontWeight, reason: '$key weight');
  expect(style.fontWeight, FontWeight.w400, reason: '$key not bold');
  expect(style.height, want.height, reason: '$key line height');
  expect(style.color, MenzilColors.light.ink2, reason: '$key colour');
  expect(style, want, reason: '$key = caption(ink2)');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final width in [390.0, 320.0]) {
    for (final scale in [1.0, 1.3]) {
      final tag = '${width.toInt()} pt, ×$scale';

      testWidgets('"Mühimmat sıcaklığının hesaba girmesi…" is caption/ink2 '
          '($tag)', (tester) async {
        await _open(tester, _firearm(), width: width, scale: scale);
        expect(
          tester.widget<Text>(find.byKey(_source)).data,
          startsWith('Mühimmat sıcaklığının hesaba girmesi için'),
        );
        _expectCaption(tester, _source);
      });

      testWidgets('"Hesapta kullanılan…" and "Bugünkü hız…" are caption/ink2 '
          '($tag)', (tester) async {
        await _open(
          tester,
          _firearm(k: 1, t0: 10),
          width: width,
          scale: scale,
          airTemp: '5',
        );
        expect(
          tester.widget<Text>(find.byKey(_source)).data,
          'Hesapta kullanılan: Barut katsayısı %1 / 15 °C, Hız ölçüm '
          'sıcaklığı 10 °C. Değiştirmek için Profil → Mühimmat.',
        );
        expect(
          tester.widget<Text>(find.byKey(_today)).data,
          startsWith('Bugünkü hız: '),
        );
        _expectCaption(tester, _source);
        _expectCaption(tester, _today);
        // Left-aligned, unchanged: no textAlign set.
        expect(tester.widget<Text>(find.byKey(_source)).textAlign, isNull);
        expect(tester.widget<Text>(find.byKey(_today)).textAlign, isNull);
      });
    }
  }
}
