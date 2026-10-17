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
    tester.widget<Text>(find.byKey(key)).data!;

/// One line, nothing cut, inside the card, between Vuruş noktası and the
/// Hesap dökümü header.
void _expectOneLineAbove(
  WidgetTester tester,
  Key key,
  double width,
  double textScale,
) {
  final p = tester.renderObject<RenderParagraph>(find.byKey(key));
  expect(p.didExceedMaxLines, isFalse);
  // Height of one line of the same style and scale.
  final one = TextPainter(
    text: TextSpan(text: 'Rg', style: p.text.style),
    textDirection: TextDirection.ltr,
    textScaler: p.textScaler,
  )..layout();
  expect(p.size.height, closeTo(one.height, 0.5));
  // The whole line (shrunk if needed) stays on screen, left-aligned with
  // the Vuruş noktası line.
  final rect = tester.getRect(find.byKey(key));
  final impact = tester.getRect(find.byKey(ScopeDialKeys.impactText));
  expect(rect.left, closeTo(impact.left, 0.5));
  expect(rect.right, lessThanOrEqualTo(width));
  final workings = tester.getRect(find.byKey(ScopeDialKeys.workingsToggle));
  expect(rect.top, greaterThan(impact.bottom));
  expect(rect.bottom, lessThan(workings.top));
  debugPrint('RUZGAR_SATIR ${textScale}x: ${_text(tester, key)} | $rect');
}

void main() {
  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('390 pt: both wind lines above Hesap dökümü, exact texts', (
    tester,
  ) async {
    await _seed();
    await _show(tester);
    final dial = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
    final bracket = _text(tester, _bracket);
    final m = RegExp(
      r'^Rüzgâr 6,2 m/s: (\d+) klik (sağ|sol) · 9,3 m/s: (\d+) klik (sağ|sol)$',
    ).firstMatch(bracket);
    expect(m, isNotNull, reason: bracket);
    // Low end = the side turret's own clicks (same as main).
    expect(
      int.parse(m!.group(1)!),
      (dial.requiredRight.abs() / dial.clickValue).round(),
    );
    expect(m.group(2), dial.requiredRight >= 0 ? 'sağ' : 'sol');
    expect(m.group(4), m.group(2));
    expect(int.parse(m.group(3)!), greaterThan(int.parse(m.group(1)!)));

    final shares = _text(tester, _shares);
    final s = RegExp(
      r'^Yana kayma: yakın %(\d+) · orta %(\d+) · uzak %(\d+)$',
    ).firstMatch(shares);
    expect(s, isNotNull, reason: shares);
    final pct = [for (var i = 1; i <= 3; i++) int.parse(s!.group(i)!)];
    expect(pct[0] + pct[1] + pct[2], 100);

    // Order: Vuruş noktası → Rüzgâr → Yana kayma → Hesap dökümü.
    final dy = [
      tester.getTopLeft(find.byKey(ScopeDialKeys.impactText)).dy,
      tester.getTopLeft(find.byKey(_bracket)).dy,
      tester.getTopLeft(find.byKey(_shares)).dy,
      tester.getTopLeft(find.byKey(ScopeDialKeys.workingsToggle)).dy,
    ];
    for (var i = 1; i < dy.length; i++) {
      expect(dy[i], greaterThan(dy[i - 1]), reason: '$dy');
    }
    _expectOneLineAbove(tester, _bracket, 390, 1);
    _expectOneLineAbove(tester, _shares, 390, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 pt at text scale 1.3: still one line each, no overflow', (
    tester,
  ) async {
    await _seed();
    await _show(tester, width: 320, textScale: 1.3);
    expect(tester.takeException(), isNull);
    _expectOneLineAbove(tester, _bracket, 320, 1.3);
    _expectOneLineAbove(tester, _shares, 320, 1.3);
    // Same numbers as at 390 pt; only the size changes.
    expect(
      _text(tester, _bracket),
      matches(RegExp(r'^Rüzgâr 6,2 m/s: \d+ klik (sağ|sol) · 9,3 m/s: ')),
    );
  });

  testWidgets('without En yüksek rüzgâr: no Rüzgâr line, Yana kayma stays '
      '(as on main)', (tester) async {
    await _seed(windMax: '');
    await _show(tester);
    expect(find.byKey(_bracket), findsNothing);
    expect(_text(tester, _shares), startsWith('Yana kayma: yakın %'));
    _expectOneLineAbove(tester, _shares, 390, 1);
  });
}
