// Profiller kartının gri ikinci satırı (owner, 2026-10-17 18:59 "aç
// görevi"): "Tüfek markası, kalibre adı", e.g. "Accuracy International,
// .308 Win"; no sıfır, fps or BC; always one line, the end cut with "…".
// See docs/reports/profil_kart_marka_kalibre.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

/// A list rifle whose model does not name its cartridge: the name comes
/// from the list variant (".308 Win"), as in the profile editor.
const _atx = Rifle(
  id: 'test_atx_le',
  brand: 'Accuracy International',
  model: 'AT-X LE',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  twistRateIn: 10,
  userEntered: true,
);

/// A typed rifle with a caliber that is in no list.
const _typed = Rifle(
  id: 'test_typed',
  brand: 'Accuracy International',
  model: 'Özel Namlu',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  userEntered: true,
);

/// A typed rifle whose brand is blank (saved before Marka was required).
const _noBrand = Rifle(
  id: 'test_no_brand',
  brand: '  ',
  model: 'Eski',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.82,
  userEntered: true,
);

RifleProfile _profile(String id, String rifleId) => RifleProfile(
  id: id,
  name: 'Profil $id',
  rifleId: rifleId,
  ammunitionId: 'no-such-ammo',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 792.48,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      const UserCatalog(rifles: [_atx, _typed, _noBrand]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('profileListSummary: marka, kalibre adı', () {
    test('catalog rifle: brand and its cartridge name', () {
      expect(
        profileListSummary(_profile('a', 'ata-turqua-308')),
        'ATA Arms, .308 Win',
      );
    });

    test('list rifle without the cartridge in its model: the list name', () {
      expect(
        profileListSummary(_profile('b', 'test_atx_le')),
        'Accuracy International, .308 Win',
      );
    });

    test('unlisted caliber: the mm text with a comma', () {
      expect(
        profileListSummary(_profile('c', 'test_typed')),
        'Accuracy International, 7,82 mm',
      );
    });

    test('PCP rifle: no cartridge name, the mm text', () {
      expect(
        profileListSummary(_profile('d', 'hatsan-hercules-635')),
        'Hatsan, 6,35 mm',
      );
    });

    test('blank brand: only the caliber, no leading comma', () {
      expect(profileListSummary(_profile('e', 'test_no_brand')), '7,82 mm');
    });

    test('unknown rifle: no crash, nothing shown', () {
      final s = profileListSummary(_profile('f', 'no-such-rifle'));
      expect(s, '');
      expect(s.startsWith(','), isFalse);
    });

    test('no sıfır, fps or BC in the line', () {
      for (final id in ['ata-turqua-308', 'test_atx_le', 'test_typed']) {
        final s = profileListSummary(_profile('g', id));
        expect(s, isNot(contains('sıfır')), reason: id);
        expect(s, isNot(contains('fps')), reason: id);
        expect(s, isNot(contains('BC')), reason: id);
      }
    });
  });

  group('one line', () {
    Future<double> pumpList(WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 2400) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemoryProfileStore();
      await store.save(_profile('a', 'test_atx_le'));
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.25)),
            child: child!,
          ),
          home: Scaffold(
            body: ProfilesScreen(
              embedded: true,
              store: store,
              activeProfileId: 'a',
              onActivate: (_) async {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(const Key('profile-row-summary'))).width;
    }

    testWidgets('the card line has maxLines 1 and an ellipsis', (tester) async {
      await pumpList(tester);
      expect(tester.takeException(), isNull);
      final t = tester.widget<Text>(
        find.byKey(const Key('profile-row-summary')),
      );
      expect(t.data, 'Accuracy International, .308 Win');
      expect(t.maxLines, 1);
      expect(t.overflow, TextOverflow.ellipsis);
      expect(t.textAlign, TextAlign.start);
    });

    testWidgets('320 pt, ×1.25: the longest names are cut with "…" on one '
        'line, no overflow', (tester) async {
      // The width the line gets in a real card at 320 pt and ×1.25.
      final width = await pumpList(tester);
      const long = 'Accuracy International, .338-378 Weatherby Mag';
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: const ProfileRowSummary(long),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final f = find.byKey(const Key('profile-row-summary'));
      expect(tester.getSize(f).width, lessThanOrEqualTo(width + 0.5));
      TextPainter painter(String text) => TextPainter(
        text: TextSpan(text: text, style: tester.widget<Text>(f).style),
        textDirection: TextDirection.ltr,
        textScaler: const TextScaler.linear(1.25),
      )..layout();
      // The whole text does not fit, so it is cut…
      expect(painter(long).width, greaterThan(width));
      // …on one line: the same height as a one-word line.
      expect(tester.getSize(f).height, closeTo(painter('A').height, 0.5));
    });
  });
}
