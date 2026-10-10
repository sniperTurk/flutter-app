import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/drag_curve.dart';
import '../../core/drag_table.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'profile_field_info.dart';

/// Reads a curve file the user picks; null = cancelled.
typedef DragCurveFileReader = Future<String?> Function();

Future<String?> _pickCurveFile() async {
  const group = XTypeGroup(
    label: 'Sürüklenme eğrisi',
    extensions: ['drg', 'csv', 'txt'],
    // .drg has no system type; iOS needs UTIs, so accept text and data.
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.plain-text',
      'public.text',
      'public.data',
    ],
  );
  final file = await openFile(acceptedTypeGroups: const [group]);
  return file?.readAsString();
}

/// Profil → Mühimmat → BC modeli "Özel eğri (Mach–Cd)": load the bullet's own
/// drag curve from a file or the clipboard, and show it as a small chart.
class DragCurveField extends StatefulWidget {
  final List<DragSample>? curve;
  final ValueChanged<List<DragSample>> onChanged;

  /// Shown under the buttons after a failed save attempt with no curve.
  final String? errorText;

  /// Injected in tests; defaults to the system file picker.
  final DragCurveFileReader? readFile;

  const DragCurveField({
    super.key,
    required this.curve,
    required this.onChanged,
    this.errorText,
    this.readFile,
  });

  @override
  State<DragCurveField> createState() => _DragCurveFieldState();
}

class _DragCurveFieldState extends State<DragCurveField> {
  String? _error;

  void _load(String? text) {
    if (text == null) return;
    try {
      final curve = DragCurve.parse(text);
      setState(() => _error = null);
      widget.onChanged(curve);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _fromFile() async {
    try {
      _load(await (widget.readFile ?? _pickCurveFile)());
    } on Exception {
      setState(() => _error = 'Dosya okunamadı.');
    }
  }

  Future<void> _fromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      setState(() => _error = 'Panoda metin yok. Önce eğriyi kopyalayın.');
      return;
    }
    _load(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final curve = widget.curve;
    final error = _error ?? widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Sürüklenme eğrisi', style: MenzilType.body(c.ink)),
            ),
            const MenzilInfoButton(
              title: 'Sürüklenme eğrisi',
              text: ProfileFieldInfo.dragCurve,
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.xs),
        Row(
          children: [
            Expanded(
              child: MenzilSecondaryButton(
                key: const Key('ammo-curve-file'),
                label: 'Dosyadan yükle',
                icon: Icons.description_outlined,
                expand: true,
                onPressed: _fromFile,
              ),
            ),
            const SizedBox(width: MenzilSpace.sm),
            Expanded(
              child: MenzilSecondaryButton(
                key: const Key('ammo-curve-paste'),
                label: 'Yapıştır',
                icon: Icons.content_paste,
                expand: true,
                onPressed: _fromClipboard,
              ),
            ),
          ],
        ),
        const SizedBox(height: MenzilSpace.xs),
        Text(
          '.drg veya .csv (her satırda Mach ve Cd)',
          style: MenzilType.caption(c.ink2),
        ),
        if (curve != null) ...[
          const SizedBox(height: MenzilSpace.sm),
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomPaint(
              key: const Key('ammo-curve-chart'),
              painter: _CurvePainter(curve, line: c.amber, text: c.ink2),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: MenzilSpace.xs),
          Text(
            '✓ ${curve.length} nokta yüklendi · Mach '
            '${_num(curve.first.mach)}–${_num(curve.last.mach)}',
            key: const Key('ammo-curve-status'),
            style: MenzilType.body(c.ok),
          ),
          Text(
            'Çap ve ağırlık mühimmattan alınır; BC girmeye gerek yok.',
            style: MenzilType.caption(c.ink2),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: MenzilSpace.xs),
          Text(
            error,
            key: const Key('ammo-curve-error'),
            style: MenzilType.caption(c.danger),
          ),
        ],
      ],
    );
  }

  static String _num(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
}

class _CurvePainter extends CustomPainter {
  final List<DragSample> curve;
  final Color line, text;
  _CurvePainter(this.curve, {required this.line, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0, bottom = 18.0;
    final w = size.width - 2 * pad, h = size.height - pad - bottom;
    if (w <= 0 || h <= 0) return;
    final maxMach = curve.last.mach;
    var maxCd = 0.0;
    for (final p in curve) {
      if (p.coefficient > maxCd) maxCd = p.coefficient;
    }
    final path = Path();
    for (var i = 0; i < curve.length; i++) {
      final x = pad + w * curve[i].mach / maxMach;
      final y = pad + h * (1 - curve[i].coefficient / (maxCd * 1.1));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    void label(String s, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(color: text, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at);
    }

    label('Cd', const Offset(4, 2));
    label('Mach 0', Offset(pad, size.height - 14));
    final end = 'Mach ${maxMach.toStringAsFixed(1)}';
    label(end, Offset(size.width - pad - 6 * end.length, size.height - 14));
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.curve != curve || old.line != line || old.text != text;
}
