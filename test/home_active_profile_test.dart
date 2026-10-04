import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
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
    expect(find.text('Önce bir tüfek profili oluştur.'), findsOneWidget);
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
