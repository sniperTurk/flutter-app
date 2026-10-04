// Converted from source-string matching to real widget behaviour tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
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
);

void main() {
  testWidgets('home disables Ballistics navigation when there is no active profile', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(profileStore: MemoryProfileStore(), activeProfileStore: MemoryActiveProfileStore()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DOPE için önce aktif profil oluşturun'), findsOneWidget);
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Balistik / DOPE'));
    expect(tile.enabled, isFalse);

    await tester.tap(find.text('Balistik / DOPE'));
    await tester.pumpAndSettle();
    expect(find.byType(BallisticsScreen), findsNothing);
  });

  testWidgets('Ballistics screen fails closed instead of solving with fallback profile values', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BallisticsScreen(profile: null)));
    await tester.pumpAndSettle();

    expect(
      find.text('DOPE oluşturmak için önce bir tüfek profili oluşturup aktif profil olarak seçin.'),
      findsOneWidget,
    );
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('Ballistics also fails closed when saved catalog references are stale', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BallisticsScreen(profile: _staleProfile)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aktif profil katalogla artık eşleşmiyor'), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('Ballistics screen renders normally for a valid, catalog-matched profile', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BallisticsScreen(profile: _validProfile)));
    await tester.pumpAndSettle();

    expect(find.text('DOPE oluşturmak için önce bir tüfek profili oluşturup aktif profil olarak seçin.'), findsNothing);
    expect(find.textContaining('Aktif profil katalogla artık eşleşmiyor'), findsNothing);
    expect(find.text('DOPE oluştur'), findsOneWidget);
  });
}
