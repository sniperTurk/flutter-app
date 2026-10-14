import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ports/elevation_provider.dart';

/// [ElevationProvider] for the Google Maps Elevation API (owner,
/// 2026-10-14: İrtifa → "Haritadan").
///
///  * The key is the Google Maps iOS key the TestFlight build passes as
///    `--dart-define=GOOGLE_MAPS_IOS_API_KEY=…`; it is never committed. A
///    build without it sends nothing ([ElevationFailure.noKey]).
///  * The key is restricted to the iOS app, so every request carries the
///    `X-Ios-Bundle-Identifier` header.
///  * Only the button sends a request: the point (latitude, longitude) of
///    the phone at that moment, nothing else. Nothing is stored here.
///  * Transient failures (timeout, HTTP 5xx / 429, OVER_QUERY_LIMIT,
///    UNKNOWN_ERROR) are retried quickly, after 2 s and 5 s; others are not.
class GoogleElevationProvider implements ElevationProvider {
  static const keyFromBuild = String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY');
  static const bundleId = 'com.sniperturk.sniperTurk';
  static const retryDelays = [Duration(seconds: 2), Duration(seconds: 5)];

  final http.Client? _client;
  final String _apiKey;
  final Duration _timeout;

  /// Waits between retries; tests pass an instant one (no real timers).
  final Future<void> Function(Duration)? _delay;

  const GoogleElevationProvider({
    http.Client? client,
    String apiKey = keyFromBuild,
    Duration timeout = const Duration(seconds: 10),
    Future<void> Function(Duration)? delay,
  }) : _client = client,
       _apiKey = apiKey,
       _timeout = timeout,
       _delay = delay;

  /// The request URL (coordinates with 5 decimals, about 1 m).
  static Uri requestUri(double latitude, double longitude, String key) =>
      Uri.https('maps.googleapis.com', '/maps/api/elevation/json', {
        'locations':
            '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}',
        'key': key,
      });

  @override
  Future<ElevationResult> elevation(double latitude, double longitude) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      return const ElevationUnavailable(ElevationFailure.noKey);
    }
    if (!latitude.isFinite || !longitude.isFinite) {
      return const ElevationUnavailable(ElevationFailure.error);
    }
    final client = _client ?? http.Client();
    try {
      var attempt = 0;
      while (true) {
        final (result, transient) = await _once(
          client,
          requestUri(latitude, longitude, key),
        );
        if (!transient || attempt >= retryDelays.length) return result;
        final wait = retryDelays[attempt++];
        final delay = _delay;
        if (delay != null) {
          await delay(wait);
        } else {
          await Future<void>.delayed(wait);
        }
      }
    } finally {
      if (_client == null) client.close();
    }
  }

  /// One request: the result, and whether a retry may help.
  Future<(ElevationResult, bool)> _once(http.Client client, Uri uri) async {
    final http.Response response;
    try {
      response = await client
          .get(
            uri,
            headers: const {
              'X-Ios-Bundle-Identifier': bundleId,
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
    } on TimeoutException {
      return (const ElevationUnavailable(ElevationFailure.offline), true);
    } on SocketException {
      return (const ElevationUnavailable(ElevationFailure.offline), false);
    } on http.ClientException {
      return (const ElevationUnavailable(ElevationFailure.offline), false);
    } on IOException {
      return (const ElevationUnavailable(ElevationFailure.offline), false);
    }
    final code = response.statusCode;
    if (code == 429 || code >= 500) {
      return (const ElevationUnavailable(ElevationFailure.error), true);
    }
    if (code != 200) {
      return (const ElevationUnavailable(ElevationFailure.error), false);
    }
    return parse(utf8.decode(response.bodyBytes));
  }

  /// Reads an Elevation API JSON body. Exposed for tests.
  static (ElevationResult, bool) parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) {
        return (const ElevationUnavailable(ElevationFailure.error), false);
      }
      final status = json['status'];
      if (status == 'OVER_QUERY_LIMIT' || status == 'UNKNOWN_ERROR') {
        return (const ElevationUnavailable(ElevationFailure.error), true);
      }
      final results = json['results'];
      if (status != 'OK' || results is! List || results.isEmpty) {
        return (const ElevationUnavailable(ElevationFailure.error), false);
      }
      final first = results.first;
      final m = first is Map ? first['elevation'] : null;
      // The deepest land (Dead Sea shore) to above Everest: else unreadable.
      if (m is! num || !m.isFinite || m < -500 || m > 9000) {
        return (const ElevationUnavailable(ElevationFailure.error), false);
      }
      return (ElevationRead(m.toDouble()), false);
    } catch (_) {
      return (const ElevationUnavailable(ElevationFailure.error), false);
    }
  }
}
