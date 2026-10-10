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
  'pro-coriolis-switch': 'coriolis',
  'pro-latitude': 'coriolis',
  'pro-latitude-gps': 'coriolis',
  'pro-azimuth': 'coriolis',
  'pro-azimuth-compass': 'coriolis',
  'pro-coriolis-effect': 'coriolis',
  'pro-gravity-switch': 'gravity',
  'pro-gravity': 'gravity',
  'pro-gravity-gps': 'gravity',
  'pro-gravity-effect': 'gravity',
  'pro-target-speed': 'target',
  'pro-group': 'target',
  'pro-sd': 'target',
  'pro-target-size': 'target',
  'pro-range-error': 'target',
  'pro-bc-error': 'target',
  'shot-wez': 'target',
  'pro-turret-scale': 'rifle',
  'pro-zero-up': 'rifle',
  'pro-zero-right': 'rifle',
  'pro-spin-switch': 'rifle',
  'pro-bullet-length': 'rifle',
  'pro-powder-coef': 'rifle',
  'pro-powder-temp': 'rifle',
  'pro-powder-today': 'rifle',
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
  await tester.tap(header);
  await tester.pumpAndSettle();
}
