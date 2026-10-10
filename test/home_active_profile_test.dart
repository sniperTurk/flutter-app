import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

class _FailingStaleActiveProfileStore implements ActiveProfileStore {
  String? value = 'deleted-profile';
  @override
  Future<String?> getActiveProfileId() async => value;
  @override
  Future<void> setActiveProfileId(String? id) async =>
      throw StateError('write failed');
}

class _FailingActiveProfileStore implements ActiveProfileStore {
  String? value = 'p1';
  @override
  Future<String?> getActiveProfileId() async => value;
  @override
  Future<void> setActiveProfileId(String? id) async =>
      throw StateError('write failed');
}

void main() {
  testWidgets(
    'failed active-profile write keeps previous selection and reports error',
    (tester) async {
      final profiles = MemoryProfileStore();
      const p1 = RifleProfile(
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
      const p2 = RifleProfile(
        id: 'p2',
        name: 'İki',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      );
      await profiles.save(p1);
      await profiles.save(p2);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profileStore: profiles,
            activeProfileStore: _FailingActiveProfileStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bir'), findsWidgets);

      await tester.tap(find.byType(DropdownButtonFormField<RifleProfile>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İki').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Aktif profil kaydedilemedi. Önceki seçim korundu.'),
        findsOneWidget,
      );
      final dropdown = tester.widget<DropdownButtonFormField<RifleProfile>>(
        find.byType(DropdownButtonFormField<RifleProfile>),
      );
      expect(dropdown.initialValue?.id, 'p1');
      _expectActiveEverywhere(
        tester,
        'p1',
        shownName: 'Bir',
        hiddenName: 'İki',
      );
    },
  );

  testWidgets(
    'successful active-profile write moves form, display and solver',
    (tester) async {
      final profiles = MemoryProfileStore();
      await profiles.save(_profile('p1', 'Bir'));
      await profiles.save(_profile('p2', 'İki'));
      final activeStore = MemoryActiveProfileStore()..value = 'p1';

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profileStore: profiles,
            activeProfileStore: activeStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectActiveEverywhere(
        tester,
        'p1',
        shownName: 'Bir',
        hiddenName: 'İki',
      );

      await tester.tap(find.byType(DropdownButtonFormField<RifleProfile>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İki').last);
      await tester.pumpAndSettle();

      expect(activeStore.value, 'p2');
      _expectActiveEverywhere(
        tester,
        'p2',
        shownName: 'İki',
        hiddenName: 'Bir',
      );
    },
  );
  testWidgets('stale active-profile id is cleared when no profiles remain', (
    tester,
  ) async {
    final profiles = MemoryProfileStore();
    final activeStore = MemoryActiveProfileStore()..value = 'deleted-profile';

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profileStore: profiles,
          activeProfileStore: activeStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(activeStore.value, isNull);
    // No profile: the workspace shows a preview, offstage at start (Profil).
    expect(
      find.byKey(EmptyStateKeys.proPreview, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('failed stale active-id repair does not block loaded profiles', (
    tester,
  ) async {
    final profiles = MemoryProfileStore();
    const p1 = RifleProfile(
      id: 'p1',
      name: 'Kullanılabilir Profil',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 270,
      zeroRangeM: 25,
      sightHeightMm: 60,
      pressureBar: 200,
    );
    await profiles.save(p1);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profileStore: profiles,
          activeProfileStore: _FailingStaleActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kullanılabilir Profil'), findsWidgets);
    expect(find.text('Aktif profil uyarısı'), findsOneWidget);
    expect(
      find.textContaining('Bu oturumda geçerli profil kullanılacak.'),
      findsOneWidget,
    );
    expect(
      find.text('Profil verileri okunamadı. Kayıtlar değiştirilmedi.'),
      findsNothing,
    );
  });
}

RifleProfile _profile(String id, String name) => RifleProfile(
  id: id,
  name: name,
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

/// Checks the real form value (not just the widget's initialValue), the
/// profile name actually painted in the selector, the profile handed to the
/// ballistic solver workspace and the "active" marker on the Profil tab.
void _expectActiveEverywhere(
  WidgetTester tester,
  String id, {
  required String shownName,
  required String hiddenName,
}) {
  final field = find.byType(DropdownButtonFormField<RifleProfile>);
  // DropdownButtonFormField is itself a FormField; its State holds the
  // live value the user sees, independent of initialValue.
  final state = tester.state<FormFieldState<RifleProfile>>(field);
  expect(state.value?.id, id, reason: 'form value');
  expect(
    find.descendant(of: field, matching: find.text(shownName)),
    findsOneWidget,
    reason: 'visible selector text',
  );
  expect(
    find.descendant(of: field, matching: find.text(hiddenName)),
    findsNothing,
    reason: 'other profile must not be painted as selected',
  );
  final solver = tester.widget<BallisticsScreen>(
    find.byType(BallisticsScreen, skipOffstage: false),
  );
  expect(solver.profile?.id, id, reason: 'profile used for calculation');
  final profilesTab = tester.widget<ProfilesScreen>(
    find.byType(ProfilesScreen, skipOffstage: false),
  );
  expect(profilesTab.activeProfileId, id, reason: 'Profil tab active marker');
}
