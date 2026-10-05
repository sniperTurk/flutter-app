import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

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

Future<MemoryProfileStore> _storeWith(List<RifleProfile> profiles) async {
  final store = MemoryProfileStore();
  for (final p in profiles) {
    await store.save(p);
  }
  return store;
}

Future<void> _pumpShell(
  WidgetTester tester,
  ProfileStore store,
  ActiveProfileStore active,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: HomeScreen(profileStore: store, activeProfileStore: active),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shell shows the Menzil bar and the five tabs', (tester) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );

    expect(find.text('Menzil'), findsOneWidget);
    for (final tab in const ['Atış', 'Tablo', 'Ortam', 'Profil', 'Araçlar']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    // Atış is the start tab and offers the range dial.
    expect(find.text('Hesapla'), findsOneWidget);
    expect(find.bySemanticsLabel('5 artır'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Atış, Tablo and Ortam share one workspace state', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );

    // Edit the environment on Ortam, then solve from Tablo.
    await tester.tap(find.text('Ortam'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), '30');

    await tester.tap(find.text('Tablo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    // Back on Ortam the edited value survived the tab switches, and the
    // atmosphere result of the same solve is shown.
    await tester.tap(find.text('Ortam'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(BallisticsFieldKeys.temperature),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '30');
    expect(find.textContaining('Hava yoğunluğu:'), findsOneWidget);

    // Atış uses the same validated solve: no "calculate first" prompt.
    await tester.tap(find.text('Atış'));
    await tester.pumpAndSettle();
    expect(find.text('Hesapla'), findsNothing);
    expect(find.text('Atış görünümü'), findsOneWidget);
    // V354: elevation is computed from the vacuum drop (valid trigonometry);
    // only wind stays locked, since a vacuum model has no aerodynamic
    // coupling to produce a real wind value.
    expect(find.text('KİLİTLİ'), findsNWidgets(1));
  });

  testWidgets('range dial steps change the evaluated distance', (tester) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();

    expect(find.text('100'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 artır'));
    await tester.pumpAndSettle();
    expect(find.text('105'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('1 azalt'));
    await tester.pumpAndSettle();
    expect(find.text('104'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'shot view shows a vacuum elevation correction but keeps wind locked',
    (tester) async {
      await _pumpShell(
        tester,
        await _storeWith([_profile]),
        MemoryActiveProfileStore(),
      );
      await tester.tap(find.text('Hesapla'));
      await tester.pumpAndSettle();

      // V354: elevation shows a real MOA/mrad value and a click count on the
      // profile's own scope; wind has no aerodynamic coupling in the vacuum
      // model, so it alone stays locked.
      expect(find.text('KİLİTLİ'), findsNWidgets(1));
      expect(find.text('Rüzgâr'), findsOneWidget);
      expect(find.textContaining('MOA'), findsWidgets);
      expect(find.textContaining('mrad'), findsWidgets);
      expect(find.textContaining('klik'), findsWidgets);
      expect(
        find.textContaining('gerçek atış için kullanmayın'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Araçlar lists the V1 tools plus the V1.1 Vuruş Olasılığı tool', (
    tester,
  ) async {
    await _pumpShell(
      tester,
      await _storeWith([_profile]),
      MemoryActiveProfileStore(),
    );
    await tester.tap(find.text('Araçlar'));
    await tester.pumpAndSettle();

    // Chronograph, Sight Height, Compass and Level are back in V1 scope
    // (M1); Vuruş Olasılığı (hit probability) is a V1.1 standalone stats
    // tool. Qwen/cloud wording must stay absent from the hub either way.
    for (final key in const [
      'chronograph',
      'sight-height',
      'compass',
      'level',
      'weather',
      'hit-probability',
      'catalog',
      'settings',
    ]) {
      expect(find.byKey(Key('tool-$key')), findsOneWidget, reason: key);
    }
    expect(find.textContaining('Qwen'), findsNothing);
  });

  testWidgets('Profil tab activates, copies and confirms before deleting', (
    tester,
  ) async {
    // find.bySemanticsLabel throws unless semantics are enabled.
    final semantics = tester.ensureSemantics();
    const second = RifleProfile(
      id: 'p2',
      name: 'İki',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 280,
      zeroRangeM: 30,
      sightHeightMm: 60,
      pressureBar: 200,
    );
    final store = await _storeWith([_profile, second]);
    final active = MemoryActiveProfileStore();
    await _pumpShell(tester, store, active);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Aktif profil'), findsOneWidget);

    // Tapping a row makes it active (persisted through the shell).
    await tester.tap(find.bySemanticsLabel('Profil İki'));
    await tester.pumpAndSettle();
    expect(active.value, 'p2');

    await tester.ensureVisible(find.text('Kopyala'));
    await tester.tap(find.text('Kopyala'));
    await tester.pumpAndSettle();
    expect((await store.all()).map((p) => p.name), contains('İki (kopya)'));

    await tester.ensureVisible(find.text('Sil'));
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Profili sil?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect((await store.all()).length, 3, reason: 'cancel must not delete');
    semantics.dispose();
  });

  testWidgets('profile editor saves through the store with catalog defaults', (
    tester,
  ) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(body: ProfilesScreen(embedded: true, store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz kayıtlı profil yok'), findsOneWidget);

    await tester.tap(find.text('Yeni profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
    final saveButton = tester.widget<MenzilPrimaryButton>(
      find.widgetWithText(MenzilPrimaryButton, 'Kaydet'),
    );
    expect(
      saveButton.onPressed,
      isNotNull,
      reason: 'a new profile with catalog defaults must be saveable',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Profil Oluştur'),
      findsNothing,
      reason: 'editor should have closed after saving',
    );

    expect((await store.all()).single.name, 'Yeni Profil');
    expect(find.text('Yeni Profil'), findsOneWidget);
  });

  testWidgets('MenzilCard hosts ListTile children without ink assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: MenzilCard(
            child: SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Balistik birimleri'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Balistik birimleri'), findsOneWidget);
  });
}
