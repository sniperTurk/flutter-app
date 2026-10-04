// Converted from source-string / substring-offset matching to real widget
// behaviour tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51', // catalog entry with no BC/model set (see catalog_repository.dart)
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

void main() {
  testWidgets('new solve request clears a previously shown DOPE table when validation fails', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BallisticsScreen(profile: _profile)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget, reason: 'a first solve with valid defaults should produce a table');

    // Now break a required field and solve again. The stale table from the
    // successful run above must not remain on screen once a new request has
    // started, even though this second request fails validation.
    await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), 'abc');
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Sayısal alanları kontrol edin.'), findsOneWidget);
  });

  testWidgets('catalog ammunition without a validated BC still solves via the vacuum baseline', (tester) async {
    // gmaz-51 has ballisticCoefficient == null in the catalog. This exercises
    // the same code path that would throw UnsupportedError (see
    // BallisticEngine.solve) if a BC/ballisticModel were ever passed through;
    // reaching a rendered DataTable here demonstrates the screen is not
    // forwarding BC/model data into the solver for this ammunition.
    await tester.pumpWidget(const MaterialApp(home: BallisticsScreen(profile: _profile)));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bu mühimmat için doğrulanmış BC/model yok'),
      findsOneWidget,
      reason: 'the screen must say so explicitly rather than silently using an unvalidated value',
    );

    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();

    // No UnsupportedError SnackBar and a real table means the BallisticEngine
    // production gate was never tripped for this request.
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Bu balistik model henüz desteklenmiyor.'), findsNothing);
  });
}
