// Profil summary (owner, 2026-10-17 06:08): no "Tüfek / Dürbün / Mühimmat
// bilgileri" titles above the three cards; each card's first row reads
// "Tüfek Marka/Model", "Dürbün Marka/Model", "Mühimmat Marka/Model".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_oe',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Hatsan',
  'model': 'Hercules',
  'caliberMm': 6.35,
  'barrelLengthMm': 800,
  'twistDirection': 'right',
  'twistRateIn': 6,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_oe',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Engin Sak',
  'model': '',
  'caliberMm': 6.35,
  'grain': 50,
  'ammoType': 'pellet',
  'bc': 0.165,
  'bcModel': 'g1',
};
const _scope = <String, dynamic>{
  'id': 'manual_scope_oe',
  'kind': 'scope',
  'platform': 'pcp',
  'brand': 'GaziSniper',
  'model': '6-36x56 FFP',
  'objectiveMm': 56,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 6,
  'maxMag': 36,
  'elevationRangeMrad': 26,
};

const _profile = RifleProfile(
  id: 'p-oe',
  name: 'Hercules',
  rifleId: 'manual_rifle_oe',
  ammunitionId: 'manual_ammo_oe',
  scopeId: 'manual_scope_oe',
  muzzleVelocityMps: 289.56,
  zeroRangeM: 100,
  sightHeightMm: 66,
  mountCantMoa: 30,
);

const _cards = {
  'profile-summary-rifle': 'Tüfek Marka/Model',
  'profile-summary-scope': 'Dürbün Marka/Model',
  'profile-summary-ammo': 'Mühimmat Marka/Model',
};

Future<void> _pump(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = 'p-oe',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  for (final (width, scale) in const [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('$width pt, ×$scale: no titles, new labels in their cards', (
      tester,
    ) async {
      await _pump(tester, width, scale);
      expect(tester.takeException(), isNull);

      for (final title in const [
        'Tüfek bilgileri',
        'Dürbün bilgileri',
        'Mühimmat bilgileri',
      ]) {
        expect(find.text(title), findsNothing, reason: title);
      }
      expect(find.text('Marka / Model'), findsNothing);

      for (final MapEntry(key: key, value: label) in _cards.entries) {
        final card = find.byKey(Key(key));
        expect(card, findsOneWidget, reason: key);
        expect(find.text(label), findsOneWidget, reason: label);
        expect(
          find.descendant(of: card, matching: find.text(label)),
          findsOneWidget,
          reason: '$label in $key',
        );
        final rect = tester.getRect(card);
        expect(rect.right, lessThanOrEqualTo(width + 0.01), reason: key);
        // The label is the card's first row.
        expect(
          tester.getRect(find.text(label)).top,
          lessThan(rect.top + 40),
          reason: label,
        );
      }

      // Cards in order with the same gap (MenzilSpace.lg) between them.
      Rect at(String key) => tester.getRect(find.byKey(Key(key)));
      final rifle = at('profile-summary-rifle');
      final scope = at('profile-summary-scope');
      final ammo = at('profile-summary-ammo');
      expect(scope.top - rifle.bottom, moreOrLessEquals(MenzilSpace.lg));
      expect(ammo.top - scope.bottom, moreOrLessEquals(MenzilSpace.lg));
    });
  }
}
