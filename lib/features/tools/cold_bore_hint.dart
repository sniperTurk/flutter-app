import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../services/shot_journal_store.dart';
import '../../tools/domain/cold_bore.dart';
import '../../ui/menzil_theme.dart';
import 'tool_support.dart';

/// Shared wording of a cold-bore suggestion.
abstract final class ColdBoreFormat {
  static List<ColdBoreShot> shots(Iterable<ShotRecord> records) => [
    for (final r in records)
      ColdBoreShot(
        rangeM: r.rangeM,
        missUpCm: r.missUpCm,
        missRightCm: r.missRightCm,
        firstShot: r.firstShot,
        suppressor: r.suppressor,
      ),
  ];

  static String state(bool suppressor) =>
      suppressor ? 'susturucu takılı' : 'susturucusuz';

  /// Only the axes whose mean is clear of its uncertainty, e.g.
  /// "0,20 MRAD aşağı, 0,05 MRAD sol"; null when none is.
  static String? correction(ColdBoreSummary s, AngularUnit unit) {
    final parts = <String>[];
    void axis(double? mean, double? se, String plus, String minus) {
      if (mean == null || se == null) return;
      if (mean.abs() <= 1e-12 || mean.abs() < ColdBore.significance * se) {
        return;
      }
      // The correction is against the mean miss.
      final v = unit.fromMrad(-mean);
      parts.add(
        '${ToolFormat.dec(v.abs(), 2)} ${unit.label} ${v > 0 ? plus : minus}',
      );
    }

    axis(s.meanUpMrad, s.seUpMrad, 'yukarı', 'aşağı');
    axis(s.meanRightMrad, s.seRightMrad, 'sağ', 'sol');
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// Hedef: one line per approved cold-bore suggestion of [profileId]. It is
/// advice for the first shot only and is never added to the turret
/// values. It disappears when the records no longer support it.
class ColdBoreHint extends StatefulWidget {
  final String profileId;
  final AngularUnit unit;
  const ColdBoreHint({super.key, required this.profileId, required this.unit});

  @override
  State<ColdBoreHint> createState() => _ColdBoreHintState();
}

class _ColdBoreHintState extends State<ColdBoreHint> {
  List<String> _lines = const [];

  @override
  void initState() {
    super.initState();
    ShotJournalStore.changes.addListener(_reload);
    _reload();
  }

  @override
  void didUpdateWidget(covariant ColdBoreHint old) {
    super.didUpdateWidget(old);
    if (old.profileId != widget.profileId || old.unit != widget.unit) {
      _reload();
    }
  }

  @override
  void dispose() {
    ShotJournalStore.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() => unawaited(_load());

  Future<void> _load() async {
    const store = ShotJournalStore();
    final lines = <String>[];
    try {
      final records = await store.load(profileId: widget.profileId);
      final shots = ColdBoreFormat.shots(records);
      for (final sup in const [false, true]) {
        if (!await store.isApproved(widget.profileId, suppressor: sup)) {
          continue;
        }
        final s = ColdBore.forState(shots, suppressor: sup);
        if (s.verdict != ColdBoreVerdict.suggest) continue;
        final text = ColdBoreFormat.correction(s, widget.unit);
        if (text == null) continue;
        lines.add(
          'Soğuk namlu, ilk atış ${ColdBoreFormat.state(sup)}: $text ek '
          'düzeltme · ${s.firstShots} kayıt.',
        );
      }
    } catch (_) {
      // No storage: no suggestion.
    }
    if (mounted) setState(() => _lines = lines);
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) return const SizedBox.shrink();
    final c = MenzilColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Text(
        _lines.join('\n'),
        key: const Key('cold-bore-hint'),
        style: MenzilType.body(c.ink),
      ),
    );
  }
}
