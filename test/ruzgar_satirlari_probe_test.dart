// Hedef: the two wind lines (owner, 2026-10-17, TestFlight 112: "Yazı
// sanki hesap dökümü olarak algılanıyor" · "İki yazıyı da tek satıra
// sığdır, toplam 2 satır olacak"). They sit between the Vuruş noktası
// paragraph and "Hesap dökümü", each on one line that shrinks instead of
// wrapping. Report: docs/reports/ruzgar_satirlari.md.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/wind_clock.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';

// A PCP slug with a G1 BC so the drag solver (wind) runs, as in
// test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart.
const _ammo = <String, dynamic>{
  'id': 'c-ruz-satir',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 34,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'G1',
};

const _profile = RifleProfile(
  id: 'p-ruz-satir',
  name: 'Rüzgâr satırları',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-ruz-satir',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 60,
);

const _bracket = Key('shot-wind-bracket');
const _shares = Key('shot-wind-zone-shares');

/// Hava Durumu wind 6,2 m/s from 9 o'clock; En yüksek rüzgâr 9,3 m/s
/// unless [windMax] is empty.
Future<void> _seed({String windMax = '9.3'}) async {
  SharedPreferences.setMockInitialValues({});
  await const ShotSettingsStore().save(
    _profile.id,
    ShotSettings(
      weatherSaved: true,
      weatherSi: {'wind': 6.2, 'windDirection': WindClock.toDegrees(9)},
      windMaxText: windMax,
      windMaxOff: windMax.isEmpty,
    ),
  );
}

Future<void> _show(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 3200) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(
        body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    find.byKey(key).evaluate().isEmpty
    ? 'yok'
    : tester.widget<Text>(find.byKey(key)).data!;

void main() {
  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final max in ['9.3', '']) {
    testWidgets('probe main texts, windMax="$max"', (tester) async {
      await _seed(windMax: max);
      await _show(tester);
      final dial = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
      debugPrint('PROBE max=$max bracket: ${_text(tester, _bracket)}');
      debugPrint('PROBE max=$max shares: ${_text(tester, _shares)}');
      debugPrint(
        'PROBE max=$max right=${dial.requiredRight} click=${dial.clickValue}',
      );
    });
  }
}
