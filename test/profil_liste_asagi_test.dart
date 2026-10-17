// Profil sekmesi sırası (owner, 2026-10-17 19:14 "20 pt olarak yap, iki
// düzeltmeyi de başlat"): Tüfek, Dürbün, Mühimmat kartları; altında
// "Profiller" başlığı ve profil satırları; en sonda "Hava Durumu'na geç".
// "Katalog değerleri bilgi amaçlıdır…" notu silindi. Kartlar arası ve
// Mühimmat → Profiller arası görünen boşluk 20 pt (MenzilSpace.xl); satır
// arası 8 pt.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _slug = Ammunition(
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

const _a = RifleProfile(
  id: 'a',
  name: 'Hercules',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'test_slug_g1',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 274.32,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _b = RifleProfile(
  id: 'b',
  name: 'Yedek',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'test_slug_g1',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 30,
  sightHeightMm: 55,
  pressureBar: 200,
);

Future<void> _pump(
  WidgetTester tester, {
  List<RifleProfile> profiles = const [_a, _b],
  String? active = 'a',
  bool embedded = true,
  double width = 393,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ProfilesScreen(
          embedded: embedded,
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

Finder _row(String id) => find
    .ancestor(
      of: find.byKey(Key('profile-menu-$id')),
      matching: find.byType(InkWell),
    )
    .first;

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

/// The drawn card (border + fill) of a summary grid, without the grid's
/// own bottom padding.
Rect _visibleCard(WidgetTester tester, String key) => tester.getRect(
  find
      .descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

void main() {
  setUp(
    () => CatalogRepository.installUserCatalog(
      const UserCatalog(ammunition: [_slug]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('order: cards, Profiller list, Hava Durumu\'na geç last', (
    tester,
  ) async {
    await _pump(tester);
    final tops = <String, double>{
      'rifle': _rect(tester, 'profile-summary-rifle').top,
      'scope': _rect(tester, 'profile-summary-scope').top,
      'ammo': _rect(tester, 'profile-summary-ammo').top,
      'header': _rect(tester, 'profiles-list-header').top,
      'row a': tester.getRect(_row('a')).top,
      'row b': tester.getRect(_row('b')).top,
      'weather': _rect(tester, 'profile-continue-weather').top,
    };
    final names = tops.keys.toList();
    for (var i = 1; i < names.length; i++) {
      expect(
        tops[names[i]]!,
        greaterThan(tops[names[i - 1]]!),
        reason: '${names[i - 1]} before ${names[i]}',
      );
    }
    // The list sits below the Mühimmat card, the button below every row.
    expect(
      _rect(tester, 'profiles-list-header').top,
      greaterThanOrEqualTo(_rect(tester, 'profile-summary-ammo').bottom),
    );
    expect(
      _rect(tester, 'profile-continue-weather').top,
      greaterThan(tester.getRect(_row('b')).bottom),
    );
  });

  testWidgets('the catalog note is gone', (tester) async {
    await _pump(tester);
    expect(find.textContaining('Katalog değerleri'), findsNothing);
    expect(find.textContaining('vakum temel hesap'), findsNothing);
    expect(find.textContaining('sürüklenme çözücüsünü'), findsNothing);
  });

  testWidgets('visible gaps: cards 20 pt, Mühimmat → Profiller 20 pt', (
    tester,
  ) async {
    await _pump(tester);
    final rifle = _visibleCard(tester, 'profile-summary-rifle');
    final scope = _visibleCard(tester, 'profile-summary-scope');
    final ammo = _visibleCard(tester, 'profile-summary-ammo');
    final header = _rect(tester, 'profiles-list-header');
    expect(scope.top - rifle.bottom, moreOrLessEquals(MenzilSpace.xl));
    expect(ammo.top - scope.bottom, moreOrLessEquals(MenzilSpace.xl));
    expect(header.top - ammo.bottom, moreOrLessEquals(MenzilSpace.xl));
    // ignore: avoid_print
    print(
      'PROFIL_LISTE_ASAGI|kart=${(scope.top - rifle.bottom).toStringAsFixed(1)}'
      '|muhimmat_profiller=${(header.top - ammo.bottom).toStringAsFixed(1)}',
    );
  });

  testWidgets('profile rows 8 pt apart; button 18 pt below the last row', (
    tester,
  ) async {
    await _pump(tester);
    final a = tester.getRect(_row('a'));
    final b = tester.getRect(_row('b'));
    expect(b.top - a.bottom, moreOrLessEquals(MenzilSpace.sm));
    // The row's own 8 pt bottom padding + the unchanged MenzilSpace.md
    // above the button.
    final button = _rect(tester, 'profile-continue-weather');
    expect(
      button.top - b.bottom,
      moreOrLessEquals(MenzilSpace.sm + MenzilSpace.md),
    );
  });

  for (final (width, scale) in const [(320.0, 1.25), (320.0, 1.0)]) {
    testWidgets('$width pt, ×$scale: no overflow, same order', (tester) async {
      await _pump(tester, width: width, scale: scale);
      expect(tester.takeException(), isNull);
      final ammo = _rect(tester, 'profile-summary-ammo');
      final header = _rect(tester, 'profiles-list-header');
      final button = _rect(tester, 'profile-continue-weather');
      expect(header.top, greaterThanOrEqualTo(ammo.bottom));
      expect(button.top, greaterThan(tester.getRect(_row('b')).bottom));
      expect(button.right, lessThanOrEqualTo(width));
    });
  }

  testWidgets('no active profile: list only, no cards, no button', (
    tester,
  ) async {
    await _pump(tester, active: null);
    expect(find.byKey(const Key('profiles-list-header')), findsOneWidget);
    expect(find.byKey(const Key('profiles-add')), findsOneWidget);
    expect(_row('a'), findsOneWidget);
    expect(find.byKey(const Key('profile-summary-rifle')), findsNothing);
    expect(find.byKey(const Key('profile-continue-weather')), findsNothing);
  });

  testWidgets('empty list (not embedded): empty card and Profil ekle', (
    tester,
  ) async {
    await _pump(tester, profiles: const [], active: null, embedded: false);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Henüz kayıtlı profil yok'), findsOneWidget);
    expect(find.byKey(const Key('profiles-add')), findsOneWidget);
    expect(find.byKey(const Key('profile-continue-weather')), findsNothing);
  });

  testWidgets('zero profiles (embedded): welcome page unchanged', (
    tester,
  ) async {
    await _pump(tester, profiles: const [], active: null);
    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomePanel), findsOneWidget);
    expect(find.byKey(const Key('profiles-list-header')), findsNothing);
  });
}
