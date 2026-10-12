import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../ports/pressure_sensor.dart';

/// Production [PressureSensor]: the phone barometer through `sensors_plus`.
///
/// On iOS the plugin reads Core Motion `CMAltimeter`
/// (`CMAltitudeData.pressure`, kPa, reported here in hPa). The stream is
/// subscribed only inside [read], the first plausible sample is taken and
/// the subscription is cancelled at once, so the sensor runs for well under
/// a second and never in the background.
class SensorsPlusPressureSensor implements PressureSensor {
  /// Plausible station pressure (hPa); the solver accepts 300–1100.
  static const double minHpa = 300, maxHpa = 1100;

  /// Injected in tests; null = the plugin's barometer stream.
  final Stream<BarometerEvent> Function()? source;
  final Duration timeout;

  const SensorsPlusPressureSensor({
    this.source,
    this.timeout = const Duration(seconds: 5),
  });

  /// hPa from a raw sample. A plugin build reporting kPa (Core Motion's own
  /// unit, ~101) is scaled by 10; anything else must already be hPa.
  static double? toHpa(double raw) {
    if (!raw.isFinite) return null;
    final hpa = raw >= minHpa / 10 && raw <= maxHpa / 10 ? raw * 10 : raw;
    return hpa >= minHpa && hpa <= maxHpa ? hpa : null;
  }

  @override
  Future<PressureReading> read() async {
    final done = Completer<PressureReading>();
    StreamSubscription<BarometerEvent>? sub;
    Timer? timer;
    double? lastBad;
    void finish(PressureReading r) {
      if (done.isCompleted) return;
      done.complete(r);
      timer?.cancel();
      // Stop the sensor on every path: sample, error, end or timeout.
      unawaited(sub?.cancel());
    }

    try {
      final events = source?.call() ?? barometerEventStream();
      PressureUnavailable silent() => lastBad == null
          ? const PressureUnavailable(PressureFailure.noSample)
          : PressureUnavailable(PressureFailure.outOfRange, lastBad);
      timer = Timer(timeout, () => finish(silent()));
      sub = events.listen(
        (e) {
          final hpa = toHpa(e.pressure);
          if (hpa != null) {
            finish(PressureRead(hpa));
          } else {
            lastBad = e.pressure;
          }
        },
        // No barometer (older device), permission refused: "okunamadı".
        onError: (Object _) => finish(const PressureUnavailable()),
        onDone: () =>
            finish(lastBad == null ? const PressureUnavailable() : silent()),
        cancelOnError: true,
      );
      if (done.isCompleted) unawaited(sub.cancel());
    } catch (_) {
      // Plugin missing (simulator, tests): "okunamadı".
      finish(const PressureUnavailable());
    }
    return done.future;
  }
}
