// Test-only doubles for the tool ports. They live under test/ on purpose:
// production code (lib/) contains no fake, demo or mock data.
import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sniper_turk/tools/ports/camera_service.dart';
import 'package:sniper_turk/tools/ports/photo_picker.dart';
import 'package:sniper_turk/tools/ports/place_search.dart';
import 'package:sniper_turk/tools/ports/clock.dart';
import 'package:sniper_turk/tools/ports/heading_provider.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';
import 'package:sniper_turk/tools/ports/vision_assist.dart';
import 'package:sniper_turk/tools/ports/weather_provider.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

class TestClock implements Clock {
  DateTime current;
  TestClock(this.current);
  @override
  DateTime now() => current;
}

class TestLocation implements LocationProvider {
  LocationResult result;
  int settingsOpened = 0;
  TestLocation(this.result);
  @override
  Future<LocationResult> current() async => result;
  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class TestWeather implements WeatherProvider {
  Object? outcome; // WeatherObservation or WeatherFailure
  Completer<WeatherObservation>? hold;
  int calls = 0;
  TestWeather(this.outcome);
  @override
  String get sourceName => 'Test servisi';
  @override
  Future<WeatherObservation> fetch(double latitude, double longitude) async {
    calls++;
    if (hold != null) return hold!.future;
    final o = outcome;
    if (o is WeatherFailure) throw o;
    return o! as WeatherObservation;
  }
}

class TestHeading implements HeadingProvider {
  final StreamController<HeadingState> controller =
      StreamController<HeadingState>.broadcast();
  @override
  Stream<HeadingState> headings() => controller.stream;
}

class TestTilt implements TiltProvider {
  final StreamController<TiltState> controller =
      StreamController<TiltState>.broadcast();
  @override
  Stream<TiltState> tilts() => controller.stream;
}

class TestCamera implements CameraService {
  CameraUnavailable? failure;

  /// Any other error thrown by [open] (not a [CameraUnavailable]).
  Object? error;

  /// When set, [open] waits for it before returning/throwing.
  Completer<void>? hold;
  int opened = 0;
  int disposed = 0;
  TestCamera({this.failure, this.error});
  @override
  Future<CameraSession> open() async {
    opened++;
    if (hold != null) await hold!.future;
    if (failure != null) throw failure!;
    if (error != null) throw error!;
    return _Session(this);
  }

  @override
  Future<bool> openSettings() async => true;
}

class _Session implements CameraSession {
  final TestCamera owner;
  _Session(this.owner);
  @override
  Widget buildPreview(BuildContext context) =>
      const ColoredBox(color: Colors.black);
  @override
  Future<Uint8List> capture() async => Uint8List(0);
  @override
  Future<void> dispose() async {
    owner.disposed++;
  }
}

/// Gallery double: returns [photo], or throws [failure], or null (cancel).
class TestPhotoPicker implements PhotoPicker {
  final Uint8List? photo;
  final PhotoPickFailure? failure;
  int calls = 0;
  TestPhotoPicker({this.photo, this.failure});
  @override
  Future<Uint8List?> pickPhoto() async {
    calls++;
    if (failure != null) throw failure!;
    return photo;
  }
}

class TestPlaceSearch implements PlaceSearch {
  List<PlaceResult> results;
  PlaceSearchFailure? failure;
  final List<String> queries = [];
  TestPlaceSearch([this.results = const []]);
  @override
  String get sourceName => 'Test servisi';
  @override
  Future<List<PlaceResult>> search(String query) async {
    queries.add(query);
    if (failure != null) throw failure!;
    return results;
  }
}

ToolsServices testServices({
  LocationProvider? location,
  WeatherProvider? weather,
  HeadingProvider? heading,
  TiltProvider? tilt,
  CameraService? camera,
  PhotoPicker? photoPicker,
  PlaceSearch? places,
  Clock? clock,
}) => ToolsServices(
  location: location ?? TestLocation(const LocationFix(39.9, 32.8)),
  weather:
      weather ??
      TestWeather(const WeatherFailure(WeatherFailureKind.offline, 'x')),
  heading: heading ?? TestHeading(),
  tilt: tilt ?? TestTilt(),
  camera: camera ?? TestCamera(),
  photoPicker: photoPicker ?? TestPhotoPicker(),
  places: places ?? TestPlaceSearch(),
  vision: const DisconnectedVisionAssist(),
  clock: clock ?? TestClock(DateTime.utc(2026, 10, 3, 12)),
);

Widget host(Widget child, {ToolsServices? services, double textScale = 1.0}) =>
    MaterialApp(
      theme: MenzilTheme.light(),
      // The scope sits ABOVE the Navigator so pushed routes (camera capture,
      // marking page, dialogs) see the injected fakes, as in lib/main.dart.
      builder: (context, c) => ToolsServicesScope(
        services: services ?? testServices(),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: child,
    );

WeatherObservation observation({
  required DateTime fetchedAt,
  double windSpeedMps = 5.0,
  double windFromDeg = 270,
}) => WeatherObservation(
  temperatureC: 18.5,
  humidityPercent: 55,
  pressureHpa: 1012.3,
  pressureKind: PressureKind.seaLevel,
  windSpeedMps: windSpeedMps,
  windFromDeg: windFromDeg,
  conditionCode: 'partlycloudy_day',
  validAt: fetchedAt,
  fetchedAt: fetchedAt,
  sourceName: 'Test servisi',
);
