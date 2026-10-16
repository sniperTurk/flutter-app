import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'watch_solution.dart';

/// Outcome of one send to the native side.
enum WatchSendResult {
  /// Handed to the watch link (e.g. WCSession application context).
  sent,

  /// The native side exists but nothing was delivered (no paired watch, the
  /// watch app is not installed, the session is not active yet).
  notDelivered,

  /// No native side at all (Android, tests, a scaffold without the bridge).
  unavailable,
}

/// The link to a watch. The app uses [MethodChannelWatchTransport]; tests
/// use a fake.
abstract interface class WatchTransport {
  Future<WatchSendResult> send(Map<String, Object> message);

  /// Messages the watch sent to the phone.
  Stream<Map<Object?, Object?>> get incoming;
}

/// `sniper_turk/watch` method channel. Phone → native: `publish(map)` returns
/// true when handed to the watch link. Native → phone: `fromWatch(map)`.
class MethodChannelWatchTransport implements WatchTransport {
  static const channelName = 'sniper_turk/watch';

  final MethodChannel _channel;
  StreamController<Map<Object?, Object?>>? _incoming;

  MethodChannelWatchTransport([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    try {
      final ok = await _channel.invokeMethod<bool>('publish', message);
      return ok == true ? WatchSendResult.sent : WatchSendResult.notDelivered;
    } on MissingPluginException {
      return WatchSendResult.unavailable;
    } on PlatformException {
      return WatchSendResult.notDelivered;
    }
  }

  @override
  Stream<Map<Object?, Object?>> get incoming {
    final existing = _incoming;
    if (existing != null) return existing.stream;
    final controller = StreamController<Map<Object?, Object?>>.broadcast();
    _incoming = controller;
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      if (call.method == 'fromWatch' && args is Map) {
        controller.add(Map<Object?, Object?>.of(args));
      }
      return null;
    });
    return controller.stream;
  }
}

/// Several watch links at once (Apple Watch and Garmin). A send goes to all
/// of them: [WatchSendResult.sent] when any took it,
/// [WatchSendResult.unavailable] only when none has a native side, otherwise
/// [WatchSendResult.notDelivered].
/// Messages from every link arrive on one stream.
class MultiWatchTransport implements WatchTransport {
  final List<WatchTransport> _links;
  Stream<Map<Object?, Object?>>? _incoming;

  MultiWatchTransport(List<WatchTransport> links)
    : _links = List.unmodifiable(links);

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    final results = await Future.wait(
      _links.map((link) async {
        try {
          return await link.send(message);
        } catch (_) {
          return WatchSendResult.notDelivered;
        }
      }),
    );
    if (results.contains(WatchSendResult.sent)) return WatchSendResult.sent;
    if (results.isNotEmpty &&
        results.every((r) => r == WatchSendResult.unavailable)) {
      return WatchSendResult.unavailable;
    }
    return WatchSendResult.notDelivered;
  }

  @override
  Stream<Map<Object?, Object?>> get incoming {
    final existing = _incoming;
    if (existing != null) return existing;
    final controller = StreamController<Map<Object?, Object?>>.broadcast();
    for (final link in _links) {
      link.incoming.listen(controller.add);
    }
    return _incoming = controller.stream;
  }
}

/// The Garmin link's own calls: choosing the watch in Garmin Connect.
/// Only the iOS Garmin bridge answers them (garmin/ios_runner, opt-in);
/// elsewhere every call is a quiet no.
class GarminLink {
  static const channelName = 'sniper_turk/garmin';

  /// Native → Dart: the number of chosen watches, once on listen and after
  /// every return from Garmin Connect.
  static const devicesChannelName = 'sniper_turk/garmin/devices';

  final MethodChannel _channel;
  final EventChannel _devices;

  GarminLink([MethodChannel? channel, EventChannel? devices])
    : _channel = channel ?? const MethodChannel(channelName),
      _devices = devices ?? const EventChannel(devicesChannelName);

  static GarminLink? _instance;

  /// The app-wide link.
  static GarminLink get instance => _instance ??= GarminLink();

  /// Replaces [instance] (tests only).
  @visibleForTesting
  static set instance(GarminLink link) => _instance = link;

