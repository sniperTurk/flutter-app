// Hız Doğrulama screen: active profile, BC guard, compute and the explicit
// old -> new confirmation before the profile is written.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/features/tools/truing_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

import 'support/tool_fakes.dart';

const _bcAmmo = Ammunition(
  id: 'test-slug-bc',
  brand: 'Test slug',
  model: '',
  platform: WeaponPlatform.pcp,
  caliberMm: 6.35,
  grain: 51,
  type: AmmunitionType.slug,
  ballisticCoefficient: 0.12,
  ballisticModel: BallisticModel.g1,
  userEntered: true,
);

RifleProfile _profile(String ammoId) => RifleProfile(
  id: 'p1',
  name: 'Hercules',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: ammoId,
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Future<MemoryProfileStore> _pump(WidgetTester tester, RifleProfile p) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(p);
  final active = MemoryActiveProfileStore()..value = p.id;
  await tester.pumpWidget(
    host(TruingScreen(profileStore: store, activeProfileStore: active)),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      const UserCatalog(ammunition: [_bcAmmo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('hub lists Hız Doğrulama', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
    expect(find.byKey(const Key('tool-truing')), findsOneWidget);
  });

  testWidgets('no active profile: says so, no inputs', (tester) async {
    await tester.pumpWidget(
      host(
        TruingScreen(
          profileStore: MemoryProfileStore(),
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('truing-no-profile')), findsOneWidget);
    expect(find.byKey(const Key('truing-range')), findsNothing);
  });

  testWidgets('ammunition without BC is refused', (tester) async {
    await _pump(tester, _profile('gmaz-51'));
    expect(find.byKey(const Key('truing-no-bc')), findsOneWidget);
    expect(find.byKey(const Key('truing-compute')), findsNothing);
  });

  testWidgets('computes the trued velocity and saves only after confirm', (
    tester,
  ) async {
    final store = await _pump(tester, _profile(_bcAmmo.id));
    final observed = const BallisticEngine()
        .solve(
          BallisticInput(
            muzzleVelocityMps: 260,
            grain: 51,
            zeroRangeM: 25,
            sightHeightMm: 60,
            rangesM: const [100],
            ballisticCoefficient: 0.12,
            ballisticModel: BallisticModel.g1,
          ),
        )
        .single
        .correctionMrad;

    await tester.enterText(find.byKey(const Key('truing-range')), '100');
    await tester.enterText(
      find.byKey(const Key('truing-observed')),
      observed.toStringAsFixed(6).replaceAll('.', ','),
    );
    await tester.ensureVisible(find.byKey(const Key('truing-compute')));
    await tester.tap(find.byKey(const Key('truing-compute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('truing-error')), findsNothing);
    expect(find.byKey(const Key('truing-result')), findsOneWidget);
    // Velocity is shown in fps, as on Profil: 260 m/s = 853 fps.
    expect(find.text('853 fps'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('truing-apply')));
    await tester.tap(find.byKey(const Key('truing-apply')));
    await tester.pumpAndSettle();
    // Nothing is written before the confirmation.
    expect((await store.all()).single.muzzleVelocityMps, 270);
    await tester.tap(find.byKey(const Key('truing-confirm')));
    await tester.pumpAndSettle();
    expect((await store.all()).single.muzzleVelocityMps, closeTo(260, 0.15));
  });

  testWidgets('range inside the zero shows the reason', (tester) async {
    await _pump(tester, _profile(_bcAmmo.id));
    await tester.enterText(find.byKey(const Key('truing-range')), '20');
    await tester.enterText(find.byKey(const Key('truing-observed')), '1');
    await tester.ensureVisible(find.byKey(const Key('truing-compute')));
    await tester.tap(find.byKey(const Key('truing-compute')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('truing-error')), findsOneWidget);
    expect(find.textContaining('sıfır mesafesinden uzak'), findsOneWidget);
  });
}
