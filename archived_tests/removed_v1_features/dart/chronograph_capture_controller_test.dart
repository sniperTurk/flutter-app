import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/models/measurement.dart';
import 'package:sniper_turk/services/chronograph_audio_source.dart';
import 'package:sniper_turk/services/chronograph_capture_controller.dart';

class FakeAudio implements ChronographAudioSource {
  final c = StreamController<ChronographPcmChunk>.broadcast();
  @override Stream<ChronographPcmChunk> get chunks => c.stream;
  @override Future<void> start() async {
    final x=List<double>.filled(512,0); for(var i=0;i<256;i++) x[i]=0.8;
    c.add(ChronographPcmChunk(monoSamples:x,sampleRate:48000,absoluteStartSample:0));
    final y=List<double>.filled(512,0); for(var i=256;i<512;i++) y[i]=0.8;
    c.add(ChronographPcmChunk(monoSamples:y,sampleRate:48000,absoluteStartSample:24000));
  }
  @override Future<void> stop() async {}
}

void main(){
  test('microphone result can never become valid',() async {
    final controller=ChronographCaptureController(FakeAudio());
    final result=await controller.captureOne(distanceMeters:10,temperatureC:20,timeout:const Duration(seconds:1));
    expect(result.status,isNot(MeasurementStatus.valid));
  });
}
