// Profiller → Yedekle / Geri yükle (owner, 2026-10-12).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/manual_catalog_store.dart';
import 'package:sniper_turk/services/profile_backup.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _one = RifleProfile(
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

const _two = RifleProfile(
  id: 'p2',
  name: 'İki',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 180,
);

Map<String, dynamic> _ammo(String id) => {
  'id': id,
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'JSB',
  'model': 'Exact King',
  'caliberMm': 6.35,
  'grain': 25.39,
  'ammoType': 'pellet',
  'bc': 0.033,
  'bcModel': 'G1',
};

Future<MemoryProfileStore> _storeWith(List<RifleProfile> profiles) async {
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  return store;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('file', () {
    test('round-trips profiles and catalog entries', () {
      final text = ProfileBackup.encode(
        ProfileBackupContents(
          profiles: const [_one, _two],
          catalog: [_ammo('c1')],
        ),
        createdAt: DateTime.utc(2026, 10, 12),
      );
      final map = jsonDecode(text) as Map<String, dynamic>;
      expect(map['format'], ProfileBackup.format);
      expect(map['version'], 1);
      final back = ProfileBackup.decode(text);
      expect(back.profiles.map((p) => p.id), ['p1', 'p2']);
      expect(back.profiles.first.muzzleVelocityMps, 270);
      expect(back.catalog.single['id'], 'c1');
    });

    test('file name carries the date', () {
      expect(
        ProfileBackup.fileName(DateTime(2026, 3, 7)),
        'sniper-turk-yedek-2026-03-07.json',
      );
    });

    test('other files are refused with a clear message', () {
      for (final text in ['not json', '[]', '{"format":"x","version":1}']) {
        expect(
          () => ProfileBackup.decode(text),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              ProfileBackup.notABackup,
            ),
          ),
        );
      }
    });

    test('a newer backup version is refused', () {
      final text = jsonEncode({
        'format': ProfileBackup.format,
        'version': 99,
        'profiles': {'schemaVersion': 1, 'profiles': []},
      });
      expect(
        () => ProfileBackup.decode(text),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('daha yeni'),
          ),
        ),
      );
    });
  });

  group('restore', () {
    test('adds and updates, deletes nothing', () async {
      final store = await _storeWith(const [_one]);
      final catalog = ManualCatalogStore();
      await catalog.upsert(_ammo('c0'));
      const changedOne = RifleProfile(
        id: 'p1',
        name: 'Bir',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 275,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      );
      final r = await ProfileBackup.restore(
        ProfileBackupContents(
          profiles: const [changedOne, _two],
          catalog: [
            _ammo('c1'),
            {'id': 'broken', 'kind': 'nothing'},
          ],
        ),
        store,
        catalog,
      );
      expect(r.profiles, 2);
      expect(r.catalog, 1);
      expect(r.skipped, 1);
      final all = await store.all();
      expect(all.map((p) => p.id).toSet(), {'p1', 'p2'});
      expect(all.firstWhere((p) => p.id == 'p1').muzzleVelocityMps, 275);
      expect((await catalog.all()).map((e) => e['id']).toSet(), {'c0', 'c1'});
    });
  });

  group('Profiller page', () {
    testWidgets('Yedekle hands the file to the share sheet', (tester) async {
      final store = await _storeWith(const [_one, _two]);
      String? sharedName;
      String? sharedText;
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(
            store: store,
            catalogStore: ManualCatalogStore(),
            shareBackup: (name, text, origin) async {
              sharedName = name;
              sharedText = text;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Yedekle'));
      await tester.tap(find.text('Yedekle'));
      await tester.pumpAndSettle();
      expect(sharedName, startsWith('sniper-turk-yedek-'));
      expect(sharedName, endsWith('.json'));
      expect(ProfileBackup.decode(sharedText!).profiles, hasLength(2));
    });

    testWidgets('Geri yükle asks first, then adds the profiles', (
      tester,
    ) async {
      final store = await _storeWith(const [_one]);
      final backup = ProfileBackup.encode(
        const ProfileBackupContents(profiles: [_two], catalog: []),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(
            store: store,
            catalogStore: ManualCatalogStore(),
            pickBackup: () async => backup,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Geri yükle'));
      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();
      expect(find.text('Yedek geri yüklensin mi?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
      await tester.pumpAndSettle();
      expect(await store.all(), hasLength(1));

      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Geri yükle'));
      await tester.pumpAndSettle();
      expect((await store.all()).map((p) => p.id).toSet(), {'p1', 'p2'});
      expect(find.text('1 profil geri yüklendi.'), findsOneWidget);
    });

    testWidgets('a wrong file changes nothing', (tester) async {
      final store = await _storeWith(const [_one]);
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: ProfilesScreen(
            store: store,
            catalogStore: ManualCatalogStore(),
            pickBackup: () async => '{"hello": 1}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Geri yükle'));
      await tester.tap(find.text('Geri yükle'));
      await tester.pumpAndSettle();
      expect(find.text(ProfileBackup.notABackup), findsOneWidget);
      expect(await store.all(), hasLength(1));
    });
  });
}
