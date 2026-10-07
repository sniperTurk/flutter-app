import 'package:flutter/material.dart';

import '../../services/app_settings.dart';
import '../../services/settings_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool metric = true;
  bool loading = true;
  bool saving = false;
  String? loadError;
  SettingsStore? store;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final opened = await SettingsStore.open();
      final loadedMetric = opened.loadMetric();
      if (!mounted) return;
      setState(() {
        store = opened;
        metric = loadedMetric;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        store = null;
        loading = false;
        loadError = 'Ayarlar yüklenemedi.';
      });
    }
  }

  Future<void> _setMetric(bool value) async {
    final currentStore = store;
    if (currentStore == null || saving) return;
    setState(() => saving = true);
    try {
      await currentStore.saveMetric(value);
      if (!mounted) return;
      AppSettingsScope.maybeOf(context)?.applyMetric(value);
      setState(() => metric = value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Birim ayarı kaydedilemedi. Mevcut ayar korundu.'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Ayarlar'),
      body: loading
          ? Center(
              child: Semantics(
                label: 'Ayarlar yükleniyor',
                liveRegion: true,
                child: const CircularProgressIndicator(),
              ),
            )
          : loadError != null
          ? MenzilStateMessage(
              message: loadError!,
              action: MenzilPrimaryButton(
                label: 'Tekrar dene',
                onPressed: _load,
                expand: false,
              ),
            )
          : MenzilPage(
              children: [
                const MenzilSectionHeader(
                  'Birimler',
                  padding: EdgeInsets.only(bottom: MenzilSpace.sm),
                ),
                MenzilCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: MenzilSpace.xxs,
                  ),
                  child: SwitchListTile(
                    value: metric,
                    onChanged: saving ? null : _setMetric,
                    title: Text(
                      'Balistik birimleri',
                      style: MenzilType.body(
                        c.ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      metric
                          ? 'metre • m/s • joule • hPa'
                          : 'yard • FPS • ft-lb • inHg',
                      style: MenzilType.caption(c.ink2),
                    ),
                    secondary: saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                Text(
                  'Birim değiştiğinde Hava Durumu ve Atış (tek atış ve tablo) profil değerleriyle yeni birimde yeniden başlar.',
                  style: MenzilType.caption(c.ink2),
                ),
              ],
            ),
    );
  }
}
