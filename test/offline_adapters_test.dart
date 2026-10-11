// Çevrimdışı denetim (2026-10-11): the real network adapters with an HTTP
// client that fails the way a phone without internet (or behind a Wi-Fi
// login page) fails. Every failure must become the adapter's own typed
// failure with a Turkish message; nothing raw may reach the screens.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sniper_turk/tools/adapters/met_no_weather_provider.dart';
import 'package:sniper_turk/tools/adapters/nominatim_place_search.dart';
import 'package:sniper_turk/tools/ports/place_search.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';

const _ua = 'SniperTurk/1.0 test@example.invalid';

/// What `http.Client()` (IOClient) lets through without wrapping it.
final _rawErrors = <String, Object Function()>{
  // Wi-Fi with a login page / wrong TLS: a TlsException, not a socket error.
  'HandshakeException': () => const HandshakeException('captive portal'),
  'TlsException': () => const TlsException('bad certificate'),
  // Any other dart:io I/O error the platform client may raise.
  'IOException (other)': () => const FileSystemException('x'),
};

http.Client _failing(Object Function() error) =>
    MockClient((_) async => throw error());

void main() {
  group('MetNoWeatherProvider without internet', () {
    test('a socket error is an "offline" failure', () async {
      final p = MetNoWeatherProvider(
        client: _failing(() => const SocketException('no route')),
        userAgent: _ua,
      );
      await expectLater(
        p.fetch(39.9, 32.8),
        throwsA(
          isA<WeatherFailure>()
              .having((f) => f.kind, 'kind', WeatherFailureKind.offline)
              .having((f) => f.message, 'message', 'İnternet bağlantısı yok.'),
        ),
      );
    });

    for (final e in _rawErrors.entries) {
      test('${e.key} is an "offline" failure, not a raw error', () async {
        final p = MetNoWeatherProvider(
          client: _failing(e.value),
          userAgent: _ua,
        );
        await expectLater(
          p.fetch(39.9, 32.8),
          throwsA(
            isA<WeatherFailure>().having(
              (f) => f.kind,
              'kind',
              WeatherFailureKind.offline,
            ),
          ),
        );
      });
    }

    test('a hanging connection ends with a timeout failure', () async {
      final p = MetNoWeatherProvider(
        client: MockClient((_) => Completer<http.Response>().future),
        userAgent: _ua,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        p.fetch(39.9, 32.8),
        throwsA(
          isA<WeatherFailure>().having(
            (f) => f.kind,
            'kind',
            WeatherFailureKind.timeout,
          ),
        ),
      );
    });
  });

  group('NominatimPlaceSearch without internet', () {
    test('a socket error is an "offline" failure', () async {
      final s = NominatimPlaceSearch(
        client: _failing(() => const SocketException('no route')),
        userAgent: _ua,
      );
      await expectLater(
        s.search('Seferihisar'),
        throwsA(
          isA<PlaceSearchFailure>()
              .having((f) => f.kind, 'kind', PlaceSearchFailureKind.offline)
              .having((f) => f.message, 'message', 'İnternet bağlantısı yok.'),
        ),
      );
    });

    for (final e in _rawErrors.entries) {
      test('${e.key} is an "offline" failure, not a raw error', () async {
        final s = NominatimPlaceSearch(
          client: _failing(e.value),
          userAgent: _ua,
        );
        await expectLater(
          s.search('Seferihisar'),
          throwsA(
            isA<PlaceSearchFailure>().having(
              (f) => f.kind,
              'kind',
              PlaceSearchFailureKind.offline,
            ),
          ),
        );
      });
    }

    test('a hanging connection ends with a timeout failure', () async {
      final s = NominatimPlaceSearch(
        client: MockClient((_) => Completer<http.Response>().future),
        userAgent: _ua,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        s.search('Seferihisar'),
        throwsA(
          isA<PlaceSearchFailure>().having(
            (f) => f.kind,
            'kind',
            PlaceSearchFailureKind.timeout,
          ),
        ),
      );
    });
  });
}
