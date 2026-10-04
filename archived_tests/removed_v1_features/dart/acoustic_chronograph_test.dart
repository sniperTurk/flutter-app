import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/acoustic_chronograph.dart';

void main() {
  test('removes sound return time from observed event delta', () {
    const distance = 50.0;
    const temperature = 20.0;
    final c = 331.3 + 0.606 * temperature;
    const projectileFlight = 0.2;
    final observed = projectileFlight + distance / c;
    final result = AcousticChronograph.estimate(distanceMeters: distance, eventDeltaSeconds: observed, temperatureC: temperature);
    expect(result.projectileFlightSeconds, closeTo(projectileFlight, 1e-9));
    expect(result.averageVelocityMps, closeTo(250, 1e-6));
  });

  test('rejects impossible delta shorter than sound return', () {
    expect(() => AcousticChronograph.estimate(distanceMeters: 100, eventDeltaSeconds: 0.1, temperatureC: 20), throwsArgumentError);
  });

  test('rejects non-finite and unsupported environmental input', () {
    expect(() => AcousticChronograph.estimate(distanceMeters: double.nan, eventDeltaSeconds: 1, temperatureC: 20), throwsArgumentError);
    expect(() => AcousticChronograph.estimate(distanceMeters: 10, eventDeltaSeconds: 1, temperatureC: 80), throwsArgumentError);
  });
}
