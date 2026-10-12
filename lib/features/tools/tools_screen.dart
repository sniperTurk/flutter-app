import 'package:flutter/material.dart';

import '../../models/domain.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import '../guide/usage_guide_screen.dart';
import 'calculators_screen.dart';
import 'chrono_screen.dart';
import 'compass_screen.dart';
import 'hit_probability_screen.dart';
import 'level_screen.dart';
import 'map_distance_screen.dart';
import 'mpbr_screen.dart';
import 'parallax_screen.dart';
import 'preshot_checklist_screen.dart';
import 'shot_journal_screen.dart';
import 'sight_height_screen.dart';
import 'truing_screen.dart';
import 'weather_screen.dart';
import 'zero_group_screen.dart';

/// Tool hub (Hız Doğrulama, Sight Height, Haritadan mesafe, Hava & Rüzgâr,
/// Pusula, Su Terazisi, Vuruş Olasılığı, Paralaks Mesafesi (PCP), Avcı
/// Sıfırı, Hesaplayıcılar, Atış Öncesi Kontrol, Sıfır Grubu, Atış Günlüğü,
/// Kullanım rehberi).
/// Katalog is no
/// longer listed here (owner, 2026-10-08); its records and screen remain.
/// The audio Kronograf was removed from the hub (owner, 2026-10-09); a typed
/// Kronograf (velocity string statistics, PCP string slope, powder
/// coefficient) came back under Hız Doğrulama (Ö3, 2026-10-12). Visual
/// assistance is NOT a tool of its own; it only
/// appears inside the Sight Height flow.
class ToolsScreen extends StatelessWidget {
  /// Called after any tool route closes. Hız Doğrulama and Sight Height can
  /// write
  /// to a profile; the shell must reload so Atış/Tablo never keep using the
  /// previous muzzle velocity or sight height.
  final Future<void> Function()? onProfilesChanged;

  /// Platform of the active profile; Paralaks Mesafesi is listed only for
  /// PCP (owner, 2026-10-12). Null = no profile.
  final WeaponPlatform? activePlatform;

  const ToolsScreen({super.key, this.onProfilesChanged, this.activePlatform});

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
          tileKey: const Key('tool-truing'),
          icon: Icons.tune,
          title: 'Hız Doğrulama',
          subtitle:
              'Sahada gözlenen düşüşle namlu hızı doğrulama; profile aktarım',
          onTap: () => _open(context, const TruingScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-chrono'),
          icon: Icons.speed,
          title: 'Kronograf',
          subtitle: 'Hız serisi: ortalama, SD, ES; profile ve WEZ\'e aktarım',
          onTap: () => _open(context, const ChronoScreen()),
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
          title: 'İsabet Olasılığı',
          subtitle: 'Grup ve hedef çapından tek atış isabet yüzdesi',
          onTap: () => _open(context, const HitProbabilityScreen()),
        ),
        if (activePlatform == WeaponPlatform.pcp)
          MenzilToolTile(
            tileKey: const Key('tool-parallax'),
            icon: Icons.center_focus_strong_outlined,
            title: 'Paralaks Mesafesi',
            subtitle: 'Paralaks tekerleği işaretinden mesafe; işaret kaydı',
            onTap: () => _open(context, const ParallaxScreen()),
          ),
        MenzilToolTile(
          tileKey: const Key('tool-mpbr'),
          icon: Icons.vertical_align_center,
          title: 'Avcı Sıfırı',
          subtitle: 'Hedef bölgede kalan en uzun menzil ve sıfır mesafesi',
          onTap: () => _open(context, const MpbrScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-calculators'),
          icon: Icons.calculate_outlined,
          title: 'Hesaplayıcılar',
          subtitle:
              'Mesafe, MOA, tık doğrulama, BC, hava laboratuvarı, birim dönüştürücüler',
          onTap: () => _open(context, const CalculatorsScreen()),
        ),
        // Ö11, Ö10, Ö9 (2026-10-12): last, so the hub order above stays.
        MenzilToolTile(
          tileKey: const Key('tool-checklist'),
          icon: Icons.checklist,
          title: 'Atış Öncesi Kontrol',
          subtitle:
              'Profil, kule birimi ve turu, paralaks, su terazisi, büyütme',
          onTap: () => _open(context, const PreShotChecklistScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-zero-group'),
          icon: Icons.grid_on,
          title: 'Sıfır Grubu',
          subtitle: 'Vuruşları işaretle: grup merkezi, σ, gereken atış',
          onTap: () => _open(context, const ZeroGroupScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-shot-journal'),
          icon: Icons.menu_book_outlined,
          title: 'Atış Günlüğü',
          subtitle: 'Oturum kaydı ve soğuk namlu ilk atış kaçıklığı',
          onTap: () => _open(context, const ShotJournalScreen()),
        ),
        MenzilToolTile(
          tileKey: const Key('tool-usage-guide'),
          icon: Icons.menu_book_outlined,
          title: 'Kullanım rehberi',
          subtitle: 'Profil, sıfırlama, hava, Hedef, Pro ve Tablo kısaca',
          onTap: () => _open(context, const UsageGuideScreen()),
        ),
        const SizedBox(height: MenzilSpace.md),
        Center(
          child: Text('SNIPER TÜRK • V1', style: MenzilType.caption(c.ink2)),
        ),
      ],
    );
  }
}
