import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../services/shot_journal_store.dart';
import '../../tools/domain/cold_bore.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'cold_bore_hint.dart';
import 'tool_support.dart';

/// ⓘ texts of the Atış Günlüğü page (owner rule: every entered value is
/// explained).
abstract final class ShotJournalFieldInfo {
  static const range =
      'Hedefin mesafesi; telemetreyle ölçün. Farklı mesafelerdeki kayıtlar '
      'açıya çevrilerek birleştirilir. Örnek: 300 m.';
  static const first =
      'Bu atış oturumun ilk atışı mı: soğuk ve temiz namlu, o gün henüz '
      'atılmamış. Soğuk namlu önerisi yalnız ilk atışlardan hesaplanır. '
      'Örnek: sabah ilk atış Evet, ikinci atış Hayır.';
  static const suppressor =
      'Atışta susturucu takılı mıydı. Susturucu vuruş noktasını kaydırır; '
      'iki durumun soğuk namlu ortalaması ayrı tutulur. Örnek: Takılı.';
  static const elevation =
      'Atıştan önce kuleye çevirdiğiniz yükseliş düzeltmesi, profil biriminde '
      '(yukarı artı). Kayıt içindir; hesapta kullanılmaz, boş bırakılabilir. '
      'Örnek: 2,1.';
  static const windage =
      'Atıştan önce kuleye çevirdiğiniz yan düzeltme, profil biriminde (sağ '
      'artı). Kayıt içindir; boş bırakılabilir. Örnek: 0,3.';
  static const missUp =
      'Vuruşun nişan noktasına göre dikey kaçıklığı, cm. Yukarı artı, aşağı '
      'eksi; hedefte ölçün veya dürbünden okuyun. Tam isabet 0. Örnek: 4.';
  static const missRight =
      'Vuruşun nişan noktasına göre yatay kaçıklığı, cm. Sağ artı, sol eksi. '
      'Tam isabet 0. Örnek: -1.';
}

/// Ö9 Atış günlüğü: session records on the phone only, and the cold-bore
/// first-shot suggestion once there are enough records and the shooter
/// approves it. No default is ever made up.
class ShotJournalScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const ShotJournalScreen({
    super.key,
    this.profileStore,
    this.activeProfileStore,
  });

  @override
  State<ShotJournalScreen> createState() => _ShotJournalScreenState();
}

