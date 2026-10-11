// Çevrimdışı denetim (2026-10-11): the app in the field with no internet.
//
// Every route to the network is made to fail:
//  * HttpOverrides: any dart:io HttpClient creation throws SocketException
//    and is counted (tile images, package:http's IOClient, anything else);
//  * the weather / place-search ports are the REAL adapters driven by an
//    http client that throws, so their error handling is exercised too.
// Profil, Hava Durumu, Pro and Hedef (single shot and DOPE table) must work
// fully, and no screen may hang or crash.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/features/tools/map_distance_screen.dart';
import 'package:sniper_turk/features/tools/weather_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/adapters/met_no_weather_provider.dart';
import 'package:sniper_turk/tools/adapters/nominatim_place_search.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';
import 'support/tool_fakes.dart';

const _ua = 'SniperTurk/1.0 test@example.invalid';

// A pellet with a BC, so the full drag solver (not the vacuum one) runs.
const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-offline',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _ammo = <String, dynamic>{
  'id': 'c-offline',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 pellet',
  'caliberMm': 6.35,
  'grain': 25.4,
  'ammoType': 'pellet',
  'bc': 0.04,
  'bcModel': 'G1',
};

/// No internet at all: every HttpClient the app tries to make fails.
class _NoInternet extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('Ağ yok (test)');
  }
}

http.Client _failingClient(Object error) => MockClient((_) async => throw error);

/// Production adapters, offline. GPS still works without internet.
ToolsServices _offlineServices({Object? error}) {
  final e = error ?? const SocketException('Ağ yok (test)');
  return testServices(
    location: TestLocation(const LocationFix(38.0752, 26.9366)),
    weather: MetNoWeatherProvider(client: _failingClient(e), userAgent: _ua),
    places: NominatimPlaceSearch(client: _failingClient(e), userAgent: _ua),
  );
}

/// 1x1 transparent PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _OkTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

/// A tile image that fails like a download without internet.
class _OfflineTile extends ImageProvider<_OfflineTile> {
  @override
  Future<_OfflineTile> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_OfflineTile key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(const SocketException('Ağ yok (test)')),
      );
}

class _OfflineTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _OfflineTile();
}

String? _title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('top-bar-title'))).data;

Future<void> _tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  late HttpOverrides? previous;
  late _NoInternet net;

  setUp(() {
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_ammo]),
    );
    previous = HttpOverrides.current;
    net = _NoInternet();
    HttpOverrides.global = net;
  });
  tearDown(() {
    HttpOverrides.global = previous;
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });

  testWidgets('Profil, Hava Durumu, Pro and Hedef work fully offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await store.save(_profile);

    await tester.pumpWidget(
      ToolsServicesScope(
        services: _offlineServices(),
        child: MaterialApp(
          theme: MenzilTheme.light(),
          home: HomeScreen(
            profileStore: store,
            activeProfileStore: MemoryActiveProfileStore()..value = 'p1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Profil: the saved profile is there and active.
    expect(find.text('Aktif profil'), findsOneWidget);

    // Hava Durumu: live weather fails with a clear message, the values are
    // typed by hand instead and the screen stays usable.
    await tester.tap(find.text('Hava Durumu'));
    await tester.pumpAndSettle();
    expect(_title(tester), 'Hava Durumu');
    await _tapKey(tester, 'environment-fill-weather');
    expect(
      find.text('Hava servisine ulaşılamadı; değerleri elle girin.'),
      findsOneWidget,
    );
    expect(find.text('Konumdan canlı hava verisi al'), findsOneWidget);
    await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), '30');
    await tester.pumpAndSettle();
    expect(find.textContaining('Hava yoğunluğu:'), findsOneWidget);

    // Pro Ayarlar: values typed by hand change the solution.
    await _tapKey(tester, 'environment-continue-pro');
    expect(_title(tester), 'Pro Ayarlar');
    await openProFor(tester, const Key('pro-latitude'));
    await tester.enterText(find.byKey(const Key('pro-latitude')), '40');
    await tester.enterText(find.byKey(const Key('pro-azimuth')), '0');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('pro-coriolis-effect'))).data,
      contains('sağa'),
    );

    // Hedef: the shot is solved on the device.
    await _tapKey(tester, 'pro-continue-shot');
    expect(_title(tester), 'Hedef Görünümü');
    expect(find.byKey(ScopeDialKeys.impactText), findsOneWidget);
    expect(find.textContaining('klik'), findsWidgets);

    // Hedef > Tablo: the DOPE table is built offline too.
    await tester.tap(find.byKey(const Key('shot-mode-table')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DOPE oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    // Nothing above went to the network except the one weather request the
    // user asked for, and that failed through the fake client.
    expect(net.attempts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hava & Rüzgâr says there is no internet and offers a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const WeatherScreen(), services: _offlineServices()),
    );
    await tester.tap(find.text('Hava verisini getir'));
    await tester.pumpAndSettle();
    expect(
      find.text('İnternet bağlantısı yok. Bağlandığınızda tekrar deneyin.'),
      findsOneWidget,
    );
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hava & Rüzgâr behind a Wi-Fi login page still says why', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const WeatherScreen(),
        services: _offlineServices(
          error: const HandshakeException('captive portal'),
        ),
      ),
    );
    await tester.tap(find.text('Hava verisini getir'));
    await tester.pumpAndSettle();
    expect(
      find.text('İnternet bağlantısı yok. Bağlandığınızda tekrar deneyin.'),
      findsOneWidget,
    );
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('map place search offline shows a message and does not hang', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _OkTiles()),
        services: _offlineServices(),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('map-search')), 'Seferihisar');
    await tester.tap(find.byKey(const Key('map-search-go')));
    await tester.pump();
    await tester.pump();
    expect(find.text('İnternet bağlantısı yok.'), findsOneWidget);
    // The search can be tried again (the button is enabled, no spinner).
    final go = tester.widget<IconButton>(
      find.byKey(const Key('map-search-go')),
    );
    expect(go.onPressed, isNotNull);
  });

  testWidgets('map place search behind a Wi-Fi login page does not hang', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _OkTiles()),
        services: _offlineServices(
          error: const HandshakeException('captive portal'),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('map-search')), 'Seferihisar');
    await tester.tap(find.byKey(const Key('map-search-go')));
    await tester.pump();
    await tester.pump();
    expect(find.text('İnternet bağlantısı yok.'), findsOneWidget);
    final go = tester.widget<IconButton>(
      find.byKey(const Key('map-search-go')),
    );
    expect(go.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map without internet says the imagery did not load', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _OfflineTiles()),
        services: _offlineServices(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('map-offline')), findsOneWidget);
    expect(
      find.text(
        'Harita yüklenemedi; internet yok olabilir. Mesafeyi elle de girebilirsiniz.',
      ),
      findsOneWidget,
    );
    // GPS still places the shooter and a tap still measures.
    final center = tester.getCenter(find.byKey(const Key('map-view')));
    await tester.tapAt(center + const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Mesafe: —'), findsNothing);
  });

  testWidgets('map with working imagery shows no offline notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MapDistanceScreen(tileProvider: _OkTiles()),
        services: _offlineServices(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('map-offline')), findsNothing);
  });
}
