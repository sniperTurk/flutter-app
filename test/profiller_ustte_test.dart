// Profil → "Profiller" listesi (owner, 2026-10-15 12:49 "profilleri
// yukarı al, içi böyle yazılı olsun"; Profil.png on design/clean-2026-10-15).
// Since 2026-10-17 19:14 the list sits below the Tüfek / Dürbün / Mühimmat
// summaries and "Hava Durumu'na geç" is last. "Profil ekle" is amber with
// no icon (a "+" glyph since 2026-10-17); each card shows its name
// (+ Aktif) and one summary line, since 2026-10-17 "Tüfek markası, kalibre
// adı" (docs/reports/profil_kart_marka_kalibre.md); the active card has a
// 4 pt amber left edge; ⋯ stays right.
// See docs/reports/profiller_ustte.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

/// Personal records so the BC and its drag model are known exactly.
const _slugG1 = Ammunition(
  id: 'test_slug_g1',
  brand: 'Test',
  model: 'Slug',
  platform: WeaponPlatform.pcp,
  caliberMm: 6.35,
  grain: 33.95,
  type: AmmunitionType.slug,
  ballisticCoefficient: 0.08,
  ballisticModel: BallisticModel.g1,
  userEntered: true,
);

const _bulletG7 = Ammunition(
  id: 'test_bullet_g7',
  brand: 'Test',
  model: 'Match',
  platform: WeaponPlatform.firearm,
  caliberMm: 7.62,
  grain: 175,
  type: AmmunitionType.bullet,
  ballisticCoefficient: 0.243,
  ballisticModel: BallisticModel.g7,
  userEntered: true,
);

