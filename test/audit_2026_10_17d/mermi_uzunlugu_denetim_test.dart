// Denetim 2026-10-17d: yalnız PR #379 (Mermi uzunluğu Pro'dan Profil >
// Mühimmat'a; Pro'da yalnız ateşli "Mühimmat sıcaklığı" bölümü).
// Rapor: docs/reports/denetim_2026_10_17d.md. Bu testler regresyon
// bekçisidir; açık bulguların testleri `skip:` ile bulgu kimliğini taşır.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

typedef _Shot = ({double? up, double right, String? note});

Future<_Shot> _shot(
  WidgetTester tester, {
  required RifleProfile profile,
  required Map<String, dynamic> rifle,
  required Map<String, dynamic> ammo,
  double? profileLength,
  String? legacy,
  List<Map<String, dynamic>> extra = const [],
}) async {
  tester.view.physicalSize = const Size(430 * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    ShotSettingsStore.keyFor(profile.id): jsonEncode(
      ShotSettings(bulletLengthText: legacy ?? '').toJson(),
    ),
  });
  final a = Map<String, dynamic>.of(ammo)..remove('lengthMm');
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([
      rifle,
      ...extra,
      {...a, if (profileLength != null) 'lengthMm': profileLength},
    ]),
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final dial = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
  final note = find.byKey(const Key('shot-spin-drift'));
  return (
    up: dial.requiredUp,
    right: dial.requiredRight,
    note: note.evaluate().isEmpty ? null : tester.widget<Text>(note).data,
  );
}

