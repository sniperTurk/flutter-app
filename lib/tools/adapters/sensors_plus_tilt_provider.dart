import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../ports/tilt_provider.dart';

/// Production [TiltProvider] backed by `sensors_plus` (accelerometer,
/// gravity included).
class SensorsPlusTiltProvider implements TiltProvider {
  const SensorsPlusTiltProvider();

  @override
  Stream<TiltState> tilts() {
    final Stream<AccelerometerEvent> source;
    try {
      source = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval);
    } catch (_) {
      return Stream<TiltState>.value(const TiltUnavailable(TiltUnavailableReason.error));
    }
    return source.map<TiltState>((e) => TiltAvailable(GravityVector(e.x, e.y, e.z))).transform(
      StreamTransformer<TiltState, TiltState>.fromHandlers(
        handleError: (error, stack, sink) =>
            sink.add(const TiltUnavailable(TiltUnavailableReason.noSensor)),
      ),
    );
  }
}
