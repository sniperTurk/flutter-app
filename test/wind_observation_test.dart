// Ö2 (docs/yeni-hesaplar-2026-10-11.md): Rüzgâr gözlemi is hidden behind
// WIND_OBSERVATION (owner, 2026-10-13: its class middle overwrote a fetched
// wind; the display-only guide is in wind_guide_test.dart). Hedef shows how
// much of the wind drift each third of the path gives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

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

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder get _select => find.byWidgetPredicate(
  (w) => w is MenzilSelect<int> && w.label == 'Rüzgâr gözlemi',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _installDragAmmo();
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Rüzgâr gözlemi is hidden by default (WIND_OBSERVATION)', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    // Owner, 2026-10-13: its class middle overwrote a fetched wind.
    expect(_select, findsNothing);
    expect(find.text('Rüzgâr gözlemi'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('wind-observation-'),
      ),
      findsNothing,
    );
    // Rüzgâr hızı / Rüzgâr yönü stay; the ⓘ text is kept for the flag.
    expect(find.byKey(BallisticsFieldKeys.wind), findsOneWidget);
    expect(find.byKey(BallisticsFieldKeys.windDirection), findsOneWidget);
    expect(EnvironmentFieldInfo.windObservation, contains('10 m'));
  });

  testWidgets('Hedef shows the near / middle / far wind shares', (
    tester,
  ) async {
    await _sized(tester);
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    // Orta's middle, typed by the shooter (the select is hidden).
    await tester.ensureVisible(_field(BallisticsFieldKeys.wind));
    await tester.enterText(_field(BallisticsFieldKeys.wind), '4.4');
    await tester.pump();
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