  /// Garmin watches the user shared with the app; null when this build has
  /// no Garmin bridge.
  Future<int?> deviceCount() async {
    try {
      return await _channel.invokeMethod<int>('deviceCount');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// The chosen-watch count whenever it changes (Garmin Connect returned a
  /// new selection). Empty without a Garmin bridge; native errors end it.
  Stream<int> get deviceCountChanges async* {
    // Without a bridge EventChannel would report the missing plugin as a
    // Flutter error instead of an exception; ask the method channel first.
    if (await deviceCount() == null) return;
    try {
      await for (final value in _devices.receiveBroadcastStream()) {
        if (value is int) yield value;
      }
    } on MissingPluginException {
      // No bridge: the stream simply ends.
    } on PlatformException {
      // Native error: the stream ends; the tile still refreshes on resume.
    }
  }

  /// Opens Garmin Connect to pick the watch. False without a bridge.
  Future<bool> selectDevice() async {
    try {
      return await _channel.invokeMethod<bool>('selectDevice') == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// Sends the shot solution to a watch and receives the watch's distance and
/// shot angle requests. Without a watch (or without the native side) it
/// silently does nothing: no exception, no retry storm.
class WatchBridge {
  /// The same content is sent again after this long, so a watch that marks
  /// data older than 2 minutes as stale never does so while Atış is open
  /// and unchanged. It also limits retries when no watch is paired.
  static const refreshAfter = Duration(seconds: 60);

  final WatchTransport _transport;
  final int maxRange;
  final DateTime Function() _clock;

  bool _available = true;
  Map<String, Object>? _lastKey;
  DateTime? _lastAttempt;

  WatchBridge({
    WatchTransport? transport,
    this.maxRange = 100000,
    DateTime Function()? clock,
  }) : _transport =
           transport ??
           MultiWatchTransport([
             MethodChannelWatchTransport(),
             MethodChannelWatchTransport(
               const MethodChannel(GarminLink.channelName),
             ),
           ]),
       _clock = clock ?? DateTime.now;

  static WatchBridge? _instance;

  /// The app-wide bridge.
  static WatchBridge get instance => _instance ??= WatchBridge();

  /// Replaces [instance] (tests only).
  @visibleForTesting
  static set instance(WatchBridge bridge) => _instance = bridge;

  /// False once the native side turned out to be missing.
  bool get available => _available;

  /// Sends [solution] unless the same content was sent (or tried) less
  /// than [refreshAfter] ago.
  Future<void> publish(WatchSolution solution) async {
    if (!_available) return;
    final key = solution.contentKey();
    final now = _clock();
    final last = _lastKey;
    final lastAt = _lastAttempt;
    if (last != null &&
        lastAt != null &&
        mapEquals(last, key) &&
        now.difference(lastAt) < refreshAfter) {
      return;
    }
    _lastKey = key;
    _lastAttempt = now;
    WatchSendResult result;
    try {
      result = await _transport.send(solution.toMessage());
    } catch (_) {
      // A watch must never break the phone app.
      result = WatchSendResult.notDelivered;
    }
    if (result == WatchSendResult.unavailable) _available = false;
  }

  /// Distances (in the profile's display unit) the shooter picked on the
  /// watch. Only whole numbers in 1…[maxRange] pass.
  Stream<int> get rangeRequests => _transport.incoming
      .where((m) => m['type'] == 'setRange')
      .map((m) => m['value'])
      .where((v) => v is int && v >= 1 && v <= maxRange)
      .cast<int>();

  /// Largest shot angle (degrees, either sign) the watch may set.
  static const maxWatchAngleDeg = 60.0;

  /// Shot angles (degrees, + up / − down) the watch's level measured and
  /// the shooter sent ("Açıyı gönder"). Only finite numbers within
  /// ±[maxWatchAngleDeg] pass, rounded to 0.1°.
  Stream<double> get angleRequests => _transport.incoming
      .where((m) => m['type'] == 'setAngle')
      .map((m) => m['value'])
      .where((v) => v is num && v.isFinite && v.abs() <= maxWatchAngleDeg)
      .cast<num>()
      .map((v) {
        final r = (v * 10).roundToDouble() / 10;
        return r == 0 ? 0.0 : r;
      });
}
