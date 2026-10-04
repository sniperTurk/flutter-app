import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/audio_transient_detector.dart';

void main() {
  test('detects separated transients and preserves absolute timestamps', () {
    const rate = 48000;
    final samples = List<double>.filled(4096, 0.001);
    for (var i = 512; i < 768; i++) { samples[i] = 0.5; }
    for (var i = 2560; i < 2816; i++) { samples[i] = 0.35; }
    final events = AudioTransientDetector().process(samples, sampleRate: rate, absoluteStartSample: 1000);
    expect(events.length, 2);
    expect(events.first.sampleIndex, 1512);
    expect(events.last.sampleIndex, 3560);
    expect(events.first.timeSeconds, closeTo(1512 / rate, 1e-12));
  });

  test('quiet noise does not create events', () {
    final events = AudioTransientDetector().process(List<double>.filled(4096, 0.002), sampleRate: 48000);
    expect(events, isEmpty);
  });

  test('rejects malformed PCM and impossible sample rates', () {
    final detector = AudioTransientDetector();
    expect(() => detector.process([double.nan], sampleRate: 48000), throwsArgumentError);
    expect(() => detector.process(List<double>.filled(256, 0), sampleRate: 1000), throwsArgumentError);
  });
}
