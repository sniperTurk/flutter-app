import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<MemoryProfileStore> _storeWith(List<RifleProfile> profiles) async {
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  return store;
}

Future<void> _pumpShell(
  WidgetTester tester,
  ProfileStore store,
  ActiveProfileStore active,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(profileStore: store, activeProfileStore: active),
    ),
  );
  await tester.pumpAndSettle();
}

/// The app opens on Profil; tests of the ballistic workspace switch to Atış.
Future<void> _openShot(WidgetTester tester) async {
  await tester.tap(find.text('Atış'));
  await tester.pumpAndSettle();
}

/// The DOPE table is the second mode of the Atış tab.
Future<void> _openTable(WidgetTester tester) async {
  await _openShot(tester);
  await tester.tap(find.byKey(const Key('shot-mode-table')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shell shows the Menzil bar and the four tabs', (tester) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );

    // Profil shows no Menzil wordmark; the other tabs do.
    expect(find.text('Menzil'), findsNothing);
    for (final tab in const ['Profil', 'Hava Durumu', 'Atış', 'Araçlar']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    // Tablo is no longer a bottom tab: it is a mode of Atış.
    expect(find.text('Tablo'), findsNothing);
    expect(find.text('Ortam'), findsNothing);
    // Profil is the start tab and the leftmost one.
    expect(find.text('Aktif profil'), findsOneWidget);
    expect(find.text('Hesapla'), findsNothing);
    // Left to right: Profil, Hava Durumu, Atış, Araçlar.
    var previousX = double.negativeInfinity;
    for (final tab in const ['Profil', 'Hava Durumu', 'Atış', 'Araçlar']) {
      final x = tester.getCenter(find.text(tab)).dx;
      expect(x, greaterThan(previousX), reason: tab);
      previousX = x;
    }
    // Atış opens on the single shot and offers the range dial.
    await _openShot(tester);
    expect(find.text('Menzil'), findsOneWidget);
    expect(find.byKey(const Key('shot-mode-shot')), findsOneWidget);
    expect(find.byKey(const Key('shot-mode-table')), findsOneWidget);
    expect(find.text('Hesapla'), findsOneWidget);
    expect(find.bySemanticsLabel('5 artır'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Atış, Tablo and Hava Durumu share one workspace state', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );

    // Edit the conditions on Hava Durumu, then solve from Atış > Tablo.
    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('environment-open-weather')),
      findsOneWidget,
      reason: 'live service data is one tap away before shooting',
    );
    await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), '30');

    await _openTable(tester);
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    // Back on Hava Durumu the edited value survived the tab switches, and
    // the atmosphere result of the same solve is shown.
    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    // Values that come from Profil are shown but locked here.
    await tester.ensureVisible(find.text('Atış girdileri'));
    await tester.tap(find.text('Atış girdileri'));
    await tester.pumpAndSettle();
    for (final key in [
      BallisticsFieldKeys.velocity,
      BallisticsFieldKeys.grain,
      BallisticsFieldKeys.zero,
      BallisticsFieldKeys.sight,
    ]) {
      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
      expect(field.enabled, isFalse, reason: '$key');
    }
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.temperature),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '30');
    expect(find.textContaining('Hava yoğunluğu:'), findsOneWidget);

    // Atış remembers the table mode; switching to the single shot uses the
    // same validated solve: no "calculate first" prompt.
    await tester.tap(find.text('Atış'));
    await tester.pumpAndSettle();
    expect(find.text('DOPE oluştur'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shot-mode-shot')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Değerleri görmek için hesaplayın'),
      findsNothing,
    );
    expect(find.text('Atış görünümü'), findsOneWidget);
    // V354: elevation is computed from the vacuum drop (valid trigonometry);
    // only wind stays locked, since a vacuum model has no aerodynamic
    // coupling to produce a real wind value.
    expect(find.text('KİLİTLİ'), findsNWidgets(1));
  });

  testWidgets('range dial steps change the evaluated distance', (tester) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );
    await _openShot(tester);
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();

    expect(find.text('100'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 artır'));
    await tester.pumpAndSettle();
    expect(find.text('105'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('1 azalt'));
    await tester.pumpAndSettle();
    expect(find.text('104'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'shot view shows a vacuum elevation correction but keeps wind locked',
    (tester) async {
      await _pumpShell(
        tester,
        await _storeWith([_profile]),
        MemoryActiveProfileStore(),
      );
      await _openShot(tester);
      await tester.tap(find.text('Hesapla'));
      await tester.pumpAndSettle();

      // V354: elevation shows a real MOA/mrad value and a click count on the
      // profile's own scope; wind has no aerodynamic coupling in the vacuum
      // model, so it alone stays locked.
      expect(find.text('KİLİTLİ'), findsNWidgets(1));
      expect(find.text('Rüzgâr'), findsOneWidget);
      expect(find.textContaining('MOA'), findsWidgets);
      expect(find.textContaining('mrad'), findsWidgets);
      expect(find.textContaining('klik'), findsWidgets);
      expect(
        find.textContaining('gerçek atış için kullanmayın'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Araçlar lists the V1 tools plus the V1.1 Vuruş Olasılığı tool', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );
    await tester.tap(find.text('Araçlar'));
    await tester.pumpAndSettle();

    // Chronograph, Sight Height, Compass and Level are back in V1 scope
    // (M1); Vuruş Olasılığı (hit probability) is a V1.1 standalone stats
    // tool. Qwen/cloud wording must stay absent from the hub either way.
    for (final key in const [
      'chronograph',
      'sight-height',
      'compass',
      'level',
      'weather',
      'hit-probability',
      'calculators',
      'catalog',
    ]) {
      expect(find.byKey(Key('tool-$key')), findsOneWidget, reason: key);
    }
    expect(find.textContaining('Qwen'), findsNothing);
    // V380: Ayarlar was removed (metric only).
    expect(find.byKey(const Key('tool-settings')), findsNothing);
  });

  testWidgets('Profil tab activates, copies and confirms before deleting', (
    tester,
  ) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    const second = RifleProfile(
      id: 'p2',
      name: 'İki',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 280,
      zeroRangeM: 30,
      sightHeightMm: 60,
      pressureBar: 200,
    );
    final store = await _storeWith([_profile, second]);
    final active = MemoryActiveProfileStore();
    await _pumpShell(tester, store, active);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Aktif profil'), findsOneWidget);

    // Tapping a row makes it active (persisted through the shell). The list
    // sits below the active-profile summary.
    await tester.ensureVisible(find.bySemanticsLabel('Profil İki'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Profil İki'));
    await tester.pumpAndSettle();
    expect(active.value, 'p2');

    await tester.ensureVisible(find.text('Kopyala'));
    await tester.tap(find.text('Kopyala'));
    await tester.pumpAndSettle();
    expect((await store.all()).map((p) => p.name), contains('İki (kopya)'));
    // Let the "oluşturuldu" snackbar close; it can cover the buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sil'));
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Profili sil?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect((await store.all()).length, 3, reason: 'cancel must not delete');
    semantics.dispose();
  });

  testWidgets('profile editor saves a typed-in rifle through the stores', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(body: ProfilesScreen(embedded: true, store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz kayıtlı profil yok'), findsOneWidget);

    await tester.tap(find.text('Yeni profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
    VoidCallback? save() => tester
        .widget<MenzilPrimaryButton>(
          find.widgetWithText(MenzilPrimaryButton, 'Kaydet'),
        )
        .onPressed;
    expect(
      save(),
      isNull,
      reason: 'the rifle must be typed in; no catalog rifle is preselected',
    );
    await fillRifleForm(tester);
    expect(save(), isNull, reason: 'the scope must be typed in as well');
    await fillScopeForm(tester);
    expect(save(), isNull, reason: 'the ammunition must be typed in as well');
    await fillAmmoForm(tester);
    expect(
      save(),
      isNull,
      reason: 'new profiles start empty: velocity, zero, sight are required',
    );
    expect(find.textContaining('Atış değerleri: Çıkış hızı'), findsOneWidget);
    await fillShotValues(tester);
    expect(
      find.text('Dürbün: Test Optik 6-24x56 FFP'),
      findsOneWidget,
      reason: 'separate fields are shown as one designation line',
    );
    expect(save(), isNotNull, reason: 'complete rifle, ammo and scope data');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Profil Oluştur'),
      findsNothing,
      reason: 'editor should have closed after saving',
    );

    final saved = (await store.all()).single;
    expect(saved.name, 'Yeni Profil');
    // 900 fps entered on Profil reaches the solver as 274.32 m/s.
    expect(saved.muzzleVelocityMps, closeTo(274.32, 1e-9));
    expect(saved.zeroRangeM, 25);
    expect(saved.sightHeightMm, 60);
    expect(saved.pressureBar, 120, reason: 'PCP pressure = regulator');
    expect(find.text('Yeni Profil'), findsOneWidget);
    // The rifle became a personal record with every typed value.
    final rifle = CatalogRepository.allRifles.singleWhere(
      (r) => r.id == saved.rifleId,
    );
    expect(rifle.userEntered, isTrue);
    expect(rifle.brand, 'Test Marka');
    expect(rifle.model, 'Test Model');
    expect(rifle.caliberMm, 6.35);
    expect(rifle.barrelLengthMm, 600);
    expect(rifle.twistDirection, TwistDirection.right);
    expect(rifle.twistRateIn, 16);
    expect(rifle.regulatorBar, 120);
    final scope = CatalogRepository.allScopes.singleWhere(
      (o) => o.id == saved.scopeId,
    );
    expect(scope.userEntered, isTrue);
    expect(scope.brand, 'Test Optik');
    expect(scope.model, '6-24x56 FFP');
    expect(scope.minMagnification, 6);
    expect(scope.maxMagnification, 24);
    expect(scope.objectiveDiameterMm, 56);
    expect(scope.firstFocalPlane, isTrue);
    expect(scope.clickValue, 0.1);
    expect(scope.clickUnit, AngularUnit.mrad);
    final ammo = CatalogRepository.allAmmunition.singleWhere(
      (a) => a.id == saved.ammunitionId,
    );
    expect(ammo.userEntered, isTrue);
    expect(ammo.caliberMm, 6.35, reason: 'caliber follows the rifle');
    expect(ammo.grain, 33.95);
    expect(ammo.type, AmmunitionType.slug);
    expect(ammo.ballisticCoefficient, 0.08);
    expect(ammo.ballisticModel, BallisticModel.g1);
  });

  testWidgets('MenzilCard hosts ListTile children without ink assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: MenzilCard(
            child: SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Balistik birimleri'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Balistik birimleri'), findsOneWidget);
  });
}
