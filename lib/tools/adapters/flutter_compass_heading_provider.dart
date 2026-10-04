// dart format off
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../domain/compass_math.dart';
import '../ports/heading_provider.dart';

/// Production [HeadingProvider] backed by `flutter_compass`.
///
/// Reference caveat: the `flutter_compass` changelog says iOS uses magnetic
/// heading by default since 0.4.0, but the 0.8.1 iOS source (checked
/// 2026-10-04) reads `CLHeading.trueHeading` (negative when it cannot be
/// determined). The two sources disagree and neither was verified on a
/// device, so this adapter exposes only an unqualified sensor heading; the UI
/// must not label it true OR magnetic north. Negative values stay invalid and
/// are never normalised into a fake 359° bearing.
class FlutterCompassHeadingProvider implements HeadingProvider {
  const FlutterCompassHeadingProvider();

  @override
  Stream<HeadingState> headings() {
    final Stream<CompassEvent>? events;
    try {
      events = FlutterCompass.events;
    } catch (_) {
      return Stream<HeadingState>.value(const HeadingUnavailable(HeadingUnavailableReason.error));
    }
    if (events == null) {
      return Stream<HeadingState>.value(const HeadingUnavailable(HeadingUnavailableReason.noSensor));
    }
    return events.map<HeadingState>(_toState).transform(
      StreamTransformer<HeadingState, HeadingState>.fromHandlers(
        handleError: (error, stack, sink) =>
            sink.add(const HeadingUnavailable(HeadingUnavailableReason.error)),
      ),
    );
  }

  HeadingState _toState(CompassEvent event) {
    final heading = event.heading;
    // A missing value means "no usable reading right now", not "no sensor":
    // the absence of a sensor is signalled by `FlutterCompass.events == null`.
    if (heading == null) return const HeadingUnavailable(HeadingUnavailableReason.noData);
    if (!heading.isFinite) return const HeadingUnavailable(HeadingUnavailableReason.error);
    if (heading < 0) return const HeadingUnavailable(HeadingUnavailableReason.noReference);
    double? accuracy;
    // Only iOS documents `accuracy` as CLHeading.headingAccuracy (degrees,
    // negative = invalid). Do not interpret it elsewhere.
    final raw = event.accuracy;
    if (defaultTargetPlatform == TargetPlatform.iOS && raw != null && raw.isFinite && raw >= 0) {
      accuracy = raw;
    }
    return HeadingAvailable(HeadingReading(CompassMath.normalize(heading), accuracyDeg: accuracy));
  }
}
