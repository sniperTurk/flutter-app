// Profil is the start tab: the active profile comes first, values follow the
// user's unit system, and the next step (Hava Durumu) is one tap away.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/app_settings.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _profile = RifleProfile(
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

Future<void> _pumpList(
  WidgetTester tester, {
  required bool metric,
  bool embedded = true,
  VoidCallback? onContinue,
}) async {
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    AppSettingsScope(
      settings: AppSettings(metric: metric),
      child: MaterialApp(
        theme: MenzilTheme.light(),
        home: embedded
            ? Scaffold(
                body: ProfilesScreen(
                  embedded: true,
                  store: store,
                  activeProfileId: 'p1',
                  onContinue: onContinue,
                ),
              )
            : ProfilesScreen(store: store, activeProfileId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('metric: velocity in fps (Profil rule), zero in m, Turkish', (
    tester,
  ) async {
    await _pumpList(tester, metric: true);
    // 270 m/s = 885.8 fps. Velocity is always fps on Profil.
    expect(find.textContaining('886 fps • Sıfır 25 m'), findsOneWidget);
    expect(find.textContaining('m/s', findRichText: true), findsNothing);
    expect(find.textContaining('Zero'), findsNothing);
  });

  testWidgets('imperial: the same SI profile is shown in fps and yd', (
    tester,
  ) async {
    await _pumpList(tester, metric: false);
    // 270 m/s = 885.8 fps; 25 m = 27.3 yd. The stored profile stays SI.
    expect(find.textContaining('886 fps • Sıfır 27.3 yd'), findsOneWidget);
    expect(find.textContaining('m/s', findRichText: true), findsNothing);
    // Summary tiles render value and unit as one rich text.
    expect(find.text('886 fps', findRichText: true), findsOneWidget);
    expect(find.text('27.3 yd', findRichText: true), findsOneWidget);
  });

  testWidgets('active profile summary comes before the profile list', (
    tester,
  ) async {
    await _pumpList(tester, metric: true, onContinue: () {});
    // The profile name is not repeated under "Aktif profil" (only the row).
    expect(find.text('Bir'), findsOneWidget);
    final summaryY = tester.getTopLeft(find.text('Aktif profil')).dy;
    final listY = tester.getTopLeft(find.text('Profiller')).dy;
    expect(summaryY, lessThan(listY));
  });

  testWidgets('BC note no longer claims BC is unused', (tester) async {
    await _pumpList(tester, metric: true);
    final note = find.textContaining('Katalog değerleri bilgi amaçlıdır');
    await tester.ensureVisible(note);
    expect(note, findsOneWidget);
    expect(
      find.textContaining('BC ve sürükleme modeli kullanılmaz'),
      findsNothing,
    );
    expect(
      find.textContaining('sürüklenme çözücüsünü kullanır'),
      findsOneWidget,
    );
  });

  testWidgets('continue button calls back; absent outside the shell', (
    tester,
  ) async {
    var calls = 0;
    await _pumpList(tester, metric: true, onContinue: () => calls++);
    final button = find.byKey(const Key('profile-continue-weather'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(calls, 1);

    await _pumpList(tester, metric: true, embedded: false);
    expect(find.byKey(const Key('profile-continue-weather')), findsNothing);
  });

  testWidgets('shell: Profil > Hava Durumu\'na geç opens the Hava Durumu tab', (
    tester,
  ) async {
    final store = MemoryProfileStore();
    await store.save(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: HomeScreen(
          profileStore: store,
          activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('environment-open-weather')), findsNothing);

    final button = find.byKey(const Key('profile-continue-weather'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('environment-open-weather')), findsOneWidget);
  });

  testWidgets('editor takes velocity in fps and stores m/s', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _pumpList(tester, metric: true, embedded: false);
    await tester.tap(find.byTooltip('Profili düzenle').first);
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byKey(const Key('profile-velocity-fps')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    // The stored 270 m/s is shown as fps.
    expect(tester.widget<TextField>(field).controller!.text, '885.8');
    expect(find.text('fps'), findsWidgets);
    await tester.enterText(field, '6000');
    await tester.pump();
    expect(find.text('100–4900 arasında bir değer girin.'), findsOneWidget);
    // The reason Kaydet/Güncelle is off is always written above it.
    expect(find.byKey(const Key('profile-missing')), findsOneWidget);
    expect(find.textContaining('Namlu çıkış hızı'), findsWidgets);
    // No separate shot-pressure field any more.
    expect(find.text('Atış basıncı'), findsNothing);
  });

  testWidgets('a new profile starts empty and lists what is missing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: MemoryProfileStore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    String text(String key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;
    // No placeholder data such as 250 m/s is ever filled in.
    expect(text('profile-velocity-fps'), isEmpty);
    expect(text('profile-zero'), isEmpty);
    expect(text('scope-sight-height'), isEmpty);
    final missing = tester
        .widget<Text>(find.byKey(const Key('profile-missing')))
        .data!;
    for (final section in const ['Tüfek:', 'Dürbün:', 'Mühimmat:']) {
      expect(missing, contains(section));
    }
  });

  test('new-profile default names never repeat', () {
    expect(defaultProfileName({}), 'Yeni Profil');
    expect(defaultProfileName({'Yeni Profil'}), 'Yeni Profil 2');
    expect(
      defaultProfileName({'Yeni Profil', 'Yeni Profil 2', 'Avcı'}),
      'Yeni Profil 3',
    );
    // A gap is reused: only taken names are skipped.
    expect(
      defaultProfileName({'Yeni Profil', 'Yeni Profil 3'}),
      'Yeni Profil 2',
    );
  });

  testWidgets('second new profile opens as "Yeni Profil 2"', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(
      const RifleProfile(
        id: 'p0',
        name: 'Yeni Profil',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('profile-name')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.controller!.text, 'Yeni Profil 2');
  });

  testWidgets('editor layout: zero beside the mount, aligned scope fields, '
      'no ammunition Model box', (tester) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: MemoryProfileStore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();

    Finder field(String key) => find.byKey(Key(key), skipOffstage: false);
    final mount = find.byKey(
      const ValueKey('scope-mount-cant-mrad-0.1'),
      skipOffstage: false,
    );
    // Sıfırlama mesafesi is in the Dürbün card, on the Dürbün ayağı row.
    expect(
      find.descendant(
        of: find.byKey(const Key('profile-scope-form')),
        matching: field('profile-zero'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(field('profile-zero')).dy,
      tester.getTopLeft(mount).dy,
    );
    expect(
      tester.getTopLeft(field('profile-zero')).dx,
      greaterThan(tester.getTopLeft(mount).dx),
    );

    // A field without ⓘ lines up with its neighbour that has one.
    Finder box(String key) =>
        find.descendant(of: field(key), matching: find.byType(InputDecorator));
    expect(
      tester.getTopLeft(box('scope-brand')).dy,
      tester.getTopLeft(box('scope-focal-plane')).dy,
    );

    // The ammunition card has no Model box any more.
    expect(field('ammo-model'), findsNothing);
  });
}
