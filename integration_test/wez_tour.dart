// Ö12 / Ö5 screenshot tour body (owner, 2026-10-11), shared by
// integration_test/sim_screens_wez_test.dart (Simulator, real screenshots)
// and test/wez_tour_smoke_test.dart (host check that every step works
// before a scarce macOS run is spent).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/wez.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../test/support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_sim',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_sim',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};
const _profile = RifleProfile(
  id: 'p-sim',
  name: 'Test 308',
  rifleId: 'manual_rifle_sim',
  ammunitionId: 'manual_ammo_sim',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

/// Walks the shot panel; calls [shot] with a name where a screenshot belongs
/// and [log] with the numbers shown (first shot, series, old independent).
Future<void> runWezTour(
  WidgetTester tester, {
  required Future<void> Function(String name) shot,
  required void Function(String line) log,
}) async {
  CatalogRepository.installUserCatalog(
    UserCatalog.fromManualEntries([_rifle, _ammo]),
  );

  Widget app(BallisticsView view) => MaterialApp(
    theme: MenzilTheme.light(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: BallisticsScreen(profile: _profile, view: view),
      ),
    ),
  );

  Future<void> settle() async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 8),
      );
    } on FlutterError {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> type(Key key, String text) async {
    await openProFor(tester, key);
    final field = find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> shots(int n) async {
    await openProFor(tester, const Key('pro-wez-shots'));
    final box = find.descendant(
      of: find.byKey(const Key('pro-wez-shots')),
      matching: find.byType(DropdownButton<int>),
    );
    await tester.ensureVisible(box);
    await settle();
    await tester.tap(box);
    await settle();
    await tester.tap(find.text('$n atış').last);
    await settle();
  }

  /// The shot panel scrolled so the notes under the scope are on screen.
  Future<void> hedef(String name, {Key? focus}) async {
    await tester.pumpWidget(app(BallisticsView.shot));
    await settle();
    final target = find.byKey(focus ?? const Key('shot-wez'));
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await settle();
    }
    await shot(name);
  }

  void logNumbers(String label) {
    final text = find.byKey(const Key('shot-hit-probability'));
    final n = find.byKey(const Key('shot-hit-probability-n'));
    final first = text.evaluate().isEmpty
        ? null
        : tester.widget<Text>(text).data;
    final series = n.evaluate().isEmpty ? null : tester.widget<Text>(n).data;
    final p = first == null
        ? null
        : int.parse(RegExp(r'%(\d+)').firstMatch(first)!.group(1)!) / 100;
    log(
      'SIMNUM:$label first="$first" series="$series" '
      'independent3=${p == null ? '-' : (Wez.atLeastOneHit(p, 3) * 100).round()}',
    );
  }

  await tester.pumpWidget(app(BallisticsView.pro));
  await settle();
  // 600 m, 30 cm target (radius ≈ 0.25 mrad), 4 cm group at 100 m
  // (σ ≈ 0.13 mrad), wind bracket up to 3 m/s (shared wind error).
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('pro-shot-range')),
      matching: find.byType(TextField),
    ),
    '600',
  );
  await tester.pump();
  await type(const Key('pro-group'), '4');
  await type(const Key('pro-target-size'), '30');
  // Rüzgâr düzeltmesi is on Pro Ayarlar (owner, 2026-10-12).
  await type(const Key('pro-wind-max'), '3');

  // Önce: 1 atış, mermi uzunluğu yok (no notice, as on main).
  await hedef('hedef_1atis_uyarisiz');
  logNumbers('1atis');

  // Sonra: 3 atış (ortak rüzgâr hatasıyla), uzun mermi Sg ≈ 1.27.
  await tester.pumpWidget(app(BallisticsView.pro));
  await settle();
  await shots(3);
  await type(const Key('pro-bullet-length'), '38');
  await hedef('hedef_3atis_sg_sinirda');
  logNumbers('3atis');
  await hedef('hedef_sg_uyarisi', focus: const Key('shot-stability-marginal'));
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('shot-stability-marginal')),
      matching: find.byIcon(Icons.info_outline),
    ),
  );
  await settle();
  await shot('sg_bilgi');
  Navigator.of(tester.element(find.byType(AlertDialog))).pop();
  await settle();

  // Sonra: 1000 m, transonik uyarısı; çok uzun mermi Sg < 1.
  await tester.pumpWidget(app(BallisticsView.pro));
  await settle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('pro-shot-range')),
      matching: find.byType(TextField),
    ),
    '1000',
  );
  await tester.pump();
  await type(const Key('pro-bullet-length'), '45');
  await hedef('hedef_1000m_transonik', focus: const Key('shot-transonic'));

  // Atış sayısı açıklaması: kutuda ⓘ yok (owner, 2026-10-16 21:17);
  // Hareketli hedef başlığının ⓘ sayfasında.
  await tester.pumpWidget(app(BallisticsView.pro));
  await settle();
  await openProFor(tester, const Key('pro-wez-shots'));
  final info = find.byKey(const Key('pro-info-target'));
  await tester.ensureVisible(info);
  await settle();
  await tester.tap(info);
  await settle();
  await shot('atis_sayisi_bilgi');
}
