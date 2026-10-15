/// Result of one phone barometer read (Ö4).
sealed class PressureReading {
  const PressureReading();
}

/// Station pressure measured by the phone, hPa.
class PressureRead extends PressureReading {
  final double hpa;
  const PressureRead(this.hpa);
}

/// Why a read gave no pressure (shown to the user, TestFlight 2026-10-12).
enum PressureFailure {
  /// No barometer, no Motion & Fitness permission or the plugin failed.
  noSensor,

  /// The sensor gave no sample before the timeout.
  noSample,

  /// Samples came, but none was a plausible station pressure.
  outOfRange,
}

/// No barometer, no permission, no sample in time or an invalid value.
class PressureUnavailable extends PressureReading {
  final PressureFailure reason;

  /// The last implausible sample (as received), for [PressureFailure.outOfRange].
  final double? lastValue;
  const PressureUnavailable([
    this.reason = PressureFailure.noSensor,
    this.lastValue,
  ]);
}

/// Port for the phone barometer. Implementations read ONLY when [read] is
/// called (owner rule: nothing is read before the button is pressed).
abstract interface class PressureSensor {
  Future<PressureReading> read();
}
