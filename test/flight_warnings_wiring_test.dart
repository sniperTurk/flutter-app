// Ö5 (owner, 2026-10-11): Sg and transonic notices on the shot panel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_fx',
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
const _profile = RifleProfile(
  id: 'p-fx',
  name: 'FX',
  rifleId: 'manual_rifle_fx',
  ammunitionId: 'manual_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  Widget app(BallisticsView view) => MaterialApp(
    theme: MenzilTheme.light(),
    home: Scaffold(
      body: BallisticsScreen(profile: _profile, view: view),
    ),
  );

  Future<void> type(WidgetTester tester, Key key, String v) async {
    await openProFor(tester, key);
    final f = find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(f);
    await tester.enterText(f, v);
    await tester.pump();
  }

  Future<void> shotWith(
    WidgetTester tester, {
    String? lengthMm,
    String? rangeM,
  }) async {
    tester.view.physicalSize = const Size(430, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(BallisticsView.pro));
    await tester.pumpAndSettle();
    if (rangeM != null) {
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('pro-shot-range')),
          matching: find.byType(TextField),
        ),
        rangeM,
      );
      await tester.pump();
    }
    if (lengthMm != null) {
      await type(tester, const Key('pro-bullet-length'), lengthMm);
    }
    await tester.pumpWidget(app(BallisticsView.shot));
    await tester.pumpAndSettle();
  }

  const unstable = Key('shot-stability-unstable');
  const marginal = Key('shot-stability-marginal');
  const transonic = Key('shot-transonic');

  testWidgets('mermi uzunluğu yoksa uyarı yok', (tester) async {
    await shotWith(tester);
    expect(find.byKey(unstable), findsNothing);
    expect(find.byKey(marginal), findsNothing);
    expect(find.byKey(transonic), findsNothing);
  });

  testWidgets('kararlı mermi: uyarı yok', (tester) async {
    // .308 168 gr, 31 mm, 1:10 at 800 m/s: Sg ≈ 2.3.
    await shotWith(tester, lengthMm: '31');
    expect(find.byKey(unstable), findsNothing);
    expect(find.byKey(marginal), findsNothing);
  });

  testWidgets('uzun mermi Sg ≈ 1.27: BC uyarısı', (tester) async {
    await shotWith(tester, lengthMm: '38');
    expect(find.byKey(marginal), findsOneWidget);
    expect(find.textContaining('Sg 1.2'), findsOneWidget);
  });

  testWidgets('çok uzun mermi Sg < 1: kararsız uyarısı', (tester) async {
    await shotWith(tester, lengthMm: '45');
    expect(find.byKey(unstable), findsOneWidget);
    expect(find.byKey(marginal), findsNothing);
  });

  testWidgets('kayıtlı mühimmat uzunluğu Sg\'ye girmez, yalnız Pro kutusu', (
    tester,
  ) async {
    // Owner, 2026-10-13 23:32: the length comes only from Pro > Mermi
    // uzunluğu; a length saved with the ammunition (45 mm, Sg < 1 if it
    // were used) changes nothing while the Pro box is empty.
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([
        _rifle,
        {..._ammo, 'lengthMm': 45},
      ]),
    );
    await shotWith(tester);
    expect(find.byKey(unstable), findsNothing);
    expect(find.byKey(marginal), findsNothing);
    await shotWith(tester, lengthMm: '45');
    expect(find.byKey(unstable), findsOneWidget);
  });

  testWidgets('uzak hedefte transonik uyarısı, yakında yok', (tester) async {
    await shotWith(tester, rangeM: '100');
    expect(find.byKey(transonic), findsNothing);
    await shotWith(tester, rangeM: '1000');
    expect(find.byKey(transonic), findsOneWidget);
  });
}
