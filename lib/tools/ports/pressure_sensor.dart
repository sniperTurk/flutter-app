/// Result of one phone barometer read (Ö4).
sealed class PressureReading {
  const PressureReading();
}

/// Station pressure measured by the phone, hPa.
class PressureRead extends PressureReading {
  final double hpa;
  const PressureRead(this.hpa);
}

/// No barometer, no permission, no sample in time or an invalid value.
class PressureUnavailable extends PressureReading {
  const PressureUnavailable();
}

/// Port for the phone barometer. Implementations read ONLY when [read] is
/// called (owner rule: nothing is read before the button is pressed).
abstract interface class PressureSensor {
  Future<PressureReading> read();
}
