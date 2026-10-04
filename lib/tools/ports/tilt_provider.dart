enum TiltUnavailableReason { noSensor, error }

/// Raw accelerometer vector in m/s² (device axes, gravity included).
class GravityVector {
  final double x, y, z;
  const GravityVector(this.x, this.y, this.z);
}

sealed class TiltState {
  const TiltState();
}

class TiltAvailable extends TiltState {
  final GravityVector gravity;
  const TiltAvailable(this.gravity);
}

class TiltUnavailable extends TiltState {
  final TiltUnavailableReason reason;
  const TiltUnavailable(this.reason);
}

/// Port for the accelerometer used by Su Terazisi.
abstract interface class TiltProvider {
  Stream<TiltState> tilts();
}
