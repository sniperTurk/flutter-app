// Pro tab (owner, 2026-10-08): Profil · Hava Durumu · Pro · Atış · Araçlar.
// Hava Durumu leads to Pro Ayarlar, which holds the incline/cant tiles and
// Coriolis; Atış solves on its own and every page shows its own title.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _profile = RifleProfile(
  id: 'p-pro',
  name: 'Pro',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-pro',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-pro',
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

String? _title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('top-bar-title'))).data;

Future<void> _tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('Hava Durumu → Pro Ayarlar → Atış', (tester) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore()..value = 'p-pro',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    expect(_title(tester), 'Hava Durumu');
    expect(find.text('Atış girdileri'), findsNothing);
    expect(find.text('Hesapla'), findsNothing);
    expect(find.text('Pro Ayarlara Geç'), findsOneWidget);
    // Rüzgâr düzeltmesi is back on Pro Ayarlar (owner, 2026-10-12).
    expect(find.byKey(const Key('pro-section-wind')), findsNothing);
    expect(find.byKey(const Key('pro-wind-max')), findsNothing);
    await _tapKey(tester, 'environment-continue-pro');

    // Pro Ayarlar: five boxes, all closed at first (owner, 2026-10-09).
    expect(_title(tester), 'Pro Ayarlar');
    for (final id in ['angle', 'wind', 'coriolis', 'target', 'rifle']) {
      expect(find.byKey(Key('pro-section-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('pro-wind-max')), findsNothing);
    // Rüzgâr düzeltmesi comes right after Açı.
    expect(
      tester.getTopLeft(find.byKey(const Key('pro-section-angle'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('pro-section-wind'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('pro-section-wind'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('pro-section-coriolis'))).dy,
      ),
    );
    // Box titles are regular, not bold (owner, 2026-10-11).
    for (final id in ['angle', 'coriolis', 'target', 'rifle']) {
      final title = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(Key('pro-section-$id')),
              matching: find.byType(Text),
            ),
          )
          .first;
      expect(title.style?.fontWeight, FontWeight.w400, reason: id);
    }
    expect(find.byKey(const Key('shot-incline')), findsNothing);
    // Opening a box shows its fields; its explanation opens from the ⓘ
    // next to the title (owner, 2026-10-13). One box at a time.
    await openProFor(tester, const Key('shot-incline'));
    expect(find.byKey(const Key('shot-incline')), findsOneWidget);
    expect(find.byKey(const Key('shot-cant')), findsOneWidget);
    expect(
      find.textContaining('Telefonu dik tut', findRichText: true),
      findsNothing,
    );
    await _tapKey(tester, 'pro-info-angle');
    expect(
      find.textContaining('Telefonu dik tut', findRichText: true),
      findsWidgets,
    );
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    await openProFor(tester, const Key('pro-latitude'));
    expect(find.byKey(const Key('shot-incline')), findsNothing);
    // No on/off switch: the data fields are always shown (owner, 2026-10-11).
    expect(find.byKey(const Key('pro-coriolis-switch')), findsNothing);
    expect(find.byKey(const Key('pro-latitude')), findsOneWidget);
    // A PCP profile sees no powder temperature, but the PCP spin note (in
    // the Tüfek düzeltmeleri ⓘ popup).
    await openProFor(tester, const Key('pro-turret-scale'));
    expect(find.byKey(const Key('pro-powder-source')), findsNothing);
    expect(find.byKey(const Key('pro-spin-pcp-note')), findsNothing);
    await _tapKey(tester, 'pro-info-rifle');
    expect(find.byKey(const Key('pro-spin-pcp-note')), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    await openProFor(tester, const Key('pro-latitude'));
    expect(find.byKey(const Key('pro-latitude')), findsOneWidget);
    expect(find.byKey(const Key('pro-azimuth')), findsOneWidget);
    // Every entered value explains itself (ⓘ).
    expect(find.byTooltip('Bilgi: Enlem'), findsOneWidget);
    expect(find.byTooltip('Bilgi: Atış yönü'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pro-latitude')), '40');
    await tester.enterText(find.byKey(const Key('pro-azimuth')), '0');
    await tester.pumpAndSettle();
    final effect = tester
        .widget<Text>(find.byKey(const Key('pro-coriolis-effect')))
        .data!;
    // Shooting north in the northern hemisphere: the impact moves right.
    expect(effect, contains('sağa'));
    expect(effect, contains('Kule klikleri bunu içerir'));

    await _tapKey(tester, 'pro-continue-shot');
    expect(_title(tester), 'Atış Çözümü');
    expect(find.text('Hesapla'), findsNothing);
    expect(find.byKey(const Key('shot-incline')), findsNothing);
    expect(find.byKey(ScopeDialKeys.impactText), findsOneWidget);
    expect(find.text('Menzil'), findsNothing);
  });
}
