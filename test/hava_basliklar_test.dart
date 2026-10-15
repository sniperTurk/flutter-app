// Hava Durumu headers (owner, 2026-10-13): "Basınç Ölçer" (capital Ö) and
// "Rüzgâr" are the same size as the Profil summary headers (18).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_hb',
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
  'id': 'manual_ammo_hb',
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
  'id': 'manual_scope_hb',
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
  id: 'p-hb',
  name: 'Hercules',
  rifleId: 'manual_rifle_hb',
  ammunitionId: 'manual_ammo_hb',
  scopeId: 'manual_scope_hb',
  muzzleVelocityMps: 289.56,
  zeroRangeM: 100,
  sightHeightMm: 66,
);

Finder _header(String title) => find.descendant(
  of: find.byType(MenzilSectionHeader),
  matching: find.text(title),
);

double _size(WidgetTester tester, String title) =>
    tester.widget<Text>(_header(title)).style!.fontSize!;

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo, _scope]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Hava Durumu headers render at the Profil summary size', (
    tester,
  ) async {
    await _sized(tester);

    // Profil summary header size (Tüfek bilgileri, PR #266).
    final store = MemoryProfileStore();
    await store.save(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore()..value = 'p-hb',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_header('Tüfek bilgileri'), findsOneWidget);
    final profilSize = _size(tester, 'Tüfek bilgileri');
    expect(profilSize, 18);

    // Hava Durumu.
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: const Scaffold(
          body: BallisticsScreen(
            profile: _profile,
            view: BallisticsView.environment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, _header('Basınç Ölçer'));
    expect(_header('Basınç Ölçer'), findsOneWidget);
    expect(_size(tester, 'Basınç Ölçer'), profilSize);
    expect(find.text('Basınç ölçer'), findsNothing);

    // The new İrtifa card (owner, 2026-10-14): the same size.
    await _scrollTo(tester, _header('İrtifa'));
    expect(_size(tester, 'İrtifa'), profilSize);

    await _scrollTo(tester, _header('Rüzgâr'));
    expect(_header('Rüzgâr'), findsOneWidget);
    expect(_size(tester, 'Rüzgâr'), profilSize);
    expect(find.text('Basınç ölçer'), findsNothing);
  });
}