// Ateşli .308 benzeri set (sağ yiv, 10 inç).
const _fRifle = <String, dynamic>{
  'id': 'manual_rifle_d17d',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Denetim',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fAmmo = <String, dynamic>{
  'id': 'manual_ammo_d17d',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Denetim 175',
  'model': '',
  'caliberMm': 7.62,
  'grain': 175,
  'ammoType': 'bullet',
  'bc': 0.505,
  'bcModel': 'g1',
};
const _fProfile = RifleProfile(
  id: 'p-d17d',
  name: 'D17D',
  rifleId: 'manual_rifle_d17d',
  ammunitionId: 'manual_ammo_d17d',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 792.48,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

// PCP slug seti (test/uzunluk_sadece_pro_test.dart ile aynı değerler).
const _pRifle = <String, dynamic>{
  'id': 'manual_rifle_d17dp',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölye',
  'model': 'Slug',
  'caliberMm': 6.35,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 17,
  'regulatorBar': 120,
  'sourceName': 'Kullanıcı girdisi',
};
const _pAmmo = <String, dynamic>{
  'id': 'manual_ammo_d17dp',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kendi',
  'model': '',
  'caliberMm': 6.35,
  'grain': 33.95,
  'ammoType': 'slug',
  'bc': 0.1,
  'bcModel': 'g1',
  'sourceName': 'Kullanıcı girdisi',
};
const _pScope = <String, dynamic>{
  'id': 'manual_scope_d17dp',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'Optik',
  'model': '4-16x44',
  'objectiveMm': 44,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'sfp',
  'minMag': 4,
  'maxMag': 16,
};
const _pProfile = RifleProfile(
  id: 'p-d17dp',
  name: 'D17DP',
  rifleId: 'manual_rifle_d17dp',
  ammunitionId: 'manual_ammo_d17dp',
  scopeId: 'manual_scope_d17dp',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 190,
);

void main() {
  group('Miller Sg: bağımsız elle hesap (Miller 2005)', () {
    // .308, 175 gr, d = 0,308 in, uzunluk 1,240 in (31,496 mm), yiv 1:10,
    // 2600 fps (792,48 m/s), 15 °C (59 °F), 1013,25 hPa.
    // t = 32,4675 kalibre, l = 4,02597 kalibre.
    // Sg = 30·175 / (t²·d³·l·(1+l²)) = 2,46034
    // × (2600/2800)^(1/3) = 0,975605 × (59+460)/519 = 1 × 29,92/29,9213
    // = 2,40021.
    test('uygulama formülü elle hesapla aynı', () {
      final sg = Stability.millerSg(
        grain: 175,
        caliberMm: 7.8232,
        twistIn: 10,
        lengthMm: 31.496,
        velocityMps: 792.48,
        temperatureC: 15,
        pressureHpa: 1013.25,
      );
      expect(sg, closeTo(2.4002, 0.002));
    });
  });

  group('Mühimmat sıcaklığı: barut düzeltmesi (1,5 %/15 °C, ref 20, 35 °C)', () {
    test('800 m/s → 812,0 m/s; mühimmat sıcaklığı hava yerine kullanılır', () {
      final t = PowderTemperature.effectiveTempC(airC: 15, ammoC: 35);
      expect(t, 35);
      final f = PowderTemperature.factor(
        coefPercentPer15C: 1.5,
        referenceTempC: 20,
        todayTempC: t,
      );
      expect(800 * f, closeTo(812.0, 1e-9));
    });

    test('eski kayıt: ammoTemp anahtarı aynen okunur, bulletLength korunur', () {
      final s = ShotSettings.fromJson({'ammoTemp': '35', 'bulletLength': '31'});
      expect(s.ammoTempText, '35');
      expect(s.bulletLengthText, '31');
      final back = s.toJson();
      expect(back['ammoTemp'], '35');
      expect(back['bulletLength'], '31');
    });
  });

  group('ateşli: Profil uzunluğu, yoksa eski Pro değeri', () {
    testWidgets('(1) yalnız eski Pro 31,5 = Profil 31,5; (2) Profil kazanır; '
        '(3) hiçbiri yok → spin drift yok', (tester) async {
      Future<_Shot> s({double? p, String? l}) => _shot(
        tester,
        profile: _fProfile,
        rifle: _fRifle,
        ammo: _fAmmo,
        profileLength: p,
        legacy: l,
      );
      final legacy = await s(l: '31.5');
      expect(legacy.note, isNotNull);
      final profile = await s(p: 31.5);
      expect(profile.up, legacy.up);
      expect(profile.right, legacy.right);
      expect(profile.note, legacy.note);
      final both = await s(p: 31.5, l: '40');
      expect(both.up, legacy.up);
      expect(both.right, legacy.right);
      expect(both.note, legacy.note);
      final none = await s();
      expect(none.note, isNull);
    });
  });

  group('PCP slug', () {
    testWidgets('(4) uzunluk varken spin drift var, yokken yok', (tester) async {
      Future<_Shot> s({double? p, String? l}) => _shot(
        tester,
        profile: _pProfile,
        rifle: _pRifle,
        ammo: _pAmmo,
        profileLength: p,
        legacy: l,
        extra: const [_pScope],
      );
      final none = await s();
      expect(none.note, isNull);
      final withLen = await s(p: 10.5);
      expect(withLen.note, isNotNull);
      final legacy = await s(l: '10.5');
      expect(legacy.right, withLen.right);
    });

    testWidgets(
      'D17D-2: 9db11e3\'te gizli profil uzunluğu (10,5 mm, Pro boş) hesabı '
      'değiştirmiyordu; #379 sonrası değiştiriyor',
      (tester) async {
        Future<_Shot> s({double? p}) => _shot(
          tester,
          profile: _pProfile,
          rifle: _pRifle,
          ammo: _pAmmo,
          profileLength: p,
          extra: const [_pScope],
        );
        final before = await s();
        final after = await s(p: 10.5);
        expect(after.right, before.right);
        expect(after.note, before.note);
      },
      skip: true, // D17D-2: açık bulgu (davranış değişikliği, sahibin kararı).
    );
  });

  test(
    'D17D-1: Profil > Mermi uzunluğu üst sınırı (60 mm) eski Pro kutusu ve '
    'hesap sınırından (100 mm) dar; 60 mm üstü mermi profile girilemez',
    () {
      // Açık bulgu: profile_editor.dart _lengthError 1–60 mm; hesap
      // ballistics_screen.dart _bulletLengthMm 0–100 mm kabul eder.
      // Düzeltildiğinde bu test editör üzerinden 62 mm kaydı doğrulamalı.
      fail('D17D-1 açık');
    },
    skip: true, // D17D-1
  );
}
