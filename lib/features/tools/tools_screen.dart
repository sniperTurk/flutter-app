import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'calculators_screen.dart';
import 'chronograph_screen.dart';
import 'compass_screen.dart';
import 'hit_probability_screen.dart';
import 'level_screen.dart';
import 'map_distance_screen.dart';
import 'sight_height_screen.dart';
import 'truing_screen.dart';
import 'weather_screen.dart';

/// Tool hub (Kronograf, Hız Doğrulama, Sight Height, Haritadan mesafe, Hava & Rüzgâr,
/// Pusula, Su Terazisi, Vuruş Olasılığı, Hesaplayıcılar). Katalog is no
/// longer listed here (owner, 2026-10-08); its records and screen remain. Visual assistance is NOT a tool of its own; it only
/// appears inside the Sight Height flow.
class ToolsScreen extends StatelessWidget {
  /// Called after any tool route closes. Kronograf, Hız Doğrulama and Sight
  /// Height can write
  /// to a profile; the shell must reload so Atış/Tablo never keep using the
  /// previous muzzle velocity or sight height.
  final Future<void> Function()? onProfilesChanged;

  const ToolsScreen({super.key, this.onProfilesChanged});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await onProfilesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilPage(
      children: [
        MenzilToolTile(
          tileKey: const Key('tool-chronograph'),
          icon: Icons.speed_outlined,
          title: 'Kronograf',
          subtitle: 'Hız serisi: ortalama, SD ve ES; profile aktarım',
          onTap: () => _open(context, const ChronographScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-truing'),
          icon: Icons.tune,
          title: 'Hız Doğrulama',
          subtitle: 'Sahada gözlenen düşümle namlu hızını doğrula; profile aktarım',
          onTap: () => _open(context, const TruingScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-sight-height'),
          icon: Icons.height,
          title: 'Sight Height',
          subtitle: 'Dürbün eksen yüksekliği: fiziksel ölçüm veya yan fotoğraf',
          onTap: () => _open(context, const SightHeightScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-map-distance'),
          icon: Icons.map_outlined,
          title: 'Haritadan mesafe',
          subtitle: 'Uydu haritasında nişancı ve hedef konumu, mesafe ve yön',
          onTap: () => _open(context, const MapDistanceScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-weather'),
          icon: Icons.air,
          title: 'Hava & Rüzgâr',
          subtitle: 'Konuma göre servis verisi: rüzgâr, sıcaklık, nem, basınç',
          onTap: () => _open(context, const WeatherScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-compass'),
          icon: Icons.explore_outlined,
          title: 'Pusula',
          subtitle: '360° kadran, derece ve yön',
          onTap: () => _open(context, const CompassScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-level'),
          icon: Icons.straighten,
          title: 'Su Terazisi',
          subtitle: 'Dairesel gösterge, X/Y eğim',
          onTap: () => _open(context, const LevelScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-hit-probability'),
          icon: Icons.track_changes_outlined,
          title: 'Vuruş Olasılığı',
          subtitle: 'Grup ve hedef çapından tek atış vuruş yüzdesi',
          onTap: () => _open(context, const HitProbabilityScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-calculators'),
          icon: Icons.calculate_outlined,
          title: 'Hesaplayıcılar',
          subtitle:
              'Mesafe, MOA, tık doğrulama, BC, hava laboratuvarı, birim dönüştürücüler',
          onTap: () => _open(context, const CalculatorsScreen()),
        ),
        const SizedBox(height: MenzilSpace.md),
        Center(
          child: Text('SNIPER TÜRK • V1', style: MenzilType.caption(c.ink2)),
        ),
      ],
    );
  }
}
