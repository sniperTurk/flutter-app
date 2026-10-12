// Screenshot tour of Atış Öncesi Kontrol (Ö11), Sıfır Grubu (Ö10) and Atış
// Günlüğü (Ö9) for the PR (2026-10-12). Run by sim-screens.yml with
// test=integration_test/kontrol_gunluk_screens_test.dart; it prints
// `SIMSCREEN:<name>` and holds the frame like sim_screens_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/tools/preshot_checklist_screen.dart';
import 'package:sniper_turk/features/tools/shot_journal_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/features/tools/zero_group_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_journal_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour of the three new tools', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    // A catalogue profile: Hatsan Hercules .25, Gazi 6-36 FFP (0,1 MRAD).
    const profile = RifleProfile(
      id: 'sim-p1',
      name: 'Hercules',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'hn-slug-hp2-25-34',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 270,
      zeroRangeM: 25,
      sightHeightMm: 60,
    );
    final profiles = MemoryProfileStore();
    await profiles.save(profile);
    final active = MemoryActiveProfileStore()..value = profile.id;
    const journal = ShotJournalStore();
    final base = DateTime(2026, 10, 5, 9);
    for (final (i, up, sup) in [
      (0, 1.0, false),
      (1, 1.2, false),
      (2, 0.9, false),
      (3, 1.1, false),
      (4, 1.0, false),
      (5, 0.6, true),
      (6, 1.4, true),
    ]) {
      await journal.add(
        ShotRecord(
          id: 'sim$i',
          time: base.add(Duration(days: i)),
          profileId: profile.id,
          rangeM: 50,
          firstShot: true,
          suppressor: sup,
          missUpCm: up,
          missRightCm: i.isEven ? -0.2 : 0.1,
        ),
      );
    }

    var counter = 0;
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shot(String name) async {
      await settle();
      counter++;
      debugPrint('SIMSCREEN:${counter.toString().padLeft(2, '0')}_$name');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 4)),
      );
    }

    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          debugShowCheckedModeBanner: false,
          home: page,
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await settle();
    }

    await show(const Scaffold(body: ToolsScreen()));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await shot('araclar');

    await show(
      PreShotChecklistScreen(
        profileStore: profiles,
        activeProfileStore: active,
      ),
    );
    for (final id in ['profile', 'unit', 'turret']) {
      await tester.tap(find.byKey(Key('check-$id')));
      await settle();
    }
    await shot('kontrol_listesi');

    await show(
      ZeroGroupScreen(profileStore: profiles, activeProfileStore: active),
    );
    final grid = find.byWidgetPredicate((w) => w is DropdownButton<double>);
    await tester.tap(grid);
    await settle();
    await tester.tap(find.text('1 cm').last);
    await settle();
    final target = find.byKey(const Key('zg-target'));
    await tester.ensureVisible(target);
    await settle();
    final rect = tester.getRect(target);
    for (final (r, u) in [(1.2, 0.8), (1.6, 1.3), (0.9, 1.1), (1.4, 0.6)]) {
      await tester.tapAt(
        rect.center + Offset(r * rect.width / 10, -u * rect.height / 10),
      );
      await settle();
    }
    await shot('sifir_grubu_hedef');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await shot('sifir_grubu_sonuc');

    await show(
      ShotJournalScreen(profileStore: profiles, activeProfileStore: active),
    );
    await shot('atis_gunlugu_form');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await shot('atis_gunlugu_soguk_namlu');

    debugPrint('SIMSCREEN_DONE failures=0');
  });
}
