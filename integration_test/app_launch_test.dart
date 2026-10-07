import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('production app launches and core routes open on iOS', (
    tester,
  ) async {
    // Clean install on every run: the test writes a profile further down, so a
    // second run on the same simulator would otherwise start with stale data.
    await (await SharedPreferences.getInstance()).clear();
    app.main();
    await tester.pumpAndSettle();

    // Enter through main() so this exercises the bundled-catalog startup guard
    // and the real persistent-store/plugin wiring on an iOS runtime.
    expect(find.text('Katalog yüklenemedi'), findsNothing);
    // The app opens on Profil, which shows no Menzil wordmark.
    expect(find.text('Menzil'), findsNothing);
    for (final tab in const ['Profil', 'Hava Durumu', 'Atış', 'Araçlar']) {
      expect(
        find.text(tab),
        findsWidgets,
        reason: 'bottom navigation tab $tab',
      );
    }
    // The app opens on Profil; on a clean install the ballistic workspace
    // stays locked without a profile.
    await tester.tap(find.text('Atış').first);
    await tester.pumpAndSettle();
    expect(find.text('DOPE için önce aktif profil oluşturun'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Exercise the production Navigator wiring instead of stopping at first
    // frame. These routes are intentionally usable without a profile and are
    // safe smoke-test targets on a clean install.
    await tester.tap(find.text('Araçlar').first);
    await tester.pumpAndSettle();
    // The hub now lists nine tools, so Katalog can sit below the fold.
    await tester.ensureVisible(find.text('Katalog').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Katalog').first);
    await tester.pumpAndSettle();
    expect(find.text('PCP Tüfekler'), findsWidgets);
    // The section headers render a record count suffix ("PCP Mühimmat (N)",
    // "Dürbünler (N)"), so an exact find.text() would never match them. The
    // catalog list is lazy, so scroll each header into view first.
    final catalogList = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.textContaining('PCP Mühimmat'),
      400,
      scrollable: catalogList,
      maxScrolls: 400,
    );
    expect(find.textContaining('PCP Mühimmat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Dürbünler'),
      400,
      scrollable: catalogList,
      maxScrolls: 400,
    );
    expect(find.textContaining('Dürbünler'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Araçlar'), findsWidgets);

    // Profiles owns persistence and active-profile selection, so opening it on
    // a clean install exercises another production route plus the real
    // SharedPreferences-backed stores without mutating user data.
    await tester.tap(find.text('Profil').first);
    await tester.pumpAndSettle();
    expect(find.text('Profiller'), findsWidgets);
    expect(find.textContaining('Henüz kayıtlı profil yok'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Exercise the real SharedPreferences write path, not only a read-only route.
    // The rifle is typed in (no catalog rifle is preselected); ammunition and
    // scope keep their defaults. Saving proves validation and the personal
    // catalog + profile persistence wiring on an actual iOS runtime.
    await tester.tap(find.text('Yeni profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Oluştur'), findsOneWidget);
    Future<void> type(String key, String text) async {
      final field = find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      await tester.pump();
    }

    await type('rifle-brand', 'Test Marka');
    await type('rifle-model', 'Test Model');
    await type('rifle-caliber', '6,35');
    await type('rifle-barrel', '60');
    await type('rifle-twist-rate', '16');
    await type('rifle-regulator', '120');
    await tester.ensureVisible(find.byKey(const Key('rifle-twist-direction')));
    await tester.tap(find.byKey(const Key('rifle-twist-direction')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sağ').last);
    await tester.pumpAndSettle();
    await type('ammo-brand', 'Test Mühimmat');
    await type('ammo-model', 'Test Slug');
    await tester.ensureVisible(find.byKey(const Key('ammo-type')));
    await tester.tap(find.byKey(const Key('ammo-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Slug').last);
    await tester.pumpAndSettle();
    await type('ammo-grain', '33,95');
    await type('ammo-bc', '0,08');
    await tester.ensureVisible(find.byKey(const Key('ammo-bc-model')));
    await tester.tap(find.byKey(const Key('ammo-bc-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('G1').last);
    await tester.pumpAndSettle();
    await type('profile-velocity-fps', '900');
    await type('profile-zero', '25');
    await type('scope-sight-height', '60');
    await type('scope-brand', 'Test Optik');
    await type('scope-min-mag', '6');
    await type('scope-max-mag', '24');
    await type('scope-objective', '56');
    await tester.ensureVisible(find.byKey(const Key('scope-focal-plane')));
    await tester.tap(find.byKey(const Key('scope-focal-plane')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FFP').last);
    await tester.pumpAndSettle();
    expect(find.text('Kaydet'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Profil'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Prove the write reached the platform-backed SharedPreferences store rather
    // than merely surviving in widget memory. The active id must also be durable
    // after the shell reconciles the first profile. This is intentionally an
    // on-device assertion in the iOS integration test.
    final prefs = await SharedPreferences.getInstance();
    final persistedProfiles = prefs.getString('sniper_turk.rifle_profiles.v1');
    final persistedActiveId = prefs.getString(
      'sniper_turk.active_profile_id.v1',
    );
    expect(persistedProfiles, isNotNull);
    expect(persistedProfiles, contains('Yeni Profil'));
    expect(persistedActiveId, isNotNull);
    expect(persistedActiveId, isNotEmpty);

    // The shell must reconcile the first persisted profile as active and unlock
    // DOPE. This closes the end-to-end clean-install path: create -> persist ->
    // reload -> active-profile resolution -> ballistic workspace.
    await tester.tap(find.text('Atış').first);
    await tester.pumpAndSettle();
    expect(find.text('DOPE için önce aktif profil oluşturun'), findsNothing);
    await tester.tap(find.text('Hesapla').first);
    await tester.pumpAndSettle();
    // V378: the typed ammo carries a BC with its G1 model, so Atış uses the
    // drag solver and wind is computed (no KİLİTLİ card).
    expect(find.text('KİLİTLİ'), findsNothing);
    expect(find.byKey(const Key('wind-status-card')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tablo is the second mode of the Atış tab.
    await tester.tap(find.text('Tablo').first);
    await tester.pumpAndSettle();
    expect(find.text('DOPE oluştur'), findsOneWidget);
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Araçlar').first);
    await tester.pumpAndSettle();
    // The hub now lists eight tools (V1.1 added Vuruş Olasılığı), so Ayarlar
    // can sit below the fold on the simulator screen; scroll it into view.
    await tester.ensureVisible(find.text('Ayarlar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayarlar').first);
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Ayarlar'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Araçlar'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
