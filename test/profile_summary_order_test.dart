// Profil (owner, 2026-10-09): summary boxes in the owner's order with the
// new names, no Regülatör / Odak düzlemi / Klik değeri boxes, "Sniper Türk"
// in the top bar and a compact profile selector.
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
  'id': 'manual_rifle_sum',
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
  'id': 'manual_ammo_sum',
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
  'id': 'manual_scope_sum',
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
  id: 'p-sum',
  name: 'Hercules',
  rifleId: 'manual_rifle_sum',
  ammunitionId: 'manual_ammo_sum',
  scopeId: 'manual_scope_sum',
  muzzleVelocityMps: 289.56,
  zeroRangeM: 100,
  sightHeightMm: 66,
  mountCantMoa: 30,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('summary order, names and the top bar', (tester) async {
    tester.view.physicalSize = const Size(430, 3000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore()..value = 'p-sum',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Top bar: "Sniper Türk" on the left; the selector is short.
    expect(find.byKey(const Key('top-bar-brand')), findsOneWidget);
    expect(find.text('Sniper Türk'), findsOneWidget);
    final selector = tester.getSize(
      find.byType(DropdownButtonFormField<RifleProfile>),
    );
    expect(selector.width, lessThanOrEqualTo(170));

    // The Tüfek/Mühimmat/Dürbün name card is gone (owner, 2026-10-09).
    expect(find.textContaining('kişisel kayıt'), findsNothing);
    expect(find.text('Hatsan Hercules'), findsOneWidget);

    const order = [
      'Tüfek Marka Model',
      'Namlu çıkış hızı',
      'Yiv yönü',
      'Kalibre',
      'Yiv oranı',
      'Sight height',
      'Sıfırlama mesafesi',
      'Dürbün Marka Model',
      'Dürbün',
      'Dürbün ayağı',
      'Dürbün birimi',
      'Dürbün üst kule',
      'Mühimmat',
      'BC / model',
    ];
    // Two columns, read row by row (left, then right).
    Offset at(String label) {
      final all = find.text(label);
      // "Dürbün" and "Mühimmat" also label the name card above; take the
      // last (the metric grid comes after it).
      return tester.getTopLeft(all.last);
    }

    for (var i = 1; i < order.length; i++) {
      final a = at(order[i - 1]), b = at(order[i]);
      final sameRow = (a.dy - b.dy).abs() < 4;
      expect(
        sameRow ? b.dx > a.dx : b.dy > a.dy,
        isTrue,
        reason: '${order[i - 1]} before ${order[i]}',
      );
    }

    // New names and values.
    expect(find.text('6-36 x 56 FFP'), findsOneWidget);
    expect(find.text('GaziSniper'), findsOneWidget);
    // Value and unit are one rich text: "260 klik", "50 gr Pellet".
    expect(find.text('260 klik'), findsOneWidget); // 26 mrad / 0.1
    expect(find.text('50 gr Pellet'), findsOneWidget);
    // Gone: separate Regülatör, Odak düzlemi, Klik değeri, Çap, Ağırlık,
    // Büyütme, Kule ayar aralığı and Namlu boxes.
    for (final gone in const [
      'Namlu uzunluğu',
      'Namlu boyu',
      'Regülatör',
      'Odak düzlemi',
      'Klik değeri',
      'Çap',
      'Ağırlık',
      'Büyütme',
      'Kule ayar aralığı',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });
}
