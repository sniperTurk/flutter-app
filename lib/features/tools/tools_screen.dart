import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../catalog/catalog_screen.dart';
import '../settings/settings_screen.dart';
import 'chronograph_screen.dart';
import 'compass_screen.dart';
import 'level_screen.dart';
import 'sight_height_screen.dart';
import 'weather_screen.dart';

/// Tool hub (V1 scope): Kronograf, Sight Height, Pusula, Su Terazisi,
/// Hava & Rüzgâr, Katalog, Ayarlar. Visual assistance is NOT a tool of its own;
/// it only appears inside the Sight Height flow.
class ToolsScreen extends StatelessWidget {
  /// Called after the settings route closes so the shell can refresh the
  /// unit label in the top bar.
  final Future<void> Function()? onSettingsClosed;

  /// Called after any tool route closes. Kronograf and Sight Height can write
  /// to a profile; the shell must reload so Atış/Tablo never keep using the
  /// previous muzzle velocity or sight height.
  final Future<void> Function()? onProfilesChanged;

  const ToolsScreen({super.key, this.onSettingsClosed, this.onProfilesChanged});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    await onProfilesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilPage(
      children: [
        const MenzilSectionHeader(
          'Araçlar',
          subtitle: 'Saha araçları, katalog ve uygulama ayarları',
          padding: EdgeInsets.only(bottom: MenzilSpace.sm),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-chronograph'),
          icon: Icons.speed_outlined,
          title: 'Kronograf',
          subtitle: 'Hız serisi: ortalama, SD ve ES; profile aktarım',
          onTap: () => _open(context, const ChronographScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-sight-height'),
          icon: Icons.height,
          title: 'Sight Height',
          subtitle: 'Dürbün eksen yüksekliği: fiziksel ölçüm veya yan fotoğraf',
          onTap: () => _open(context, const SightHeightScreen()),
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
          tileKey: const Key('tool-weather'),
          icon: Icons.air,
          title: 'Hava & Rüzgâr',
          subtitle: 'Konuma göre servis verisi: rüzgâr, sıcaklık, nem, basınç',
          onTap: () => _open(context, const WeatherScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-catalog'),
          icon: Icons.inventory_2_outlined,
          title: 'Katalog',
          subtitle: 'Tüfek, mühimmat ve dürbün; kaynak bilgileri ve manuel kayıtlar',
          onTap: () => _open(context, const CatalogScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-settings'),
          icon: Icons.settings_outlined,
          title: 'Ayarlar',
          subtitle: 'Birimler ve uygulama tercihleri',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            );
            await onSettingsClosed?.call();
          },
        ),
        const SizedBox(height: MenzilSpace.md),
        Center(
          child: Text('SNIPER TÜRK • V1', style: MenzilType.caption(c.ink2)),
        ),
      ],
    );
  }
}
