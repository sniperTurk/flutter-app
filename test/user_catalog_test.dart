import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/user_catalog_loader.dart';
import 'package:sniper_turk/services/user_catalog_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

class _Killed extends Error {}

/// Simulates the process dying while the copy is being written.
class _KillOnUpsert extends ManualCatalogStore {
  @override
  Future<void> upsert(Map<String, dynamic> entry) => throw _Killed();
}

/// A manual catalog whose undo (remove) fails.
class _RemoveFails extends ManualCatalogStore {
  @override
  Future<void> discardUnconfirmedCopy(String id) =>
      throw StateError('undo failed');
}

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_1',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Atölye',
  'model': 'Uzun Namlu',
  'caliberMm': 5.5,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 16,
  'regulatorBar': 120,
  'sourceName': 'Kullanıcı girdisi',
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_1',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Kendi',
  'model': 'Diabolo',
  'caliberMm': 5.5,
  'grain': 18.1,
  'ammoType': 'pellet',
  'bc': 0.03,
  'bcModel': 'g1',
  'sourceName': 'Kullanıcı girdisi',
};
const _firearmAmmo = <String, dynamic>{
  'id': 'manual_ammo_fa',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Kendi',
  'model': 'Ateşli',
  'caliberMm': 5.5,
  'grain': 55,
  'ammoType': 'bullet',
};
const _scope = <String, dynamic>{
  'id': 'manual_scope_1',
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
const _legacyScopeWithoutUnit = <String, dynamic>{
  'id': 'manual_scope_old',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'Eski',
  'model': 'Dürbün',
  'objectiveMm': 40,
  'click': 0.25,
};
const _incompleteCustom = <String, dynamic>{
  'id': 'manual_custom_1',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': '',
  'model': 'Ev yapımı slug',
  'caliberMm': 5.5,
  'ammoType': 'slug',
};

const _personalProfile = RifleProfile(
  id: 'personal',
  name: 'Kişisel Profil',
  rifleId: 'manual_rifle_1',
  ammunitionId: 'manual_ammo_1',
  scopeId: 'manual_scope_1',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 190,
);

class _GatedLoader extends UserCatalogLoader {
  final Completer<void> gate = Completer<void>();
  final List<Map<String, dynamic>> entries;
  _GatedLoader(this.entries);

  @override
  Future<UserCatalogLoadResult> load() async {
    await gate.future;
    final catalog = UserCatalog.fromManualEntries(entries);
    CatalogRepository.installUserCatalog(catalog);
    return UserCatalogLoadResult(catalog: catalog);
  }
}

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('UserCatalog conversion', () {
    test('complete records become selectable, personally labelled records', () {
      final catalog = UserCatalog.fromManualEntries([_rifle, _ammo, _scope]);
      expect(catalog.blocked, isEmpty);
      expect(catalog.rifles.single.userEntered, isTrue);
      expect(catalog.ammunition.single.userEntered, isTrue);
      expect(catalog.scopes.single.userEntered, isTrue);
      for (final source in [
        catalog.rifles.single.sourceName,
        catalog.ammunition.single.sourceName,
        catalog.scopes.single.sourceName,
      ]) {
        expect(source, userCatalogSourceName);
      }
      expect(catalog.scopes.single.clickUnit, AngularUnit.mrad);
    });

    test('incomplete custom ammunition and unit-less scopes are blocked '
        'with an explicit reason, never completed with a guess', () {
      final catalog = UserCatalog.fromManualEntries([
        _incompleteCustom,
        _legacyScopeWithoutUnit,
      ]);
      expect(catalog.ammunition, isEmpty);
      expect(catalog.scopes, isEmpty);
      final reasons = {for (final b in catalog.blocked) b.id: b.reason};
      expect(reasons['manual_custom_1'], contains('ağırlık (grain)'));
      expect(reasons['manual_scope_old'], contains('klik birimi'));
    });

    test('a personal id that collides with a built-in record is blocked', () {
      final builtIn = CatalogRepository.rifles.first;
      final catalog = UserCatalog.fromManualEntries([
        {..._rifle, 'id': builtIn.id},
      ]);
      expect(catalog.rifles, isEmpty);
      expect(catalog.blocked.single.reason, contains('çakışıyor'));
    });

    test('BC is attached only together with an explicit G1/G7 model', () {
      final catalog = UserCatalog.fromManualEntries([
        {
          ..._incompleteCustom,
          'id': 'c-g7',
          'grain': 25.0,
          'bc': 0.05,
          'bcModel': 'g7',
        },
        {..._incompleteCustom, 'id': 'c-x', 'grain': 25.0, 'bc': 0.05},
      ]);
      final byId = {for (final a in catalog.ammunition) a.id: a};
      expect(byId['c-g7']!.ballisticModel, BallisticModel.g7);
      expect(byId['c-g7']!.ballisticCoefficient, 0.05);
      expect(byId['c-x']!.ballisticCoefficient, isNull);
      expect(byId['c-x']!.brand, 'Özel yapım');
    });
  });

  group('profile resolution and platform/caliber filters', () {
    test(
      'a profile built from personal records resolves only once installed',
      () {
        expect(
          const ProfileCatalogIntegrity().resolve(_personalProfile),
          isNull,
        );
        CatalogRepository.installUserCatalog(
          UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
        );
        final resolution = const ProfileCatalogIntegrity().resolve(
          _personalProfile,
        );
        expect(resolution, isNotNull);
        expect(resolution!.ammunition.grain, 18.1);
      },
    );

    test('personal firearm ammunition never pairs with a PCP rifle', () {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_rifle, _firearmAmmo, _scope]),
      );
      const repo = CatalogRepository();
      final pcp = repo.ammunitionFor(WeaponPlatform.pcp, caliberMm: 5.5);
      expect(pcp.map((a) => a.id), isNot(contains('manual_ammo_fa')));
      expect(
        const ProfileCatalogIntegrity().resolve(
          const RifleProfile(
            id: 'x',
            name: 'x',
            rifleId: 'manual_rifle_1',
            ammunitionId: 'manual_ammo_fa',
            scopeId: 'manual_scope_1',
            muzzleVelocityMps: 280,
            zeroRangeM: 30,
            sightHeightMm: 55,
            pressureBar: 190,
          ),
        ),
        isNull,
      );
      // The catalog browser lists personal records in their own section.
      expect(
        repo.riflesFor(WeaponPlatform.pcp, includeUser: false).map((r) => r.id),
        isNot(contains('manual_rifle_1')),
      );
      expect(
        repo.riflesFor(WeaponPlatform.pcp).map((r) => r.id),
        contains('manual_rifle_1'),
      );
    });
  });

  group('UserCatalogLoader migration', () {
    test('copies legacy records, keeps the legacy key and existing manual '
        'records, and is idempotent', () async {
      final legacy = jsonEncode([
        {
          'id': 'user-1',
          'kind': 'rifle',
          'platform': 'pcp',
          'brand': 'Eski',
          'model': 'Tüfek',
          'caliberMm': 5.5,
        },
        {
          'id': 'user-2',
          'kind': 'scope',
          'brand': 'Eski',
          'model': 'Dürbün',
          'objectiveDiameterMm': 50,
          'clickValue': 0.25,
          'clickUnit': 'moa',
        },
      ]);
      SharedPreferences.setMockInitialValues({
        UserCatalogStore.key: legacy,
        ManualCatalogStore.key: jsonEncode([_ammo]),
      });
      final loader = UserCatalogLoader();

      final first = await loader.load();
      expect(first.migrated, 2);
      expect(first.warning, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UserCatalogStore.key), legacy);
      final ids = (await ManualCatalogStore().all()).map((e) => e['id']);
      expect(ids, containsAll(<String>['manual_ammo_1', 'user-1', 'user-2']));
      expect(
        CatalogRepository.userCatalog.scopes.single.clickUnit,
        AngularUnit.moa,
      );

      final second = await loader.load();
      expect(second.migrated, 0);
      expect(await ManualCatalogStore().all(), hasLength(3));

      // A migrated record the user deletes is not resurrected.
      await ManualCatalogStore().remove('user-1');
      final third = await loader.load();
      expect(third.migrated, 0);
      expect(
        (await ManualCatalogStore().all()).map((e) => e['id']),
        isNot(contains('user-1')),
      );
    });
  });

  group('UserCatalogLoader ledger write failure', () {
    test('a failed ledger write copies nothing, so a later deletion can never '
        'be undone by migration', () async {
      final legacy = jsonEncode([
        {
          'id': 'user-1',
          'kind': 'rifle',
          'platform': 'pcp',
          'brand': 'Eski',
          'model': 'Tüfek',
          'caliberMm': 5.5,
        },
      ]);
      SharedPreferences.setMockInitialValues({UserCatalogStore.key: legacy});
      final failing = UserCatalogLoader(
        writeLedger: (prefs, ids) async => false,
      );

      final first = await failing.load();
      expect(first.migrated, 0);
      expect(first.warning, contains('taşınamadı'));
      expect(first.warning, contains('silinmedi'));
      expect(await ManualCatalogStore().all(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UserCatalogStore.key), legacy);
      expect(prefs.getStringList(UserCatalogLoader.migratedIdsKey), isNull);

      // Once the ledger works again the record is migrated normally.
      final healthy = await UserCatalogLoader().load();
      expect(healthy.migrated, 1);
      expect(
        (await ManualCatalogStore().all()).map((e) => e['id']),
        contains('user-1'),
      );
      await ManualCatalogStore().remove('user-1');
      expect((await UserCatalogLoader().load()).migrated, 0);
      expect(await ManualCatalogStore().all(), isEmpty);
    });

    test('an already-present record whose ledger write fails is reported, '
        'not silently trusted', () async {
      final legacy = jsonEncode([
        {
          'id': 'manual_rifle_1',
          'kind': 'rifle',
          'platform': 'pcp',
          'brand': 'Eski',
          'model': 'Tüfek',
          'caliberMm': 5.5,
        },
      ]);
      SharedPreferences.setMockInitialValues({
        UserCatalogStore.key: legacy,
        ManualCatalogStore.key: jsonEncode([_rifle]),
      });
      final result = await UserCatalogLoader(
        writeLedger: (prefs, ids) async => false,
      ).load();
      expect(result.warning, contains('taşınamadı'));
      expect(await ManualCatalogStore().all(), hasLength(1));
    });
  });

  group('UserCatalogLoader interruption safety', () {
    final legacy = jsonEncode([
      {
        'id': 'user-1',
        'kind': 'rifle',
        'platform': 'pcp',
        'brand': 'Eski',
        'model': 'Tüfek',
        'caliberMm': 5.5,
      },
    ]);

    Future<bool> realWrite(SharedPreferences prefs, List<String> ids) =>
        prefs.setStringList(UserCatalogLoader.migratedIdsKey, ids);

    // Real write for the first [ok] calls, then every write fails.
    Future<bool> Function(SharedPreferences, List<String>) failAfter(int ok) {
      var calls = 0;
      return (prefs, ids) async => ++calls <= ok && await realWrite(prefs, ids);
    }

    test('killed after the intent was written but before the copy: the record '
        'is NOT treated as migrated and migrates on the next start', () async {
      SharedPreferences.setMockInitialValues({UserCatalogStore.key: legacy});
      final killed = UserCatalogLoader(
        manual: _KillOnUpsert(),
        writeLedger: failAfter(1), // intent persisted, rollback write fails
      );
      final first = await killed.load();
      expect(first.migrated, 0);
      expect(await ManualCatalogStore().all(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(UserCatalogLoader.migratedIdsKey), [
        'pending:user-1',
      ]);
      expect(prefs.getString(UserCatalogStore.key), legacy);

      final restart = await UserCatalogLoader().load();
      expect(restart.migrated, 1, reason: 'still migratable after the kill');
      expect(
        (await ManualCatalogStore().all()).map((e) => e['id']),
        contains('user-1'),
      );
      // Now confirmed: a later deletion is respected.
      await ManualCatalogStore().remove('user-1');
      expect((await UserCatalogLoader().load()).migrated, 0);
      expect(await ManualCatalogStore().all(), isEmpty);
    });

    test('confirmation write fails: the copy is undone, so the record stays '
        'migratable and a later deletion is still respected', () async {
      SharedPreferences.setMockInitialValues({UserCatalogStore.key: legacy});
      final first = await UserCatalogLoader(writeLedger: failAfter(1)).load();
      expect(first.migrated, 0);
      expect(first.warning, contains('taşınamadı'));
      expect(await ManualCatalogStore().all(), isEmpty, reason: 'undone');

      final second = await UserCatalogLoader().load();
      expect(second.migrated, 1);
      await ManualCatalogStore().remove('user-1');
      expect((await UserCatalogLoader().load()).migrated, 0);
      expect(await ManualCatalogStore().all(), isEmpty);
    });

    test('confirmation AND undo both fail: restart confirms the present '
        'record without duplicating or losing it', () async {
      SharedPreferences.setMockInitialValues({UserCatalogStore.key: legacy});
      final first = await UserCatalogLoader(
        manual: _RemoveFails(),
        writeLedger: failAfter(1),
      ).load();
      expect(first.migrated, 0);
      expect(first.warning, contains('taşınamadı'));
      expect(await ManualCatalogStore().all(), hasLength(1));

      final restart = await UserCatalogLoader().load();
      expect(restart.warning, isNull);
      expect(await ManualCatalogStore().all(), hasLength(1));
      await ManualCatalogStore().remove('user-1');
      expect((await UserCatalogLoader().load()).migrated, 0);
      expect(await ManualCatalogStore().all(), isEmpty);
    });

    test('user deletes the unconfirmed copy in the SAME session, then the app '
        'restarts: the deletion is preserved (no resurrection)', () async {
      SharedPreferences.setMockInitialValues({UserCatalogStore.key: legacy});
      final first = await UserCatalogLoader(
        manual: _RemoveFails(),
        writeLedger: failAfter(1), // pending stored; confirm + undo fail
      ).load();
      expect(first.migrated, 0);
      expect(await ManualCatalogStore().all(), hasLength(1));

      await ManualCatalogStore().remove('user-1'); // the user's decision
      expect(await ManualCatalogStore().all(), isEmpty);

      final restart = await UserCatalogLoader().load();
      expect(restart.migrated, 0);
      expect(restart.warning, isNull);
      expect(await ManualCatalogStore().all(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(UserCatalogStore.key),
        legacy,
        reason: 'legacy kept',
      );
    });

    test(
      'deletion with a ledger that never works is still preserved',
      () async {
        SharedPreferences.setMockInitialValues({
          UserCatalogStore.key: legacy,
          ManualCatalogStore.key: jsonEncode([
            {
              'id': 'user-1',
              'kind': 'rifle',
              'platform': 'pcp',
              'brand': 'Eski',
              'model': 'Tüfek',
              'caliberMm': 5.5,
              'sourceName': 'Kullanıcı girdisi',
            },
          ]),
        });
        await ManualCatalogStore().remove('user-1');
        final result = await UserCatalogLoader(
          writeLedger: (prefs, ids) async => false,
        ).load();
        expect(result.migrated, 0);
        expect(await ManualCatalogStore().all(), isEmpty);
      },
    );

    test(
      'a deletion that cannot be recorded is refused and deletes nothing',
      () async {
        SharedPreferences.setMockInitialValues({
          ManualCatalogStore.key: jsonEncode([_rifle]),
        });
        // Make the tombstone key unwritable: a String already lives there.
        final prefs = await SharedPreferences.getInstance();
        expect(
          await prefs.setString(ManualCatalogStore.removedKey, 'x'),
          isTrue,
        );
        await expectLater(
          ManualCatalogStore().remove('manual_rifle_1'),
          throwsA(anything),
        );
        expect(await ManualCatalogStore().all(), hasLength(1));
      },
    );
  });

  group('profile editor', () {
    Future<void> openEditor(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(_personalProfile);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_personalProfile.name).first);
      await tester.pumpAndSettle();
    }

    VoidCallback? updateAction(WidgetTester tester) => tester
        .widget<MenzilPrimaryButton>(
          find.widgetWithText(MenzilPrimaryButton, 'Güncelle'),
        )
        .onPressed;

    testWidgets('personal records prefill the typed-in editor forms', (
      tester,
    ) async {
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([
          _rifle,
          _ammo,
          _scope,
          _incompleteCustom,
        ]),
      );
      await openEditor(tester);
      String text(String key) => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(text('rifle-brand'), 'Atölye');
      expect(text('ammo-brand'), 'Kendi');
      expect(text('ammo-model'), 'Diabolo');
      expect(text('ammo-bc'), '0.03');
      expect(text('scope-brand'), 'Optik');
      expect(find.text('Dürbün: Optik 4-16x44 SFP'), findsOneWidget);
      // Complete personal records: the profile can be updated as is.
      expect(updateAction(tester), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without the personal catalog the profile fails closed', (
      tester,
    ) async {
      await openEditor(tester);
      expect(find.textContaining('sessizce seçilmedi'), findsOneWidget);
      expect(updateAction(tester), isNull);
    });
  });

  testWidgets('home waits for the personal catalog, then hands the personal '
      'profile to the solver', (tester) async {
    final profiles = MemoryProfileStore();
    await profiles.save(_personalProfile);
    final loader = _GatedLoader([_rifle, _ammo, _scope]);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profileStore: profiles,
          activeProfileStore: MemoryActiveProfileStore()..value = 'personal',
          userCatalogLoader: loader,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Kişisel katalog yükleniyor',
        // The app opens on Profil, so the workspace tab is offstage.
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('katalogla eşleşmiyor', skipOffstage: false),
      findsNothing,
    );
    expect(find.byType(BallisticsScreen, skipOffstage: false), findsNothing);

    loader.gate.complete();
    await tester.pumpAndSettle();
    final solver = tester.widget<BallisticsScreen>(
      find.byType(BallisticsScreen, skipOffstage: false),
    );
    expect(solver.profile?.id, 'personal');
  });
}
