// Ana düğmelerde ok ve simge yok (owner, 2026-10-15 12:56: "düğmelerde ok
// ve simge olmaması… tamam"): "Hava Durumu'na geç", "Pro Ayarlar'a geç",
// "Hedef'e geç", "Hesapla" and "Profil oluştur" show their label only.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/tools/sight_height_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p-ikon',
  name: 'İkon',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-ikon',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-ikon',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 pellet',
  'caliberMm': 6.35,
  'grain': 25.4,
  'ammoType': 'pellet',
  'bc': 0.04,
  'bcModel': 'G1',
};

/// The button renders exactly [label], passes no icon and draws no Icon.
void _expectTextOnly(WidgetTester tester, Finder button, String label) {
  expect(button, findsOneWidget, reason: label);
  final primary = find.descendant(
    of: button,
    matching: find.byType(MenzilPrimaryButton),
    matchRoot: true,
  );
  expect(primary, findsOneWidget, reason: label);
  final w = tester.widget<MenzilPrimaryButton>(primary);
  expect(w.label, label);
  expect(w.icon, isNull, reason: label);
  expect(
    find.descendant(of: button, matching: find.byType(Icon)),
    findsNothing,
    reason: label,
  );
  expect(
    find.descendant(of: button, matching: find.text(label)),
    findsOneWidget,
    reason: label,
  );
  // No arrow is left in the text either.
  expect(label.contains('→'), isFalse);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(WidgetTester tester, {RifleProfile? profile}) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  if (profile != null) await store.save(profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = profile?.id,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Profil → Hava Durumu → Pro Ayarlar: next buttons are text only', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _profile);

    final toWeather = find.byKey(const Key('profile-continue-weather'));
    await tester.ensureVisible(toWeather);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, toWeather, 'Hava Durumu\'na geç');
    await _tap(tester, toWeather);

    final toPro = find.byKey(const Key('environment-continue-pro'));
    await tester.ensureVisible(toPro);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, toPro, 'Pro Ayarlar\'a geç');
    expect(find.text('Pro Ayarlara Geç'), findsNothing);
    await _tap(tester, toPro);

    final toShot = find.byKey(const Key('pro-continue-shot'));
    await tester.ensureVisible(toShot);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, toShot, 'Hedef\'e geç');
    // Behaviour unchanged: it still leads to Hedef.
    await _tap(tester, toShot);
    expect(
      tester.widget<Text>(find.byKey(const Key('top-bar-title'))).data,
      'Hedef',
    );
  });

  testWidgets('without a profile "Profil oluştur" is text only', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    final create = find.byKey(const Key('environment-create-profile'));
    await tester.ensureVisible(create);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, create, 'Profil oluştur');

    await tester.tap(find.text('Hedef'));
    await tester.pumpAndSettle();
    final empty = find.byKey(EmptyStateKeys.create);
    await tester.ensureVisible(empty);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, empty, 'Profil oluştur');
  });

  testWidgets('Hava Durumu "Hesapla" (no Pro step) is text only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    final solve = find.widgetWithText(MenzilPrimaryButton, 'Hesapla');
    await tester.ensureVisible(solve);
    await tester.pumpAndSettle();
    _expectTextOnly(tester, solve, 'Hesapla');
  });

  testWidgets('Sight Height marking page "Hesapla" is text only', (
    tester,
  ) async {
    final picker = TestPhotoPicker(photo: Uint8List.fromList([0, 1, 2, 3]));
    await tester.pumpWidget(
      host(
        const SightHeightScreen(),
        services: testServices(photoPicker: picker),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('sight-gallery')));
    await tester.tap(find.byKey(const Key('sight-gallery')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final compute = find.byKey(const Key('sight-mark-compute'));
    _expectTextOnly(tester, compute, 'Hesapla');
  });
}
