import 'package:flutter/material.dart';

import 'data/catalog_repository.dart';
import 'features/home/home_screen.dart';
import 'services/app_settings.dart';
import 'services/turret_click_sound.dart';
import 'tools/tools_services.dart';
import 'ui/keyboard_done_bar.dart';
import 'ui/menzil_theme.dart';

void main() {
  // Turret click sound (owner, 2026-10-15 23:30). Tests keep the silent
  // default; the players load when the first turret drum is built.
  TurretClickSound.instance = AudioTurretClickSound();
  final catalogIssues = CatalogRepository.bundledIntegrityIssues();
  runApp(
    catalogIssues.isEmpty
        ? const SniperTurkApp()
        : CatalogStartupErrorApp(
            issues: catalogIssues
                .map((e) => e.toString())
                .toList(growable: false),
          ),
  );
}

class SniperTurkApp extends StatefulWidget {
  const SniperTurkApp({super.key});

  @override
  State<SniperTurkApp> createState() => _SniperTurkAppState();
}

class _SniperTurkAppState extends State<SniperTurkApp> {
  /// Always dark (owner, 2026-10-15: "tasarımı koyu renk yapalım"). The
  /// Koyu/Açık button is deleted; the choice may come back on a future
  /// sign-in screen. A choice saved by an older version (key `theme.dark`)
  /// is left in storage untouched and no longer read.
  final ThemeData darkTheme = MenzilTheme.dark();
  final AppSettings appSettings = AppSettings();
  final ToolsServices toolsServices = ToolsServices.production();

  @override
  void initState() {
    super.initState();
    appSettings.load();
  }

  @override
  void dispose() {
    appSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSettingsScope(
    settings: appSettings,
    child: ToolsServicesScope(
      services: toolsServices,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SNIPER TÜRK',
        theme: darkTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        // No data is fetched until the user taps a button (owner,
        // 2026-10-11): Hava Durumu fills only on "Konumdan canlı hava verisi al".
        home: const HomeScreen(),
        // Keyboard (owner, 2026-10-12): a tap outside a box closes it,
        // and a "Bitti" bar sits above the number pad, which has no
        // return key on iOS.
        builder: (context, child) => KeyboardDoneBar(child: child!),
      ),
    ),
  );
}

/// Safe startup fallback. A malformed bundled catalog is a build/data error;
/// showing it explicitly is safer than allowing partially corrupt data to flow
/// into profile creation and later screens.
class CatalogStartupErrorApp extends StatelessWidget {
  final List<String> issues;
  const CatalogStartupErrorApp({super.key, required this.issues});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MenzilTheme.light(),
    darkTheme: MenzilTheme.dark(),
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Katalog yüklenemedi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Uygulama paketindeki katalog verisi doğrulanamadı. Veri kullanan ekranlar güvenli şekilde durduruldu.',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• ${issues[index]}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
