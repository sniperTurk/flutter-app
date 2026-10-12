// Araçlar > Atış Öncesi Kontrol (Ö11), Sıfır Grubu (Ö10), Atış Günlüğü (Ö9).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/tools/cold_bore_hint.dart';
import 'package:sniper_turk/features/tools/preshot_checklist_screen.dart';
import 'package:sniper_turk/features/tools/shot_journal_screen.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/features/tools/zero_group_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/shot_journal_store.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/tool_fakes.dart';

const _ammo = Ammunition(
  id: 'test-slug-kg',
  brand: 'Test slug',
  model: '',
  platform: WeaponPlatform.pcp,
  caliberMm: 6.35,
  grain: 51,
  type: AmmunitionType.slug,
  ballisticCoefficient: 0.12,
  ballisticModel: BallisticModel.g1,
  userEntered: true,
);

const _profile = RifleProfile(
  id: 'p1',
  name: 'Hercules',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'test-slug-kg',
  // Gazi 6-36: 0,1 MRAD tık, FFP.
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

Future<void> _pump(WidgetTester tester, Widget Function(
  ProfileStore, ActiveProfileStore) build, {bool withProfile = true}) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  final active = MemoryActiveProfileStore();
  if (withProfile) {
    await store.save(_profile);
    active.value = _profile.id;
  }
  await tester.pumpWidget(host(build(store, active)));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, Key key, String item) async {
  final box = find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate((w) => w is DropdownButton),
  );
  await tester.ensureVisible(box);
  await tester.pumpAndSettle();
  await tester.tap(box);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, Key key, String text) async {
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

ShotRecord _first(String id, double up, {bool suppressor = false}) =>
    ShotRecord(
      id: id,
      time: DateTime.utc(2026, 10, 1, 9, int.parse(id.substring(1))),
      profileId: 'p1',
      rangeM: 100,
      firstShot: true,
      suppressor: suppressor,
      missUpCm: up,
      missRightCm: 0,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(
    () => CatalogRepository.installUserCatalog(
      const UserCatalog(ammunition: [_ammo]),
    ),
  );
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('hub lists the three new tools last', (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const Scaffold(body: ToolsScreen())));
    for (final k in ['tool-checklist', 'tool-zero-group', 'tool-shot-journal']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
  });

  group('Atış Öncesi Kontrol', () {
    testWidgets('FFP scope: five items, counter, ready, clear', (tester) async {
      await _pump(
        tester,
        (s, a) => PreShotChecklistScreen(profileStore: s, activeProfileStore: a),
      );
      expect(find.text('Doğru profil: Hercules'), findsOneWidget);
      expect(find.byKey(const Key('check-sfp')), findsNothing);
      expect(find.text('0 / 5 tamam'), findsOneWidget);
      // Every item explains itself.
      expect(find.byType(MenzilInfoButton), findsNWidgets(5));
      for (final id in ['profile', 'unit', 'turret', 'parallax']) {
        await tester.tap(find.byKey(Key('check-$id')));
        await tester.pumpAndSettle();
      }
      expect(find.text('4 / 5 tamam'), findsOneWidget);
      expect(find.byKey(const Key('check-ready')), findsNothing);
      await tester.tap(find.byKey(const Key('check-level')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('check-ready')), findsOneWidget);
      await tester.tap(find.byKey(const Key('check-clear')));
      await tester.pumpAndSettle();
      expect(find.text('0 / 5 tamam'), findsOneWidget);
    });

    testWidgets('no profile: list still works, SFP item shown', (tester) async {
      await _pump(
        tester,
        (s, a) => PreShotChecklistScreen(profileStore: s, activeProfileStore: a),
        withProfile: false,
      );
      expect(find.text('Doğru profil seçili'), findsOneWidget);
      expect(find.byKey(const Key('check-sfp')), findsOneWidget);
    });
  });

  group('Sıfır Grubu', () {
    Future<void> tapSquares(WidgetTester tester, double r, double u) async {
      final rect = tester.getRect(find.byKey(const Key('zg-target')));
      await tester.tapAt(
        rect.center + Offset(r * rect.width / 10, -u * rect.height / 10),
      );
      await tester.pumpAndSettle();
    }

    Future<void> threeShots(WidgetTester tester) async {
      await _pump(
        tester,
        (s, a) => ZeroGroupScreen(profileStore: s, activeProfileStore: a),
      );
      // Mesafe starts at the profile's zero range.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('zg-range')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '25',
      );
      await _select(tester, const Key('zg-grid'), '1 cm');
      final target = find.byKey(const Key('zg-target'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tapSquares(tester, 0, 0);
      await tapSquares(tester, 2, 0);
      await tapSquares(tester, 0, 2);
    }

    testWidgets('three taps: centre, sigma and how many more shots', (
      tester,
    ) async {
      await threeShots(tester);
      expect(find.text('3'), findsWidgets);
      // sigma = 1,15 cm, click 0,25 cm at 25 m -> 22 shots in total.
      final more = tester
          .widget<Text>(find.byKey(const Key('zg-more')))
          .data!;
      expect(more, contains('19 atış daha'));
      expect(more, contains('1 klikten büyük'));
    });

    testWidgets('transfer needs Uygula; Vazgeç writes nothing', (tester) async {
      await threeShots(tester);
      final apply = find.byKey(const Key('zg-apply'));
      await tester.ensureVisible(apply);
      await tester.pumpAndSettle();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(await const ShotSettingsStore().load('p1'), isNull);

      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();
      final s = (await const ShotSettingsStore().load('p1'))!;
      expect(s.zeroUpText, '0,7');
      expect(s.zeroRightText, '0,7');
    });

    testWidgets('undo removes the last shot', (tester) async {
      await threeShots(tester);
      final undo = find.byKey(const Key('zg-undo'));
      await tester.ensureVisible(undo);
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('zg-more'))).data!,
        contains('1 atış daha'),
      );
    });

    testWidgets('no profile: says so', (tester) async {
      await _pump(
        tester,
        (s, a) => ZeroGroupScreen(profileStore: s, activeProfileStore: a),
        withProfile: false,
      );
      expect(find.byKey(const Key('zg-no-profile')), findsOneWidget);
      expect(find.byKey(const Key('zg-target')), findsNothing);
    });
  });

  group('Atış Günlüğü', () {
    testWidgets('saves a record with the active profile', (tester) async {
      await _pump(
        tester,
        (s, a) => ShotJournalScreen(profileStore: s, activeProfileStore: a),
      );
      await _type(tester, const Key('sj-range'), '50');
      await _select(tester, const Key('sj-first'), 'Evet');
      await _select(tester, const Key('sj-suppressor'), 'Takılı değil');
      await _type(tester, const Key('sj-miss-up'), '1,5');
      await _type(tester, const Key('sj-miss-right'), '-0,5');
      final save = find.byKey(const Key('sj-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final all = await const ShotJournalStore().load(profileId: 'p1');
      expect(all.length, 1);
      expect(all.single.rangeM, 50);
      expect(all.single.missUpCm, 1.5);
      expect(all.single.missRightCm, -0.5);
      expect(all.single.firstShot, isTrue);
      expect(all.single.suppressor, isFalse);
      expect(all.single.unitLabel, 'MRAD');
    });

    testWidgets('missing choices: nothing saved', (tester) async {
      await _pump(
        tester,
        (s, a) => ShotJournalScreen(profileStore: s, activeProfileStore: a),
      );
      await _type(tester, const Key('sj-range'), '50');
      await _type(tester, const Key('sj-miss-up'), '1');
      await _type(tester, const Key('sj-miss-right'), '0');
      final save = find.byKey(const Key('sj-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(await const ShotJournalStore().load(), isEmpty);
    });

    testWidgets('four first shots: no suggestion, says why', (tester) async {
      for (var i = 1; i <= 4; i++) {
        await const ShotJournalStore().add(_first('r$i', 2));
      }
      await _pump(
        tester,
        (s, a) => ShotJournalScreen(profileStore: s, activeProfileStore: a),
      );
      expect(find.byKey(const Key('cb-approve-off')), findsNothing);
      expect(find.textContaining('en az 5'), findsOneWidget);
    });

    testWidgets('five consistent first shots: approve after confirmation', (
      tester,
    ) async {
      for (final (i, up) in [(1, 1.9), (2, 2.1), (3, 2.0), (4, 1.8), (5, 2.2)]) {
        await const ShotJournalStore().add(_first('r$i', up));
      }
      await _pump(
        tester,
        (s, a) => ShotJournalScreen(profileStore: s, activeProfileStore: a),
      );
      final approve = find.byKey(const Key('cb-approve-off'));
      await tester.ensureVisible(approve);
      await tester.pumpAndSettle();
      await tester.tap(approve);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(
        await const ShotJournalStore().isApproved('p1', suppressor: false),
        isFalse,
      );
      await tester.tap(approve);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();
      expect(
        await const ShotJournalStore().isApproved('p1', suppressor: false),
        isTrue,
      );
    });
  });

  group('Hedef: soğuk namlu satırı', () {
    Future<void> seed({required bool approve}) async {
      for (final (i, up) in [(1, 1.9), (2, 2.1), (3, 2.0), (4, 1.8), (5, 2.2)]) {
        await const ShotJournalStore().add(_first('r$i', up));
      }
      if (approve) {
        await const ShotJournalStore().setApproved(
          'p1',
          suppressor: false,
          approved: true,
        );
      }
    }

    testWidgets('not approved: nothing shown', (tester) async {
      await seed(approve: false);
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: ColdBoreHint(profileId: 'p1', unit: AngularUnit.mrad),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cold-bore-hint')), findsNothing);
    });

    testWidgets('approved: first-shot line against the mean', (tester) async {
      await seed(approve: true);
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: ColdBoreHint(profileId: 'p1', unit: AngularUnit.mrad),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester
          .widget<Text>(find.byKey(const Key('cold-bore-hint')))
          .data!;
      expect(text, contains('0,20 MRAD aşağı'));
      expect(text, contains('susturucusuz'));
    });
  });
}
