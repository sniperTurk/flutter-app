import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/map_distance_screen.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/place_search.dart';

import 'support/tool_fakes.dart';

/// 1x1 transparent PNG, so tests never touch the network.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _NoTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

void main() {
  testWidgets('uses the device location as shooter, tap sets the target', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _NoTiles()),
        services: testServices(
          location: TestLocation(const LocationFix(38.0752, 26.9366)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Mesafe: —'), findsOneWidget);

    final center = tester.getCenter(find.byKey(const Key('map-view')));
    await tester.tapAt(center + const Offset(0, 80));
    // flutter_map waits to rule out a double tap before reporting a tap.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Mesafe: —'), findsNothing);
    expect(find.textContaining(' m'), findsWidgets);
  });

  testWidgets('the crosshair button places the active pin at the centre', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _NoTiles()),
        services: testServices(
          location: TestLocation(const LocationFix(38.0752, 26.9366)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('map-crosshair')), findsOneWidget);
    expect(find.textContaining('Mesafe: —'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-place')));
    await tester.pump();
    expect(find.textContaining('Mesafe: —'), findsNothing);
  });

  testWidgets('place search lists matches and a result closes the list', (
    tester,
  ) async {
    final places = TestPlaceSearch(const [
      PlaceResult('Seydiköy, Seferihisar, İzmir', 38.07, 26.93),
    ]);
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _NoTiles()),
        services: testServices(places: places),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('map-search')), 'Seydiköy');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();
    expect(places.queries, ['Seydiköy']);
    expect(find.text('Seydiköy, Seferihisar, İzmir'), findsOneWidget);

    await tester.tap(find.text('Seydiköy, Seferihisar, İzmir'));
    await tester.pump();
    expect(find.byKey(const Key('map-search-results')), findsNothing);
  });

  testWidgets('place search shows the failure message and short queries', (
    tester,
  ) async {
    final places = TestPlaceSearch()
      ..failure = const PlaceSearchFailure(
        PlaceSearchFailureKind.offline,
        'İnternet bağlantısı yok.',
      );
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _NoTiles()),
        services: testServices(places: places),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('map-search')), 'ab');
    await tester.tap(find.byKey(const Key('map-search-go')));
    await tester.pump();
    expect(find.text('En az 3 harf girin.'), findsOneWidget);
    expect(places.queries, isEmpty);

    await tester.enterText(find.byKey(const Key('map-search')), 'İzmir');
    await tester.tap(find.byKey(const Key('map-search-go')));
    await tester.pump();
    await tester.pump();
    expect(find.text('İnternet bağlantısı yok.'), findsOneWidget);
  });

  testWidgets('denied location tells the user to tap the map', (tester) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _NoTiles()),
        services: testServices(
          location: TestLocation(const LocationDenied(permanent: false)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Konum izni verilmedi'), findsOneWidget);
  });

  testWidgets('"Bu mesafeyi kullan" only when asked to return a distance', (
    tester,
  ) async {
    await tester.pumpWidget(host(MapDistanceScreen(tileProvider: _NoTiles())));
    await tester.pump();
    expect(find.byKey(const Key('map-use')), findsNothing);

    await tester.pumpWidget(
      host(MapDistanceScreen(returnDistance: true, tileProvider: _NoTiles())),
    );
    await tester.pump();
    expect(find.byKey(const Key('map-use')), findsOneWidget);
  });
}
