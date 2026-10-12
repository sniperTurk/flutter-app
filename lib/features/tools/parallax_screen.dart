import 'package:flutter/material.dart';

import '../../core/parallax_range.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/parallax_table_store.dart';
import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// ⓘ texts of the Paralaks Mesafesi page (owner rule, 2026-10-07).
abstract final class ParallaxFieldInfo {
  static const mark =
      'Paralaks tekerleğinde okuduğunuz işaret: üstündeki rakam veya '
      'baştan saydığınız çentik. Hedef net ve göz oynatınca artı kaymıyorsa '
      'okuyun. Örnek: 4.';
  static const distance =
      'Bu işaretteki gerçek mesafe. Telemetre veya şerit metreyle ölçün; '
      'tekerlekteki rakam çoğu zaman tam tutmaz. Örnek: 25 m.';
  static const pick =
      'Sahada hedefi netleştirdiğiniz işaret. Liste kayıtlı işaretleri ve '
      'iki işaretin ortasını içerir; mesafe aradaki kayıtlardan hesaplanır, '
      'kayıtların dışına çıkmaz. Örnek: 5.';
}

/// Ö8 Paralaks Mesafesi (PCP): the shooter records the side-focus wheel
/// mark at known distances; in the field a mark is picked and the distance
/// is interpolated ([ParallaxRange]). With [returnDistance] (opened from
/// Pro > Atış mesafesi) the picked distance is returned in metres.
class ParallaxScreen extends StatefulWidget {
  final RifleProfile? profile;
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  final bool returnDistance;

  const ParallaxScreen({
    super.key,
    this.profile,
    this.profileStore,
    this.activeProfileStore,
    this.returnDistance = false,
  });

  @override
  State<ParallaxScreen> createState() => _ParallaxScreenState();
}

class _ParallaxScreenState extends State<ParallaxScreen> {
  static const _store = ParallaxTableStore();

  /// Largest distance accepted, in the profile's unit.
  static const _maxShown = 300.0;

  final _mark = TextEditingController();
  final _distance = TextEditingController();

