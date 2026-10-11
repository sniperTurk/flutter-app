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

/// Sends the shot solution to a watch and receives the watch's distance
/// requests. Without a watch (or without the native side) it silently does
/// nothing: no exception, no retry storm.
class WatchBridge {
  final WatchTransport _transport;
  final int maxRange;

  bool _available = true;
  Map<String, Object>? _lastSent;

  WatchBridge({WatchTransport? transport, this.maxRange = 100000})
    : _transport = transport ?? MethodChannelWatchTransport();

  static WatchBridge? _instance;

  /// The app-wide bridge.
  static WatchBridge get instance => _instance ??= WatchBridge();

  /// Replaces [instance] (tests only).
  @visibleForTesting
  static set instance(WatchBridge bridge) => _instance = bridge;

  /// False once the native side turned out to be missing.
  bool get available => _available;

  /// Sends [solution] unless the watch already has the same content.
  Future<void> publish(WatchSolution solution) async {
    if (!_available) return;
    final key = solution.contentKey();
    final last = _lastSent;
    if (last != null && mapEquals(last, key)) return;
    WatchSendResult result;
    try {
      result = await _transport.send(solution.toMessage());
    } catch (_) {
      // A watch must never break the phone app.
      result = WatchSendResult.notDelivered;
    }
    switch (result) {
      case WatchSendResult.sent:
        _lastSent = key;
      case WatchSendResult.notDelivered:
        _lastSent = null;
      case WatchSendResult.unavailable:
        _available = false;
        _lastSent = null;
    }
  }

  /// Distances (in the profile's display unit) the shooter picked on the
  /// watch. Only whole numbers in 1…[maxRange] pass.
  Stream<int> get rangeRequests => _transport.incoming
      .where((m) => m['type'] == 'setRange')
      .map((m) => m['value'])
      .where((v) => v is int && v >= 1 && v <= maxRange)
      .cast<int>();
}
