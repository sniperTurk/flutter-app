// Host run of the Ö12 / Ö5 screenshot tour (integration_test/wez_tour.dart):
// every step must find its widgets before a scarce macOS Simulator run.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';

import '../integration_test/wez_tour.dart';

void main() {
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('ekran turu her adımı bulur', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final shots = <String>[];
    final logs = <String>[];
    await runWezTour(
      tester,
      shot: (name) async => shots.add(name),
      log: logs.add,
    );
    expect(shots, [
      'hedef_1atis_uyarisiz',
      'hedef_3atis_sg_sinirda',
      'hedef_sg_uyarisi',
      'sg_bilgi',
      'hedef_1000m_transonik',
      'atis_sayisi_bilgi',
    ]);
    // 3 shots with a shared wind error: below the old independent number.
    final three = logs.singleWhere((l) => l.startsWith('SIMNUM:3atis'));
    final series = int.parse(
      RegExp(
        r'series="\d+ atışta en az bir isabet: %(\d+)',
      ).firstMatch(three)!.group(1)!,
    );
    final independent = int.parse(
      RegExp(r'independent3=(\d+)').firstMatch(three)!.group(1)!,
    );
    expect(series, lessThan(independent));
  });
}
