import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/watch/watch_bridge.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'pro_info_sheet.dart';
import 'pro_row_header.dart';
import 'pro_section_info.dart';

/// Pro Ayarlar row for choosing the Garmin watch in Garmin Connect: the
/// last item after Tüfek düzeltmeleri (owner, 2026-10-16: moved here from
/// Araçlar, "Garmin isteğe bağlı"). Title, ⓘ (bottom sheet like the other
/// Pro ⓘ) and "isteğe bağlı" on the right. Not a setting: no Pro summary
/// counts it and no calculation reads it.
///
/// Shown only when this build carries the iOS Garmin bridge
/// (garmin/ios_runner, wired by tools/configure_ios_garmin_bridge.py). The
/// TestFlight build has no bridge, so the row is not there at all. The
/// count follows the bridge's device events and is also re-read whenever
/// the app resumes.
class GarminPairTile extends StatefulWidget {
  final GarminLink? link;

  const GarminPairTile({super.key, this.link});

  @override
  State<GarminPairTile> createState() => _GarminPairTileState();
}

class _GarminPairTileState extends State<GarminPairTile>
    with WidgetsBindingObserver {
  int? _count;
  StreamSubscription<int>? _changes;

  GarminLink get _link => widget.link ?? GarminLink.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final n = await _link.deviceCount();
    if (!mounted) return;
    if (n != _count) setState(() => _count = n);
    // Only a build with the bridge has device events.
    if (n != null) {
      _changes ??= _link.deviceCountChanges.listen(_onCount);
    }
  }

  void _onCount(int n) {
    if (mounted && n != _count) setState(() => _count = n);
  }

  @override
  Widget build(BuildContext context) {
    final n = _count;
    if (n == null) return const SizedBox.shrink();
    final c = MenzilColors.of(context);
    return MenzilToolTile(
      // White icon on grey-blue, the look it had on Araçlar.
      plainIcon: true,
      tileKey: const Key('tool-garmin'),
      // The same gap as the Pro boxes above it.
      margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
      icon: Icons.watch_outlined,
      title: 'Garmin saati',
      // Its own tap target: opens the explanation, not Garmin Connect.
      // Same ⓘ as the Pro boxes (owner, 2026-10-16): right after the title.
      titleTrailing: proRowInfoButton(
        key: const Key('pro-info-garmin'),
        title: 'Garmin saati',
        onPressed: () => showProInfoSheet(
          context,
          title: 'Garmin saati',
          entries: const [],
          text: ProSectionInfo.garmin,
        ),
      ),
      // Right end, like "Ek mühimmat bilgileri" (owner, 2026-10-15).
      titleEnd: Text(
        'isteğe bağlı',
        key: const Key('pro-garmin-optional'),
        textAlign: TextAlign.end,
        style: MenzilType.caption(c.ink2),
      ),
      subtitle: n == 0
          ? 'Saat seçilmedi: Garmin Connect\'te saatinizi seçin'
          : '$n saat seçili; değiştirmek için dokunun',
      onTap: () => _link.selectDevice(),
    );
  }
}
