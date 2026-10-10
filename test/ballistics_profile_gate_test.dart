// Converted from source-string matching to real widget behaviour tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/services/sample_profiles.dart';

const _validProfile = RifleProfile(
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

const _staleProfile = RifleProfile(
  id: 'p2',
  name: 'Silinmiş Katalog',
  rifleId: 'no-such-rifle',
  ammunitionId: 'no-such-ammo',
  scopeId: 'no-such-scope',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

void main() {
  testWidgets(
    'without a profile Hedef and Pro explain themselves and solve nothing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profileStore: MemoryProfileStore(),
            activeProfileStore: MemoryActiveProfileStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The app opens on Profil with the welcome page (owner, 2026-10-10).
      expect(find.byKey(EmptyStateKeys.welcome), findsOneWidget);

      await tester.tap(find.text('Hedef'));
      await tester.pumpAndSettle();
      expect(find.byKey(EmptyStateKeys.shotPreview), findsOneWidget);
      expect(find.text('Tahmin yok, hesap var.'), findsOneWidget);
      expect(find.byType(BallisticsScreen), findsNothing);

      await tester.tap(find.text('Pro'));
      await tester.pumpAndSettle();
      expect(find.byKey(EmptyStateKeys.proPreview), findsOneWidget);
      expect(find.byType(BallisticsScreen), findsNothing);

      // "Profil oluştur" opens the new-profile form on Profil.
      await tester.tap(find.byKey(EmptyStateKeys.create));
      await tester.pumpAndSettle();
      expect(find.text('Profil Oluştur'), findsOneWidget);
    },
  );

  testWidgets('without a profile Hava Durumu stays usable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profileStore: MemoryProfileStore(),
          activeProfileStore: MemoryActiveProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('environment-no-profile')), findsOneWidget);
    expect(find.byKey(BallisticsFieldKeys.temperature), findsOneWidget);
    expect(find.byKey(const Key('environment-create-profile')), findsOneWidget);
  });

  testWidgets('"Örnek profille dene" opens Hedef with the sample profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
    final store = MemoryProfileStore();
    final active = MemoryActiveProfileStore();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(profileStore: store, activeProfileStore: active),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(EmptyStateKeys.sample));
    await tester.tap(find.byKey(EmptyStateKeys.sample));
    await tester.pumpAndSettle();
    expect((await store.all()).map((p) => p.id).toSet(), {
      SampleProfiles.pcpId,
      SampleProfiles.firearmId,
    });
    expect(active.value, SampleProfiles.pcpId);
    expect(find.byKey(const Key('shot-sample-note')), findsOneWidget);
    expect(find.byKey(const Key('scope-impact-text')), findsOneWidget);
    // Hedef opens with the solution dialled and the right turret open.
    expect(find.byKey(const ValueKey('windage-open')), findsOneWidget);
    expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
  });

  testWidgets(
    'Ballistics screen fails closed instead of solving with fallback profile values',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: null)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'DOPE oluşturmak için önce bir tüfek profili oluşturup aktif profil olarak seçin.',
        ),
        findsOneWidget,
      );
      expect(find.byType(DataTable), findsNothing);
    },
  );

  testWidgets(
    'Ballistics also fails closed when saved catalog references are stale',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: _staleProfile)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aktif profil katalogla artık eşleşmiyor'),
        findsOneWidget,
      );
      expect(find.byType(DataTable), findsNothing);
    },
  );

  testWidgets(
    'Ballistics screen renders normally for a valid, catalog-matched profile',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BallisticsScreen(profile: _validProfile)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'DOPE oluşturmak için önce bir tüfek profili oluşturup aktif profil olarak seçin.',
        ),
        findsNothing,
      );
      expect(
        find.textContaining('Aktif profil katalogla artık eşleşmiyor'),
        findsNothing,
      );
      expect(find.text('DOPE oluştur'), findsOneWidget);
    },
  );
}
