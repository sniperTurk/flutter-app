// Converted from source-string matching to real widget behaviour tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/empty_states.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

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

      // The example scope starts with both turrets at zero, the right one
      // open; "Çözümü kuleye kur" dials the example solution.
      expect(find.byKey(const ValueKey('windage-open')), findsOneWidget);
      expect(find.text('Kuleler sıfırda'), findsOneWidget);
      await tester.ensureVisible(find.byKey(ScopeDialKeys.dialSolution));
      await tester.tap(find.byKey(ScopeDialKeys.dialSolution));
      await tester.pumpAndSettle();
      expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('empty-shot-range')))
            .textSpan!
            .toPlainText(),
        '305 m',
      );

      await tester.tap(find.text('Pro'));
      await tester.pumpAndSettle();
      expect(find.byKey(EmptyStateKeys.proPreview), findsOneWidget);
      expect(find.byType(BallisticsScreen), findsNothing);
      expect(find.byKey(const Key('empty-pro-map')), findsOneWidget);
      // Boxes start closed and open their explanation.
      expect(find.text('Dürbün eğimi'), findsNothing);
      await tester.tap(find.byKey(const Key('empty-pro-section-angle')));
      await tester.pumpAndSettle();
      expect(find.text('Dürbün eğimi'), findsOneWidget);

      // "Profil oluştur" opens the new-profile form on Profil.
      await tester.ensureVisible(find.byKey(EmptyStateKeys.create));
      await tester.pumpAndSettle();
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