class _ShotJournalScreenState extends State<ShotJournalScreen> {
  static const _store = ShotJournalStore();
  static const _shownRecords = 50;
  static const _signed = TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  );

  final _range = TextEditingController();
  final _elevation = TextEditingController();
  final _windage = TextEditingController();
  final _missUp = TextEditingController();
  final _missRight = TextEditingController();
  bool? _first;
  bool? _suppressor;

  bool _loading = true;
  RifleProfile? _profile;
  List<ShotRecord> _records = const [];
  final Set<bool> _approved = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _range.dispose();
    _elevation.dispose();
    _windage.dispose();
    _missUp.dispose();
    _missRight.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await loadActiveToolProfile(
      widget.profileStore ?? PersistentProfileStore(),
      widget.activeProfileStore ?? PersistentActiveProfileStore(),
    );
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = p != null;
    });
    if (p != null) await _reloadRecords();
  }

  Future<void> _reloadRecords() async {
    final p = _profile!;
    var records = const <ShotRecord>[];
    final approved = <bool>{};
    try {
      records = await _store.load(profileId: p.id);
      for (final sup in const [false, true]) {
        if (await _store.isApproved(p.id, suppressor: sup)) approved.add(sup);
      }
    } catch (_) {
      // No storage: an empty journal.
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _records = records;
      _approved
        ..clear()
        ..addAll(approved);
    });
  }

  static double? _num(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    final p = _profile!;
    final range = _num(_range);
    final up = _num(_missUp);
    final right = _num(_missRight);
    final elevationOk =
        _elevation.text.trim().isEmpty || _num(_elevation) != null;
    final windageOk = _windage.text.trim().isEmpty || _num(_windage) != null;
    if (range == null ||
        range <= 0 ||
        range > 3000 ||
        up == null ||
        right == null ||
        up.abs() > 500 ||
        right.abs() > 500 ||
        _first == null ||
        _suppressor == null ||
        !elevationOk ||
        !windageOk) {
      _snack(
        'Mesafe, İlk atış, Susturucu ve iki kaçıklık gerekli; düzeltmeler '
        'boş ya da sayı olmalı.',
      );
      return;
    }
    final now = DateTime.now();
    final record = ShotRecord(
      id: '${now.microsecondsSinceEpoch}',
      time: now,
      profileId: p.id,
      rangeM: range,
      firstShot: _first!,
      suppressor: _suppressor!,
      missUpCm: up,
      missRightCm: right,
      elevationText: _elevation.text.trim(),
      windageText: _windage.text.trim(),
      unitLabel: p.angularUnit.label,
    );
    try {
      await _store.add(record);
    } catch (_) {
      if (mounted) _snack('Kayıt yapılamadı.');
      return;
    }
    if (!mounted) return;
    // The next shot of the session is not a first shot any more; the
    // range and the suppressor usually stay.
    setState(() {
      _first = null;
      _elevation.clear();
      _windage.clear();
      _missUp.clear();
      _missRight.clear();
    });
    _snack('Kaydedildi.');
    await _reloadRecords();
  }

  Future<bool> _confirm(String title, String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _delete(ShotRecord r) async {
    if (!await _confirm('Kaydı sil', _recordText(r), 'Sil')) return;
    try {
      await _store.delete(r.id);
    } catch (_) {
      if (mounted) _snack('Kayıt silinemedi.');
    }
    await _reloadRecords();
  }

  Future<void> _setApproved(
    bool suppressor,
    bool approved,
    String? text,
  ) async {
    final p = _profile!;
    if (approved &&
        !await _confirm(
          'Soğuk namlu önerisi',
          'Hedef ekranında ilk atış için şu ek düzeltme gösterilecek, '
              '${ColdBoreFormat.state(suppressor)}: $text. Tıklara eklenmez.',
          'Onayla',
        )) {
      return;
    }
    try {
      await _store.setApproved(
        p.id,
        suppressor: suppressor,
        approved: approved,
      );
    } catch (_) {
      if (mounted) _snack('Kaydedilemedi.');
    }
    await _reloadRecords();
  }

  static String _recordText(ShotRecord r) {
    String miss(double v, String plus, String minus) => v == 0
        ? ''
        : '${ToolFormat.dec(v.abs(), 1)} ${v > 0 ? plus : minus}';
    final up = miss(r.missUpCm, 'yukarı', 'aşağı');
    final right = miss(r.missRightCm, 'sağ', 'sol');
    final missText = up.isEmpty && right.isEmpty
        ? 'isabet'
        : '${[up, right].where((s) => s.isNotEmpty).join(', ')} cm';
    return [
      ToolFormat.dateTime(r.time),
      '${ToolFormat.dec(r.rangeM, 0)} m',
      if (r.firstShot) 'İlk atış',
      r.suppressor ? 'Susturucu takılı' : 'Susturucusuz',
      missText,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Atış Günlüğü'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const MenzilStateMessage(
              key: Key('sj-no-profile'),
              icon: Icons.person_outline,
              message: 'Önce Profil sekmesinde bir profil oluşturun.',
            )
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final c = MenzilColors.of(context);
    final p = _profile!;
    final unit = p.angularUnit.label;
    final shots = ColdBoreFormat.shots(_records);
    final summaries = [
      for (final sup in const [false, true])
        ColdBore.forState(shots, suppressor: sup),
    ].where((s) => s.firstShots > 0).toList();
    return MenzilPage(
      children: [
        Text('Profil: ${p.name}', style: MenzilType.body(c.ink2)),
        const SizedBox(height: MenzilSpace.sm),
        MenzilFieldGrid(
          children: [
            MenzilFullWidth(
              child: MenzilInput(
                key: const Key('sj-range'),
                controller: _range,
                label: 'Mesafe',
                unit: 'm',
                info: ShotJournalFieldInfo.range,
              ),
            ),
            MenzilSelect<bool>(
              key: const Key('sj-first'),
              label: 'İlk atış',
              initialValue: _first,
              info: ShotJournalFieldInfo.first,
              items: const [
                DropdownMenuItem(value: true, child: Text('Evet')),
                DropdownMenuItem(value: false, child: Text('Hayır')),
              ],
              onChanged: (v) => setState(() => _first = v),
            ),
            MenzilSelect<bool>(
              key: const Key('sj-suppressor'),
              label: 'Susturucu',
              initialValue: _suppressor,
              info: ShotJournalFieldInfo.suppressor,
              items: const [
                DropdownMenuItem(value: true, child: Text('Takılı')),
                DropdownMenuItem(value: false, child: Text('Takılı değil')),
              ],
              onChanged: (v) => setState(() => _suppressor = v),
            ),
            MenzilInput(
              key: const Key('sj-elevation'),
              controller: _elevation,
              label: 'Verilen yükseliş',
              unit: unit,
              keyboardType: _signed,
              info: ShotJournalFieldInfo.elevation,
            ),
            MenzilInput(
              key: const Key('sj-windage'),
              controller: _windage,
              label: 'Verilen yan',
              unit: unit,
              keyboardType: _signed,
              info: ShotJournalFieldInfo.windage,
            ),
            MenzilInput(
              key: const Key('sj-miss-up'),
              controller: _missUp,
              label: 'Kaçıklık yukarı',
              unit: 'cm',
              keyboardType: _signed,
              info: ShotJournalFieldInfo.missUp,
            ),
            MenzilInput(
              key: const Key('sj-miss-right'),
              controller: _missRight,
              label: 'Kaçıklık sağa',
              unit: 'cm',
              keyboardType: _signed,
              info: ShotJournalFieldInfo.missRight,
            ),
          ],
        ),
        MenzilPrimaryButton(
          key: const Key('sj-save'),
          label: 'Kaydet',
          onPressed: _save,
        ),
        const MenzilSectionHeader(
          'Soğuk namlu',
          padding: EdgeInsets.only(top: MenzilSpace.lg, bottom: MenzilSpace.sm),
        ),
        if (summaries.isEmpty)
          Text(
            'Öneri için bir susturucu durumunda en az '
            '${ColdBore.minFirstShots} ilk atış kaydı gerekir.',
            style: MenzilType.caption(c.ink2),
          ),
        for (final s in summaries) _summaryCard(context, s, p.angularUnit),
        const MenzilSectionHeader(
          'Kayıtlar',
          padding: EdgeInsets.only(top: MenzilSpace.lg, bottom: MenzilSpace.sm),
        ),
        if (_records.isEmpty)
          Text('Henüz kayıt yok.', style: MenzilType.caption(c.ink2)),
        for (final r in _records.take(_shownRecords))
          MenzilCard(
            key: Key('sj-record-${r.id}'),
            margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
            padding: const EdgeInsets.only(left: MenzilSpace.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(_recordText(r), style: MenzilType.body(c.ink)),
                ),
                IconButton(
                  tooltip: 'Kaydı sil',
                  icon: Icon(Icons.close, color: c.danger),
                  onPressed: () => _delete(r),
                ),
              ],
            ),
          ),
        if (_records.length > _shownRecords)
          Text(
            'Son $_shownRecords kayıt gösteriliyor; hesap hepsini kullanır.',
            style: MenzilType.caption(c.ink2),
          ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, ColdBoreSummary s, AngularUnit u) {
    final c = MenzilColors.of(context);
    final state = s.suppressor ? 'Susturucu takılı' : 'Susturucusuz';
    final key = s.suppressor ? 'on' : 'off';
    String mean(double m, double se, String plus, String minus) {
      final v = u.fromMrad(m);
      return '${ToolFormat.dec(v.abs(), 2)} ${v >= 0 ? plus : minus} '
          '± ${ToolFormat.dec(u.fromMrad(se), 2)}';
    }

    final lines = <Widget>[
      Text(
        '$state · ${s.firstShots} ilk atış',
        style: MenzilType.body(c.ink2),
      ),
    ];
    final text = ColdBoreFormat.correction(s, u);
    switch (s.verdict) {
      case ColdBoreVerdict.tooFew:
        lines.add(
          Text(
            'Öneri için en az ${ColdBore.minFirstShots} ilk atış gerekir.',
            style: MenzilType.body(c.ink),
          ),
        );
      case ColdBoreVerdict.notSignificant:
      case ColdBoreVerdict.suggest:
        lines.add(
          Text(
            'Ortalama kaçıklık, ${u.label}: '
            '${mean(s.meanUpMrad!, s.seUpMrad!, 'yukarı', 'aşağı')} · '
            '${mean(s.meanRightMrad!, s.seRightMrad!, 'sağ', 'sol')}',
            style: MenzilType.body(c.ink),
          ),
        );
        if (s.verdict == ColdBoreVerdict.notSignificant || text == null) {
          lines.add(
            Text(
              'Ortalama, belirsizliğinden küçük; öneri yok.',
              style: MenzilType.body(c.ink),
            ),
          );
        } else {
          final approved = _approved.contains(s.suppressor);
          lines
            ..add(
              Text(
                'Öneri: ilk atışta $text ek düzeltme.',
                style: MenzilType.body(c.ink),
              ),
            )
            ..add(const SizedBox(height: MenzilSpace.sm))
            ..add(
              approved
                  ? MenzilSecondaryButton(
                      key: Key('cb-remove-$key'),
                      label: 'Onaylandı, Hedef ekranında · Kaldır',
                      expand: true,
                      onPressed: () => _setApproved(s.suppressor, false, null),
                    )
                  : MenzilSecondaryButton(
                      key: Key('cb-approve-$key'),
                      label: 'Öneriyi onayla',
                      expand: true,
                      onPressed: () => _setApproved(s.suppressor, true, text),
                    ),
            );
        }
    }
    return MenzilCard(
      key: Key('cb-summary-$key'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }
}
