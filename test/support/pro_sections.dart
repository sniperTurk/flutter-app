// Pro Ayarlar boxes start closed (owner, 2026-10-09): tests open the box a
// field lives in before finding or typing into it.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _sectionOf = <String, String>{
  'shot-incline': 'angle',
  'shot-cant': 'angle',
  'pro-wind-max': 'wind',
  'pro-wind-mid': 'wind',
  'pro-wind-far': 'wind',
  'pro-latitude': 'coriolis',
  'pro-latitude-gps': 'coriolis',
  'pro-latitude-reset': 'coriolis',
  'pro-azimuth-reset': 'coriolis',
  'pro-gravity-reset': 'gravity',
  'pro-wind-max-fill': 'wind',
  'pro-wind-max-reset': 'wind',
  'pro-azimuth': 'coriolis',
  'pro-azimuth-compass': 'coriolis',
  'pro-coriolis-effect': 'coriolis',
  'pro-gravity': 'gravity',
  'pro-gravity-gps': 'gravity',
  'pro-gravity-effect': 'gravity',
  'pro-target-speed': 'target',
  'pro-group': 'target',
  'pro-sd': 'target',
  'pro-target-size': 'target',
  'pro-range-error': 'target',
  'pro-bc-error': 'target',
  'pro-wez-shots': 'target',
  'shot-wez': 'target',
  'pro-turret-scale': 'rifle',
  'pro-zero-up': 'rifle',
  'pro-zero-right': 'rifle',
  'pro-bullet-length': 'rifle',
  // Mühimmat sıcaklığı: Pro > Tüfek düzeltmeleri since 2026-10-16.
  'env-ammo-temp': 'rifle',
  'pro-ammo-temp-row': 'rifle',
  'pro-powder-source': 'rifle',
  'pro-powder-today': 'rifle',
  'pro-tube-pressure': 'rifle',
  'pro-pcp-regulator': 'rifle',
  'pro-pcp-velocity': 'rifle',
};

/// Opens the Pro box that holds the field with [key] when the field is not
/// on screen yet (no-op on other pages).
Future<void> openProFor(WidgetTester tester, Key key) async {
  if (find.byKey(key).evaluate().isNotEmpty) return;
  final k = key is ValueKey<String> ? key.value : null;
  final id = _sectionOf[k];
  if (id == null) return;
  final header = find.byKey(Key('pro-section-$id'));
  if (header.evaluate().isEmpty) return;
  await tester.ensureVisible(header);
  await tester.pumpAndSettle();
  await tapProHeader(tester, header);
}

/// Taps a Pro box header on its title. The header's centre can fall on the
/// ⓘ next to the title (owner, 2026-10-13), which opens the explanation
/// popup instead of the box.
Future<void> tapProHeader(WidgetTester tester, Finder header) async {
  final h = tester.getSize(header).height;
  await tester.tapAt(tester.getTopLeft(header) + Offset(12, h / 2));
  await tester.pumpAndSettle();
}
