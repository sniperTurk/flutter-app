// Mühimmat sıcaklığı Pro Ayarlar'da (owner, 2026-10-16 20:06, design PR
// #366 "onayladım"): Hava Durumu'ndaki bölüm kalktı; aynı kutu Pro >
// Tüfek düzeltmeleri içinde, Mermi uzunluğu'nun altında, barut katsayısı
// yazısının üstünde; kutu satırın sol yarısında, "isteğe bağlı" sağ
// yarısında. Yalnız ateşli silahta. Anahtar, kayıt ve barut düzeltmesi
// (boşsa hava sıcaklığı) değişmedi. Rapor: docs/reports/duzeltmeler_16_10.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mb',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_mb',
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

const _firearm = RifleProfile(
  id: 'p-mb',
  name: 'MB',
  rifleId: 'manual_rifle_mb',
  ammunitionId: 'manual_ammo_mb',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 15,
);

const _pcp = RifleProfile(
  id: 'p-mb-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _ammoKey = Key('env-ammo-temp');
const _row = Key('pro-ammo-temp-row');
const _optional = Key('pro-ammo-temp-optional');

Widget _app(
  RifleProfile p,
  BallisticsView view, {
  double scale = 1,
  bool dark = false,
}) => MaterialApp(
  theme: dark ? MenzilTheme.dark() : MenzilTheme.light(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

Future<void> _size(WidgetTester tester, double width, [double h = 3000]) async {
  tester.view.physicalSize = Size(width, h) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder _textField(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

/// Pro Ayarlar with Tüfek düzeltmeleri open.
Future<void> _pro(WidgetTester tester, RifleProfile p, {double scale = 1}) async {
  await tester.pumpWidget(_app(p, BallisticsView.pro, scale: scale, dark: true));
  await tester.pumpAndSettle();
  final header = find.byKey(const Key('pro-section-rifle'));
  await tester.ensureVisible(header);
  await tester.pumpAndSettle();
  await tapProHeader(tester, header);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Hava Durumu: no Mühimmat sıcaklığı section any more', (
    tester,
  ) async {
    await _size(tester, 430);
    await tester.pumpWidget(
      _app(_firearm, BallisticsView.environment, dark: true),
    );
    await tester.pumpAndSettle();
    for (final k in const [
      'environment-ammo-temp-header',
      'environment-ammo-temp-info',
      'environment-ammo-temp-optional',
      'environment-ammo-temp-card',
      'env-ammo-temp',
    ]) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
    expect(find.text('Mühimmat sıcaklığı'), findsNothing);
    // The rest of Hava Durumu is unchanged: Sıcaklık | Bağıl nem, then
    // Basınç Ölçer under the weather button.
    final air = tester.getRect(_textField(BallisticsFieldKeys.temperature));
    final hum = tester.getRect(_textField(BallisticsFieldKeys.humidity));
    expect(hum.top, moreOrLessEquals(air.top, epsilon: 0.01));
    expect(
      tester.getRect(find.byKey(const Key('environment-barometer-card'))).top,
      greaterThan(
        tester.getRect(find.byKey(const Key('environment-fill-weather'))).bottom,
      ),
    );
  });

  testWidgets('firearm: Pro > Tüfek düzeltmeleri, under Mermi uzunluğu and '
      'above the powder text; box left half, "isteğe bağlı" right half', (
    tester,
  ) async {
    await _size(tester, 390);
    await _pro(tester, _firearm);
    final box = find.byKey(_ammoKey);
    expect(box, findsOneWidget);
    // Inside the Tüfek düzeltmeleri box.
    expect(
      find.descendant(
        of: find.byKey(const Key('pro-box-rifle')),
        matching: box,
      ),
      findsOneWidget,
    );
    final length = tester.getRect(find.byKey(const Key('pro-bullet-length')));
    final powder = tester.getRect(find.byKey(const Key('pro-powder-source')));
    final row = tester.getRect(find.byKey(_row));
    expect(row.top, greaterThanOrEqualTo(length.bottom - 0.01));
    expect(row.bottom, lessThanOrEqualTo(powder.top + 0.01));
    // Box in the left half, "isteğe bağlı" in the right half of one row.
    final field = tester.getRect(_textField(_ammoKey));
    final opt = tester.getRect(find.byKey(_optional));
    expect(field.left, moreOrLessEquals(row.left, epsilon: 0.5));
    expect(field.width, moreOrLessEquals((row.width - 10) / 2, epsilon: 0.5));
    expect(opt.left, greaterThanOrEqualTo(field.right + 10 - 0.5));
    expect(opt.right, lessThanOrEqualTo(row.right + 0.01));
    // Level with the box.
    expect(opt.center.dy, moreOrLessEquals(field.center.dy, epsilon: 3));
    expect(tester.widget<Text>(find.byKey(_optional)).data, 'isteğe bağlı');
    expect(
      tester.widget<Text>(find.byKey(_optional)).style!.color,
      const Color(0xFF9CB1C0),
    );
    // Same label, unit, ⓘ text as on Hava Durumu before.
    final input = tester.widget<MenzilInput>(box);
    expect(input.label, 'Mühimmat sıcaklığı');
    expect(input.unit, '°C');
    expect(input.info, EnvironmentFieldInfo.ammoTemperature);
    // Listed in the box's ⓘ sheet; the box's own ⓘ opens that sheet.
    await tester.tap(find.byKey(const Key('pro-info-rifle')));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('pro-info-sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Mühimmat sıcaklığı')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PCP: no Mühimmat sıcaklığı on Pro', (tester) async {
    await _size(tester, 430);
    await _pro(tester, _pcp);
    expect(find.byKey(_ammoKey), findsNothing);
    expect(find.byKey(_row), findsNothing);
    expect(find.byKey(_optional), findsNothing);
    expect(find.text('Mühimmat sıcaklığı'), findsNothing);
  });

  testWidgets('summary of the closed box counts an entered value', (
    tester,
  ) async {
    await _size(tester, 430);
    await _pro(tester, _firearm);
    await tester.enterText(_textField(_ammoKey), '30');
    await tester.pumpAndSettle();
    await tapProHeader(tester, find.byKey(const Key('pro-section-rifle')));
    expect(
      tester.widget<Text>(find.byKey(const Key('pro-summary-rifle'))).data,
      '1 ayar açık',
    );
  });

  testWidgets('a saved value loads into the moved box and gives the same '
      'solution as typing it', (tester) async {
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor(_firearm.id): jsonEncode(
        const ShotSettings(ammoTempText: '35').toJson(),
      ),
    });
    await _size(tester, 430);

    Future<double> up600() async {
      await tester.pumpWidget(_app(_firearm, BallisticsView.pro));
      await tester.pumpAndSettle();
      final range = _textField(const Key('pro-shot-range'));
      await tester.ensureVisible(range);
      await tester.enterText(range, '600');
      await tester.pump();
      await tester.pumpWidget(_app(_firearm, BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredUp!;
    }

    Future<void> typeAmmo(String v) async {
      await tester.pumpWidget(_app(_firearm, BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, _ammoKey);
      final f = _textField(_ammoKey);
      await tester.ensureVisible(f);
      await tester.enterText(f, v);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(_app(_firearm, BallisticsView.pro));
    await tester.pumpAndSettle();
    await openProFor(tester, _ammoKey);
    expect(
      tester.widget<TextField>(_textField(_ammoKey)).controller!.text,
      '35',
    );
    final saved = await up600();

    // Empty: the air temperature (the behaviour on main).
    await typeAmmo('');
    final plain = await up600();
    expect(saved, lessThan(plain));

    // Typed again: exactly the saved result.
    await typeAmmo('35');
    expect(await up600(), saved);

    // Saved under the same key as before.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ShotSettingsStore.keyFor(_firearm.id))!;
    expect((jsonDecode(raw) as Map)['ammoTemp'], '35');
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('no overflow at $width pt, text scale 1.3', (tester) async {
      await _size(tester, width, 844);
      await _pro(tester, _firearm, scale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(_row));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(_optional), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_row)).right,
        lessThanOrEqualTo(width + 0.01),
      );
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'scroll step $i');
      }
    });
  }
}
