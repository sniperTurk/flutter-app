import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/map_distance_screen.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';

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
    await tester.pump();

    expect(find.textContaining('Mesafe: —'), findsNothing);
    expect(find.textContaining(' m'), findsWidgets);
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
    await tester.pumpWidget(
      host(MapDistanceScreen(tileProvider: _NoTiles())),
    );
    await tester.pump();
    expect(find.byKey(const Key('map-use')), findsNothing);

    await tester.pumpWidget(
      host(
        MapDistanceScreen(returnDistance: true, tileProvider: _NoTiles()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('map-use')), findsOneWidget);
  });
}
