import 'package:flutter/widgets.dart';

import 'adapters/camera_plugin_service.dart';
import 'adapters/flutter_compass_heading_provider.dart';
import 'adapters/geolocator_location_provider.dart';
import 'adapters/image_picker_photo_picker.dart';
import 'adapters/met_no_weather_provider.dart';
import 'adapters/sensors_plus_tilt_provider.dart';
import 'ports/camera_service.dart';
import 'ports/clock.dart';
import 'ports/heading_provider.dart';
import 'ports/location_provider.dart';
import 'ports/photo_picker.dart';
import 'ports/tilt_provider.dart';
import 'ports/vision_assist.dart';
import 'ports/weather_provider.dart';

/// Every platform/service dependency of the tool screens, behind ports.
/// Production wiring lives ONLY here; widget tests inject fakes through
/// [ToolsServicesScope]. No demo or fake data exists in `lib/`.
class ToolsServices {
  final LocationProvider location;
  final WeatherProvider weather;
  final HeadingProvider heading;
  final TiltProvider tilt;
  final CameraService camera;
  final PhotoPicker photoPicker;
  final VisionAssist vision;
  final Clock clock;

  const ToolsServices({
    required this.location,
    required this.weather,
    required this.heading,
    required this.tilt,
    required this.camera,
    required this.photoPicker,
    required this.vision,
    required this.clock,
  });

  factory ToolsServices.production() => ToolsServices(
        location: const GeolocatorLocationProvider(),
        weather: MetNoWeatherProvider(),
        heading: const FlutterCompassHeadingProvider(),
        tilt: const SensorsPlusTiltProvider(),
        camera: const CameraPluginService(),
        photoPicker: const ImagePickerPhotoPicker(),
        vision: const DisconnectedVisionAssist(),
        clock: const SystemClock(),
      );
}

class ToolsServicesScope extends InheritedWidget {
  final ToolsServices services;
  const ToolsServicesScope({super.key, required this.services, required super.child});

  static ToolsServices? _fallback;

  /// The installed services, or the production wiring when no scope exists.
  static ToolsServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ToolsServicesScope>();
    return scope?.services ?? (_fallback ??= ToolsServices.production());
  }

  @override
  bool updateShouldNotify(ToolsServicesScope oldWidget) => services != oldWidget.services;
}
