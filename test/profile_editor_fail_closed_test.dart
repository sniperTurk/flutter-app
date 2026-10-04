import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _stale = RifleProfile(
  id: 'stale',
  name: 'Eski Profil',
  rifleId: 'removed-rifle-id',
  ammunitionId: 'removed-ammo-id',
  scopeId: 'removed-scope-id',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 180,
);

const _valid = RifleProfile(
  id: 'valid',
  name: 'Gecerli Profil',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<MemoryProfileStore> _pumpAndOpen(
  WidgetTester tester,
  RifleProfile profile,
) async {
  tester.view.physicalSize = const Size(390 * 3, 1800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(profile.name).first);
  await tester.pumpAndSettle();
  return store;
}

VoidCallback? _updateAction(WidgetTester tester) => tester
    .widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
    )
    .onPressed;

void main() {
  testWidgets(
    'editing a profile with unresolved catalog ids never substitutes a catalog entry',
    (tester) async {
      final store = await _pumpAndOpen(tester, _stale);
      expect(find.text('Profili Düzenle'), findsOneWidget);
      expect(find.textContaining('sessizce seçilmedi'), findsOneWidget);
      expect(
        _updateAction(tester),
        isNull,
        reason: 'Güncelle must stay disabled until the user picks explicitly',
      );
      // Nothing was written.
      final stored = (await store.all()).single;
      expect(stored.rifleId, 'removed-rifle-id');
      expect(stored.ammunitionId, 'removed-ammo-id');
      expect(stored.scopeId, 'removed-scope-id');
    },
  );

  testWidgets('editing a fully resolvable profile keeps Güncelle enabled', (
    tester,
  ) async {
    await _pumpAndOpen(tester, _valid);
    expect(find.textContaining('sessizce seçilmedi'), findsNothing);
    expect(_updateAction(tester), isNotNull);
  });
}
