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
  testWidgets('metric: row and summary show m/s and m, in Turkish', (
    tester,
  ) async {
    await _pumpList(tester, metric: true);
    expect(find.textContaining('270.0 m/s • Sıfır 25 m'), findsOneWidget);
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
    final summaryY = tester.getTopLeft(find.text('Aktif profil')).dy;
    final listY = tester.getTopLeft(find.text('Profiller')).dy;
    expect(summaryY, lessThan(listY));
  });

  testWidgets('BC note no longer claims BC is unused', (tester) async {
    await _pumpList(tester, metric: true);
    final note = find.textContaining('Katalog değerleri bilgi amaçlıdır');
    await tester.ensureVisible(note);
    expect(note, findsOneWidget);
    expect(find.textContaining('BC ve sürükleme modeli kullanılmaz'), findsNothing);
    expect(find.textContaining('sürüklenme çözücüsünü kullanır'), findsOneWidget);
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
}
