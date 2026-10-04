import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/audio_transient_detector.dart';

void main() {
  test('preserves a transient split across microphone chunks', () {
    final stream = StreamingAudioTransientDetector(
      detector: AudioTransientDetector(
        config: const AudioTransientDetectorConfig(windowSamples: 16, minimumRms: 0.04),
      ),
    );
    final first = List<double>.filled(10, 0.001);
    final second = <double>[...List<double>.filled(2, 0.001), ...List<double>.filled(4, 0.8), ...List<double>.filled(10, 0.001)];
    expect(stream.processChunk(first, sampleRate: 48000, absoluteStartSample: 0), isEmpty);
    final events = stream.processChunk(second, sampleRate: 48000, absoluteStartSample: 10);
    expect(events, hasLength(1));
    expect(events.single.sampleIndex, inInclusiveRange(12, 15));
  });

  test('rejects gaps instead of silently corrupting timing', () {
    final stream = StreamingAudioTransientDetector(
      detector: AudioTransientDetector(config: const AudioTransientDetectorConfig(windowSamples: 16)),
    );
    stream.processChunk(List<double>.filled(8, 0), sampleRate: 48000, absoluteStartSample: 100);
    expect(
      () => stream.processChunk(List<double>.filled(8, 0), sampleRate: 48000, absoluteStartSample: 109),
      throwsStateError,
    );
  });

  test('rejects sample-rate changes within one stream', () {
    final stream = StreamingAudioTransientDetector(
      detector: AudioTransientDetector(config: const AudioTransientDetectorConfig(windowSamples: 16)),
    );
    stream.processChunk(List<double>.filled(8, 0), sampleRate: 48000, absoluteStartSample: 0);
    expect(
      () => stream.processChunk(List<double>.filled(8, 0), sampleRate: 44100, absoluteStartSample: 8),
      throwsStateError,
    );
  });
}
