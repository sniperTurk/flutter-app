import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/watch/watch_bridge.dart';
import '../../ui/menzil_widgets.dart';

/// Araçlar entry for choosing the Garmin watch in Garmin Connect.
///
/// Shown only when this build carries the iOS Garmin bridge
/// (garmin/ios_runner, wired by tools/configure_ios_garmin_bridge.py). The
/// TestFlight build has no bridge, so the tile is not there at all. The
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
    return MenzilToolTile(
      // Araçlar (owner, 2026-10-15): white icon on grey-blue, like every tile.
      plainIcon: true,
      tileKey: const Key('tool-garmin'),
      icon: Icons.watch_outlined,
      title: 'Garmin saati',
      subtitle: n == 0
          ? 'Saat seçilmedi: Garmin Connect\'te saatinizi seçin'
          : '$n saat seçili; değiştirmek için dokunun',
      onTap: () => _link.selectDevice(),
    );
  }
}