/// Metric: 25 m zero, 274,32 m/s = 900 fps.
const _metric = RifleProfile(
  id: 'm',
  name: 'Hercules',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'test_slug_g1',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 274.32,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// Yard: 91,44 m = 100 yd zero, 792,48 m/s = 2600 fps.
const _yard = RifleProfile(
  id: 'y',
  name: 'Turqua',
  rifleId: 'ata-turqua-308',
  ammunitionId: 'test_bullet_g7',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 792.48,
  zeroRangeM: 91.44,
  sightHeightMm: 45,
  distanceUnit: DistanceUnit.yard,
);

/// Catalog slug without a BC.
const _noBc = RifleProfile(
  id: 'n',
  name: 'BC yok',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 274.32,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

Future<void> _pump(
  WidgetTester tester, {
  String active = 'm',
  double width = 393,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in const [_metric, _yard, _noBc]) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      darkTheme: MenzilTheme.dark(),
      themeMode: ThemeMode.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ProfilesScreen(
          embedded: true,
          store: store,
          activeProfileId: active,
          onActivate: (_) async {},
          onContinue: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _menu(String id) => find.byKey(Key('profile-menu-$id'));

Finder _row(String id) =>
    find.ancestor(of: _menu(id), matching: find.byType(InkWell)).first;

Finder _summaryOf(String id) => find.descendant(
  of: _row(id),
  matching: find.byKey(const Key('profile-row-summary')),
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      const UserCatalog(ammunition: [_slugG1, _bulletG7]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('profileListSummary', () {
    test('PCP profile: brand and the mm caliber', () {
      expect(profileListSummary(_metric), 'Hatsan, 6,35 mm');
    });

    test('firearm profile: brand and the cartridge name', () {
      expect(profileListSummary(_yard), 'ATA Arms, .308 Win');
    });

    test('the BC does not change the line', () {
      expect(profileListSummary(_noBc), 'Hatsan, 6,35 mm');
    });

    test('unknown rifle: nothing shown', () {
      const p = RifleProfile(
        id: 'u',
        name: 'Bilinmeyen',
        rifleId: 'no-such-rifle',
        ammunitionId: 'no-such-ammo',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 274.32,
        zeroRangeM: 25,
        sightHeightMm: 60,
      );
      expect(profileListSummary(p), '');
    });
  });

  testWidgets('the Profiller list is below the Mühimmat card', (tester) async {
    // Owner, 2026-10-17 19:14: cards first, then the list, button last.
    await _pump(tester);
    final header = tester.getRect(find.text('Profiller'));
    final ammo = tester.getRect(find.byKey(const Key('profile-summary-ammo')));
    final weather = tester.getRect(
      find.byKey(const Key('profile-continue-weather')),
    );
    expect(header.top, greaterThan(ammo.bottom));
    for (final id in ['m', 'y', 'n']) {
      final row = tester.getRect(_row(id));
      expect(row.top, greaterThan(ammo.bottom), reason: id);
      expect(row.bottom, lessThan(weather.top), reason: id);
    }
    for (final k in [
      'profile-summary-rifle',
      'profile-summary-scope',
      'profile-summary-ammo',
    ]) {
      expect(
        tester.getRect(find.byKey(Key(k))).bottom,
        lessThanOrEqualTo(header.top),
        reason: k,
      );
    }
  });

  testWidgets('header: Profiller left, amber Profil ekle right, no icon', (
    tester,
  ) async {
    await _pump(tester);
    final add = find.byKey(const Key('profiles-add'));
    final button = tester.widget<MenzilPrimaryButton>(add);
    expect(button.amber, isTrue);
    expect(button.icon, isNull);
    expect(find.descendant(of: add, matching: find.byType(Icon)), findsNothing);
    expect(find.text('Profil ekle'), findsOneWidget);
    expect(find.textContaining('kayıtlı profil'), findsNothing);
    final title = tester.getRect(find.text('Profiller'));
    final b = tester.getRect(add);
    expect(b.left, greaterThan(title.right));
    expect(b.top, lessThan(title.bottom));
    expect(b.bottom, greaterThan(title.top));
    expect(b.height, greaterThanOrEqualTo(44));
  });

  testWidgets('cards show the summary line under the name', (tester) async {
    await _pump(tester);
    expect(tester.widget<Text>(_summaryOf('m')).data, 'Hatsan, 6,35 mm');
    expect(tester.widget<Text>(_summaryOf('y')).data, 'ATA Arms, .308 Win');
    expect(tester.widget<Text>(_summaryOf('n')).data, 'Hatsan, 6,35 mm');
    for (final id in ['m', 'y', 'n']) {
      final name = tester.getRect(
        find.descendant(
          of: _row(id),
          matching: find.byKey(const Key('profile-row-name')),
        ),
      );
      final line = tester.getRect(_summaryOf(id));
      expect(line.top, greaterThanOrEqualTo(name.bottom - 0.5), reason: id);
      // Left-aligned under the name.
      expect((line.left - name.left).abs(), lessThan(0.5), reason: id);
      expect(
        tester.widget<Text>(_summaryOf(id)).textAlign,
        TextAlign.start,
        reason: id,
      );
    }
  });

  testWidgets('active card: Aktif label and a 4 pt amber left edge', (
    tester,
  ) async {
    await _pump(tester, active: 'y');
    final ctx = tester.element(_row('y'));
    final c = MenzilColors.of(ctx);
    final aktif = find.descendant(of: _row('y'), matching: find.text('Aktif'));
    expect(aktif, findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(tester.widget<Text>(aktif).style!.color, c.amberInk);
    // Aktif sits right of the name, on its line.
    final name = tester.getRect(
      find.descendant(
        of: _row('y'),
        matching: find.byKey(const Key('profile-row-name')),
      ),
    );
    final label = tester.getRect(aktif);
    expect(label.left, greaterThan(name.right));
    expect(label.top, lessThan(name.bottom));

    final bar = find.byKey(const Key('profile-active-bar'));
    expect(bar, findsOneWidget);
    expect(find.descendant(of: _row('y'), matching: bar), findsOneWidget);
    expect(tester.widget<ColoredBox>(bar).color, c.amber);
    final barRect = tester.getRect(bar);
    final card = tester.getRect(_row('y'));
    expect(barRect.width, 4);
    expect(barRect.left, closeTo(card.left, 0.5));
    expect(barRect.top, closeTo(card.top, 0.5));
    expect(barRect.bottom, closeTo(card.bottom, 0.5));
    // Text starts right of the edge, the same inset on every card.
    expect(name.left, greaterThan(barRect.right));
    for (final id in ['m', 'n']) {
      final other = tester.getRect(
        find.descendant(
          of: _row(id),
          matching: find.byKey(const Key('profile-row-name')),
        ),
      );
      expect(other.left, closeTo(name.left, 0.5), reason: id);
    }
    // Old styling gone: no dot, no ink / 2 pt border on the active card.
    expect(
      find.descendant(
        of: find.byType(ProfilesScreen),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNothing,
    );
    for (final id in ['m', 'y', 'n']) {
      final m = tester.widget<Material>(
        find.ancestor(of: _row(id), matching: find.byType(Material)).first,
      );
      final side = (m.shape! as RoundedRectangleBorder).side;
      expect(side.width, 1, reason: id);
      expect(side.color, c.line, reason: id);
    }
  });

  testWidgets('⋯ stays right, ≥44 pt, and opens the menu', (tester) async {
    await _pump(tester);
    for (final id in ['m', 'y', 'n']) {
      final row = tester.getRect(_row(id));
      final more = tester.getRect(
        find.descendant(of: _row(id), matching: find.byType(IconButton)),
      );
      expect(more.width, greaterThanOrEqualTo(44), reason: id);
      expect(more.height, greaterThanOrEqualTo(44), reason: id);
      expect(more.right, lessThanOrEqualTo(row.right), reason: id);
      expect(more.left, greaterThan(row.center.dx), reason: id);
    }
    await tester.tap(_menu('y'));
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('Sil'), findsOneWidget);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('320 pt, ×$scale: no overflow, summary inside the card', (
      tester,
    ) async {
      await _pump(tester, width: 320, scale: scale, active: 'y');
      expect(tester.takeException(), isNull);
      for (final id in ['m', 'y', 'n']) {
        final row = tester.getRect(_row(id));
        final line = tester.getRect(_summaryOf(id));
        final more = tester.getRect(_menu(id));
        expect(row.right, lessThanOrEqualTo(320), reason: id);
        expect(line.right, lessThanOrEqualTo(more.left + 0.5), reason: id);
        expect(line.bottom, lessThanOrEqualTo(row.bottom), reason: id);
      }
    });
  }
}
