import 'package:flutter/material.dart';

import 'data/catalog_repository.dart';
import 'features/home/home_screen.dart';
import 'services/app_settings.dart';
import 'tools/tools_services.dart';
import 'ui/menzil_theme.dart';

void main() {
  final catalogIssues = CatalogRepository.bundledIntegrityIssues();
  runApp(
    catalogIssues.isEmpty
        ? const SniperTurkApp()
        : CatalogStartupErrorApp(issues: catalogIssues.map((e) => e.toString()).toList(growable: false)),
  );
}

class SniperTurkApp extends StatefulWidget {
  const SniperTurkApp({super.key});

  @override
  State<SniperTurkApp> createState() => _SniperTurkAppState();
}

class _SniperTurkAppState extends State<SniperTurkApp> {
  final MenzilThemeController themeMode = MenzilThemeController();
  final ThemeData lightTheme = MenzilTheme.light();
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
    themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSettingsScope(
        settings: appSettings,
        child: ToolsServicesScope(
          services: toolsServices,
          child: MenzilThemeScope(
            controller: themeMode,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeMode,
              builder: (context, mode, _) => MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'SNIPER TÜRK',
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: mode,
                home: const HomeScreen(),
              ),
            ),
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
                  const Text('Katalog yüklenemedi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Uygulama paketindeki katalog verisi doğrulanamadı. Veri kullanan ekranlar güvenli şekilde durduruldu.'),
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
