import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';

const _profile = RifleProfile(
  id: 'p-drag',
  name: 'Sürtünmeli',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-drag',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Map<String, dynamic> _ammo({String? bcModel = 'G1', double bc = 0.04}) => {
  'id': 'c-drag',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 pellet',
  'caliberMm': 6.35,
  'grain': 25.4,
  'ammoType': 'pellet',
  'bc': bc,
  'bcModel': bcModel,
};

Future<void> _pump(
  WidgetTester tester, {
  BallisticsView view = BallisticsView.all,
}) async {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BallisticsScreen(profile: _profile, view: view),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  void install([Map<String, dynamic>? ammo]) =>
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([ammo ?? _ammo()]),
      );

  testWidgets('BC + G1 switches the table to the drag solver', (tester) async {
    install();
    await _pump(tester);
    expect(find.textContaining('Sürtünmeli hesap: G1 BC 0.04'), findsOneWidget);

    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Rüzgâr mrad'), findsOneWidget);
    expect(find.text('Mesafe enerjisi J'), findsOneWidget);
    expect(find.textContaining('Vakum düşüşü'), findsNothing);
    expect(find.textContaining('Namlu enerjisi'), findsNothing);
  });

  testWidgets('a BC without G1/G7 is not used: vacuum baseline stays', (
    tester,
  ) async {
    install(_ammo(bcModel: null));
    await _pump(tester);
    expect(
      find.textContaining('Bu mühimmat için doğrulanmış BC/model yok'),
      findsOneWidget,
    );
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Rüzgâr mrad'), findsNothing);
    expect(find.text('Vakum düşüşü cm*'), findsOneWidget);
  });

  testWidgets('editing the grain drops the BC (it belongs to one mass)', (
    tester,
  ) async {
    install();
    await _pump(tester);
    await tester.enterText(find.byKey(BallisticsFieldKeys.grain), '30');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Grain değiştirildiği için BC kullanılmıyor'),
      findsOneWidget,
    );
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Rüzgâr mrad'), findsNothing);
  });

  testWidgets('muzzle Mach >= 0.8 shows the transonic warning', (tester) async {
    install();
    await _pump(tester);
    await tester.enterText(find.byKey(BallisticsFieldKeys.velocity), '300');
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mach 0,8'), findsOneWidget);
  });

  testWidgets('a normal pellet speed shows no Mach warning', (tester) async {
    install();
    await _pump(tester);
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('güvenilir değil'), findsNothing);
  });

  testWidgets('a BC outside the airgun range is flagged', (tester) async {
    install(_ammo(bc: 0.6));
    await _pump(tester);
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('alışılmadık'), findsOneWidget);
  });

  testWidgets('ranges the pellet cannot reach are listed, not invented', (
    tester,
  ) async {
    install();
    await _pump(tester);
    await tester.enterText(
      find.byKey(BallisticsFieldKeys.ranges),
      '25, 100, 3000',
    );
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(
      find.textContaining('ulaşamıyor, tabloda yok: 3000 m'),
      findsOneWidget,
    );
  });

  testWidgets('shot view shows the wind card instead of the lock', (
    tester,
  ) async {
    install();
    await _pump(tester, view: BallisticsView.shot);
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('KİLİTLİ'), findsNothing);
    expect(find.text('Rüzgâr 0 girildi'), findsOneWidget);
    expect(find.textContaining('1 mil ='), findsOneWidget);
  });
}
