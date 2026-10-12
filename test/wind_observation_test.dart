// Ö2 (docs/yeni-hesaplar-2026-10-11.md): Rüzgâr gözlemi fills Rüzgâr hızı
// with the Beaufort class middle and En yüksek rüzgâr with its top; Hedef
// shows how much of the wind drift each third of the path gives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/pro_sections.dart';

const _profile = RifleProfile(
  id: 'p-obs',
  name: 'Gözlem',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-obs',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

/// A pellet with a G1 BC, so Hedef uses the drag solver (wind exists).
void _installDragAmmo() => CatalogRepository.installUserCatalog(
  UserCatalog.fromManualEntries([
    {
      'id': 'c-obs',
      'kind': 'custom_ammunition',
      'platform': 'pcp',
      'brand': 'Deneme',
      'model': '.25 pellet',
      'caliberMm': 6.35,
      'grain': 25.4,
      'ammoType': 'pellet',
      'bc': 0.04,
      'bcModel': 'G1',
    },
  ]),
);

Widget _app(BallisticsView view) => MaterialApp(
  home: Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  ),
);

Finder _field(Key k) =>
    find.descendant(of: find.byKey(k), matching: find.byType(TextField));

String _text(WidgetTester tester, Key k) =>
    tester.widget<TextField>(_field(k)).controller!.text;

/// En yüksek rüzgâr lives on Pro Ayarlar (owner, 2026-10-12): read it there
/// and come back to Hava Durumu (same workspace state).
Future<String> _windMaxOnPro(WidgetTester tester) async {
  await tester.pumpWidget(_app(BallisticsView.pro));
  await tester.pumpAndSettle();
  await openProFor(tester, const Key('pro-wind-max'));
  final v = _text(tester, const Key('pro-wind-max'));
  await tester.pumpWidget(_app(BallisticsView.environment));
  await tester.pumpAndSettle();
  return v;
}

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder get _select => find.byWidgetPredicate(
  (w) => w is MenzilSelect<int> && w.label == 'Rüzgâr gözlemi',
);

Future<void> _pick(WidgetTester tester, String prefix) async {
  await tester.ensureVisible(_select);
  await tester.pumpAndSettle();
  await tester.tap(_select);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(prefix).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _installDragAmmo();
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('starts at Seçiniz with an ⓘ that warns about the 10 m height', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    final s = tester.widget<MenzilSelect<int>>(_select);
    expect(s.hint, 'Seçiniz');
    expect(s.initialValue, isNull);
    expect(s.info, EnvironmentFieldInfo.windObservation);
    expect(s.info, contains('10 m'));
    // "Seçiniz" + 8 classes: looking and leaving needs no choice.
    expect(s.items, hasLength(9));
    expect(s.items.first.value, isNull);
    expect(s.label.contains('('), isFalse);
  });

  testWidgets('a class fills Rüzgâr hızı and En yüksek rüzgâr', (tester) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await _pick(tester, 'Hafif: ');
    expect(_text(tester, BallisticsFieldKeys.wind), '2.5');
    expect(await _windMaxOnPro(tester), '3.3');
    // Rüzgâr is further down since Basınç ölçer (2026-10-12): scroll to it.
    await tester.ensureVisible(_select);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _select, matching: find.text('Hafif')),
      findsOneWidget,
    );

    // Still editable: a typed wind is the shooter's and resets the list.
    await tester.ensureVisible(_field(BallisticsFieldKeys.wind));
    await tester.enterText(_field(BallisticsFieldKeys.wind), '4');
    await tester.pumpAndSettle();
    expect(tester.widget<MenzilSelect<int>>(_select).initialValue, isNull);
    expect(await _windMaxOnPro(tester), '3.3');
  });

  testWidgets('"Seçiniz" in the list leaves without changing the wind', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    final before = _text(tester, BallisticsFieldKeys.wind);
    await tester.ensureVisible(_select);
    await tester.pumpAndSettle();
    await tester.tap(_select);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seçiniz').last);
    await tester.pumpAndSettle();
    expect(_text(tester, BallisticsFieldKeys.wind), before);
    expect(tester.widget<MenzilSelect<int>>(_select).initialValue, isNull);
  });

  testWidgets('Hedef shows the near / middle / far wind shares', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await _pick(tester, 'Orta: ');
    // From 9 o'clock: a full-value crosswind.
    await tester.ensureVisible(_field(BallisticsFieldKeys.windDirection));
    await tester.enterText(_field(BallisticsFieldKeys.windDirection), '9');
    await tester.pump();
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    final line = tester
        .widget<Text>(find.byKey(const Key('shot-wind-zone-shares')))
        .data!;
    final m = RegExp(
      r'^Rüzgâr etkisi: yakın %(\d+) · orta %(\d+) · uzak %(\d+)$',
    ).firstMatch(line);
    expect(m, isNotNull, reason: line);
    final p = [for (var i = 1; i <= 3; i++) int.parse(m!.group(i)!)];
    expect(p[0] + p[1] + p[2], 100);
    expect(p[0], greaterThan(p[1]));
    expect(p[1], greaterThan(p[2]));
  });

  testWidgets('no shares without a BC: the vacuum model has no wind', (
    tester,
  ) async {
    CatalogRepository.installUserCatalog(UserCatalog.empty);
    await _sized(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BallisticsScreen(
            profile: RifleProfile(
              id: 'p-vac',
              name: 'Boşluk',
              rifleId: 'hatsan-hercules-635',
              ammunitionId: 'gmaz-51',
              scopeId: 'gazi-6-36',
              muzzleVelocityMps: 270,
              zeroRangeM: 25,
              sightHeightMm: 60,
            ),
            view: BallisticsView.shot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shot-wind-zone-shares')), findsNothing);
  });
}