  bool _loading = true;
  RifleProfile? _profile;
  List<ParallaxPoint> _points = const [];
  double? _picked;
  String? _markError, _distanceError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mark.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var p = widget.profile;
    if (p == null) {
      try {
        final active = widget.activeProfileStore ??
            PersistentActiveProfileStore();
        final id = await active.getActiveProfileId();
        if (id != null) {
          final all = await (widget.profileStore ?? PersistentProfileStore())
              .all();
          for (final x in all) {
            if (x.id == id) p = x;
          }
        }
      } catch (_) {
        p = null;
      }
    }
    var points = const <ParallaxPoint>[];
    if (p != null) {
      try {
        points = await _store.load(p.id);
      } catch (_) {
        // No storage: the table starts empty.
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = p;
      _points = points;
    });
  }

  DistanceUnit get _unit => _profile?.distanceUnit ?? DistanceUnit.meter;

  static double? _parse(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  /// "15", "12,5", "12,75".
  static String _fmt(double v) {
    var s = v.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s.replaceAll('.', ',');
  }

  Future<void> _persist(List<ParallaxPoint> points) async {
    final p = _profile;
    if (p == null) return;
    setState(() {
      _points = points;
      if (_picked != null && !ParallaxRange.pickMarks(points).contains(_picked)) {
        _picked = null;
      }
    });
    try {
      await _store.save(p.id, points);
    } catch (_) {
      // Kept in memory for this visit.
    }
  }

  Future<void> _save() async {
    final mark = _parse(_mark.text);
    final shown = _parse(_distance.text);
    final unit = _unit.symbol;
    setState(() {
      _markError = mark == null || mark.abs() > 10000
          ? 'Tekerlekteki işareti sayı olarak girin.'
          : null;
      _distanceError = shown == null || shown < 1 || shown > _maxShown
          ? 'Mesafe 1 ile ${_maxShown.toStringAsFixed(0)} $unit arasında olmalı.'
          : null;
    });
    if (_markError != null || _distanceError != null) return;
    await _persist(
      ParallaxRange.upsert(
        _points,
        ParallaxPoint(mark: mark!, distanceM: _unit.toMeters(shown!)),
      ),
    );
    _mark.clear();
    _distance.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final p = _profile;
    final unit = _unit.symbol;
    final marks = ParallaxRange.pickMarks(_points);
    final picked = _picked;
    final distanceM = picked == null
        ? null
        : ParallaxRange.distanceAt(_points, picked);
    String shown(double m) => _unit.fromMeters(m).round().toString();

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Paralaks Mesafesi'),
      body: MenzilPage(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(MenzilSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p == null)
            const MenzilNotice(
              key: Key('parallax-no-profile'),
              tone: MenzilNoticeTone.warning,
              message: 'Aktif profil yok. Önce Profil sekmesinde bir profil seçin.',
            )
          else ...[
            const MenzilSectionHeader(
              '1 · Kayıtlı işaretler',
              padding: EdgeInsets.only(bottom: MenzilSpace.sm),
            ),
            MenzilCard(
              margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _points.length; i++)
                    Row(
                      key: Key('parallax-row-$i'),
                      children: [
                        Expanded(
                          child: Text(
                            'İşaret ${_fmt(_points[i].mark)}',
                            style: MenzilType.body(c.ink),
                          ),
                        ),
                        Text(
                          '${shown(_points[i].distanceM)} $unit',
                          style: MenzilType.body(c.ink),
                        ),
                        IconButton(
                          key: Key('parallax-del-$i'),
                          tooltip: 'Sil',
                          icon: Icon(Icons.close, color: c.danger),
                          onPressed: () => _persist([..._points]..removeAt(i)),
                        ),
                      ],
                    ),
                  if (_points.isNotEmpty)
                    const SizedBox(height: MenzilSpace.sm),
                  MenzilFieldGrid(
                    children: [
                      MenzilInput(
                        key: const Key('parallax-mark'),
                        controller: _mark,
                        label: 'İşaret',
                        info: ParallaxFieldInfo.mark,
                        errorText: _markError,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                      MenzilInput(
                        key: const Key('parallax-distance'),
                        controller: _distance,
                        label: 'Mesafe',
                        unit: unit,
                        info: ParallaxFieldInfo.distance,
                        errorText: _distanceError,
                      ),
                    ],
                  ),
                  MenzilPrimaryButton(
                    key: const Key('parallax-save'),
                    label: 'İşareti kaydet',
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            const MenzilSectionHeader(
              '2 · Sahada',
              padding: EdgeInsets.only(
                top: MenzilSpace.md,
                bottom: MenzilSpace.sm,
              ),
            ),
            if (marks.isEmpty)
              const MenzilNotice(
                key: Key('parallax-need-two'),
                message: 'Mesafe için en az 2 işaret kaydedin.',
              )
            else ...[
              KeyedSubtree(
                key: ValueKey('pick-${marks.join('|')}'),
                child: MenzilSelect<double>(
                  key: const Key('parallax-pick'),
                  label: 'Tekerlek işareti',
                  info: ParallaxFieldInfo.pick,
                  initialValue: picked,
                  items: [
                    for (final m in marks)
                      DropdownMenuItem(value: m, child: Text(_fmt(m))),
                  ],
                  onChanged: (v) => setState(() => _picked = v),
                ),
              ),
              if (distanceM != null) ...[
                const SizedBox(height: MenzilSpace.sm),
                MenzilMetricGrid(
                  key: const Key('parallax-result'),
                  columns: 2,
                  metrics: [
                    MenzilMetric('Mesafe', shown(distanceM), unit),
                    MenzilMetric(
                      'Kayıtlı aralık',
                      '${shown(_points.map((e) => e.distanceM).reduce((a, b) => a < b ? a : b))}'
                          '–'
                          '${shown(_points.map((e) => e.distanceM).reduce((a, b) => a > b ? a : b))}',
                      unit,
                    ),
                  ],
                ),
                if (widget.returnDistance)
                  MenzilPrimaryButton(
                    key: const Key('parallax-use'),
                    label: 'Atış mesafesine yaz',
                    onPressed: () => Navigator.pop<double>(context, distanceM),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
