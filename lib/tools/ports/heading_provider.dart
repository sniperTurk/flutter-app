enum HeadingUnavailableReason {
  /// The device reports no compass sensor.
  noSensor,

  /// The sensor exists but no reading has arrived (yet).
  noData,

  /// Reading failed for another reason (plugin/OS error).
  error,

  /// The provider returned a negative/invalid reference value. Showing it
  /// would display a made-up bearing such as 359°.
  noReference,
}

/// One compass reading in degrees clockwise from the sensor's north
/// reference, normalised to [0, 360).
///
/// Heading from the active provider. The north reference (true vs magnetic)
/// of `flutter_compass` 0.8.1 on iOS is contradictory between its changelog
/// (magnetic) and its source (trueHeading) and is unverified on a device, so
/// callers MUST NOT label this value as true or magnetic north.
class HeadingReading {
  final double degrees;

  /// Estimated accuracy in degrees when the platform provides it.
  final double? accuracyDeg;
  const HeadingReading(this.degrees, {this.accuracyDeg});
}

sealed class HeadingState {
  const HeadingState();
}

class HeadingAvailable extends HeadingState {
  final HeadingReading reading;
  const HeadingAvailable(this.reading);
}

class HeadingUnavailable extends HeadingState {
  final HeadingUnavailableReason reason;
  const HeadingUnavailable(this.reason);
}

/// Port for the compass. Production implementation: adapters/.
abstract interface class HeadingProvider {
  Stream<HeadingState> headings();
}
