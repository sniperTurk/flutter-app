import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_integrity.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('bundled catalog satisfies integrity rules', () {
    final issues = const CatalogIntegrity().validate(
      rifles: CatalogRepository.rifles,
      ammunition: CatalogRepository.ammunition,
      scopes: CatalogRepository.scopes,
    );
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('repository startup guard validates the exact bundled catalog', () {
    final issues = CatalogRepository.bundledIntegrityIssues();
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test(
    'current AirMaks Krait S variants are manufacturer-backed, not generic placeholders',
    () {
      Rifle byId(String id) =>
          CatalogRepository.rifles.singleWhere((e) => e.id == id);
      final kraitS = byId('airmaks-krait-s-635');
      final mk2S = byId('airmaks-krait-mkii-s-635');

      expect(kraitS.magazineCapacity, 14);
      expect(kraitS.barrelLengthMm, 400);
      expect(kraitS.airCapacityCc, 300);
      expect(kraitS.overallLengthMm, 610);
      expect(kraitS.weightKg, 2.5);
      expect(kraitS.plenumCc, 60);
      expect(kraitS.sourceName, 'AirMaks Arms');

      expect(mk2S.magazineCapacity, 12);
      expect(mk2S.barrelLengthMm, 400);
      expect(mk2S.airCapacityCc, 300);
      expect(mk2S.overallLengthMm, 640);
      expect(mk2S.weightKg, 3.13);
      expect(mk2S.plenumCc, 30);
      expect(mk2S.sourceDocument, contains('official product page'));

      expect(
        CatalogRepository.rifles.any((e) => e.id == 'airmaks-krait-635'),
        isFalse,
      );
    },
  );

  test('Krait MKII X HP manufacturer metadata stays variant-specific', () {
    final rifle = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'airmaks-krait-mkii-xhp-635',
    );
    expect(rifle.magazineCapacity, 12);
    expect(rifle.barrelLengthMm, 700);
    expect(rifle.airCapacityCc, 700);
    expect(rifle.overallLengthMm, 940);
    expect(rifle.weightKg, 3.82);
    expect(rifle.plenumCc, 115);
    expect(rifle.sourceDocument, 'AMA Catalog 2026');
  });

  test(
    'Krait PRO catalog variants preserve manufacturer-backed 6.35 metadata',
    () {
      final pro = CatalogRepository.rifles.singleWhere(
        (e) => e.id == 'airmaks-krait-pro-635',
      );
      final proLhp = CatalogRepository.rifles.singleWhere(
        (e) => e.id == 'airmaks-krait-pro-lhp-635',
      );

      expect(pro.magazineCapacity, 14);
      expect(pro.barrelLengthMm, 400);
      expect(pro.airCapacityCc, 300);
      expect(pro.overallLengthMm, 630);
      expect(pro.weightKg, 3.3);
      expect(pro.barrelType, 'choked');

      expect(proLhp.magazineCapacity, 14);
      expect(proLhp.barrelLengthMm, 520);
      expect(proLhp.airCapacityCc, 580);
      expect(proLhp.overallLengthMm, 750);
      expect(proLhp.weightKg, 3.8);
      expect(proLhp.barrelType, 'non-choked');
      expect(proLhp.sourceDocument, 'AMA Catalog 2026');
    },
  );

  test('Caiman 6.35 variants keep only manufacturer-unambiguous metadata', () {
    final caiman = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'airmaks-caiman-635',
    );
    final caimanX = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'airmaks-caiman-x-635',
    );

    expect(caiman.magazineCapacity, 8);
    expect(caiman.barrelLengthMm, 400);
    expect(caiman.barrelType, 'choked');
    expect(caiman.rail, 'Picatinny 20 MOA');
    expect(caiman.moderatorThread, '1/2 UNF');
    expect(caiman.sourceDocument, 'AMA Catalog 2026');

    expect(caimanX.magazineCapacity, 8);
    expect(caimanX.barrelLengthMm, 520);
    expect(caimanX.barrelType, 'choked');
    expect(caimanX.sourceDocument, 'AMA Catalog 2026');
  });

  test(
    'AEA Challenger Pro 6.35 record preserves verified retailer provenance',
    () {
      final rifle = CatalogRepository.rifles.singleWhere(
        (e) => e.id == 'aea-challenger-pro-635',
      );
      expect(rifle.magazineCapacity, 10);
      expect(rifle.barrelLengthMm, 610);
      expect(rifle.airCapacityCc, 350);
      expect(rifle.overallLengthMm, 840);
      expect(rifle.weightKg, 3.72);
      expect(rifle.rail, 'Picatinny/Weaver');
      expect(rifle.sourceName, 'Airgun Armoury');
      expect(rifle.sourceDocument, contains('verified 2026-09-27'));
    },
  );

  test('HATSAN 6.35 flagship PCP metadata matches manufacturer pages', () {
    final sniper = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'hatsan-sniper-long-635',
    );
    final hercules = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'hatsan-hercules-635',
    );
    final blitz = CatalogRepository.rifles.singleWhere(
      (e) => e.id == 'hatsan-blitz-635',
    );

    expect(sniper.model, 'Factor Sniper Long');
    expect(sniper.magazineCapacity, 19);
    expect(sniper.barrelLengthMm, 760);
    expect(sniper.airCapacityCc, 700);
    expect(sniper.overallLengthMm, 1180);
    expect(sniper.weightKg, 5);
    expect(sniper.moderatorThread, '1/2 UNF');
    expect(sniper.sourceName, 'HATSAN');

    expect(hercules.magazineCapacity, 13);
    expect(hercules.barrelLengthMm, 585);
    expect(hercules.airCapacityCc, 1000);
    expect(hercules.overallLengthMm, 1230);
    expect(hercules.weightKg, 5.9);
    expect(hercules.moderatorThread, isNull);

    expect(blitz.magazineCapacity, 19);
    expect(blitz.barrelLengthMm, 585);
    expect(blitz.airCapacityCc, 580);
    expect(blitz.overallLengthMm, 1150);
    expect(blitz.weightKg, 4);
    expect(blitz.moderatorThread, isNull);
  });

  test('rejects duplicate ids and incomplete BC metadata', () {
    const ammo = Ammunition(
      id: 'dup',
      brand: 'Test',
      model: 'Slug',
      platform: WeaponPlatform.pcp,
      caliberMm: 6.35,
      grain: 50,
      type: AmmunitionType.slug,
      ballisticCoefficient: 0.1,
    );
    final issues = const CatalogIntegrity().validate(
      rifles: const [],
      ammunition: const [ammo, ammo],
      scopes: const [],
    );
    expect(issues.any((e) => e.message == 'duplicate id'), isTrue);
    expect(issues.any((e) => e.message.contains('supplied together')), isTrue);
  });

  test(
    'expanded HATSAN 6.35 catalog keeps manufacturer-backed variant values',
    () {
      Rifle byId(String id) =>
          CatalogRepository.rifles.singleWhere((e) => e.id == id);

      final factor = byId('hatsan-factor-635');
      expect(factor.magazineCapacity, 19);
      expect(factor.airCapacityCc, 500);
      expect(factor.overallLengthMm, 1025);
      expect(factor.moderatorThread, '1/2 UNF');

      final rc = byId('hatsan-factor-rc-635');
      expect(rc.magazineCapacity, 19);
      expect(rc.airCapacityCc, 580);
      expect(rc.barrelLengthMm, 585);
      expect(rc.weightKg, 3.6);

      final bp = byId('hatsan-factor-bp-635');
      expect(bp.airCapacityCc, 580);
      expect(bp.overallLengthMm, 870);
      expect(bp.weightKg, 3.8);

      final sniperS = byId('hatsan-factor-sniper-s-635');
      expect(sniperS.airCapacityCc, 480);
      expect(sniperS.overallLengthMm, 1005);
      expect(sniperS.weightKg, 4.6);

      final blitzBp = byId('hatsan-blitz-bp-635');
      expect(blitzBp.magazineCapacity, 19);
      expect(blitzBp.airCapacityCc, 610);
      expect(blitzBp.overallLengthMm, 905);

      final flash = byId('hatsan-flash-635');
      final flashQe = byId('hatsan-flash-qe-635');
      expect(flash.magazineCapacity, 10);
      expect(flash.airCapacityCc, 165);
      expect(flash.overallLengthMm, 915);
      expect(flashQe.overallLengthMm, 1075);

      final repex = byId('hatsan-repex-635');
      expect(repex.magazineCapacity, 10);
      expect(repex.barrelLengthMm, 432);
      expect(repex.weightKg, 2.25);
    },
  );

  test(
    'Huğlu Spark 6.35 variants preserve manufacturer configuration pairing',
    () {
      Rifle byId(String id) =>
          CatalogRepository.rifles.singleWhere((e) => e.id == id);
      final short = byId('huglu-spark-420-635');
      final long = byId('huglu-spark-600-635');

      expect(short.magazineCapacity, 10);
      expect(short.barrelLengthMm, 420);
      expect(short.airCapacityCc, 350);
      expect(short.plenumCc, 70);
      expect(short.moderatorThread, '1/2 UNF');
      expect(short.weightKg, isNull); // source gives only a family weight range

      expect(long.magazineCapacity, 10);
      expect(long.barrelLengthMm, 600);
      expect(long.airCapacityCc, 500);
      expect(long.plenumCc, 100);
      expect(long.moderatorThread, '1/2 UNF');
      expect(long.weightKg, isNull);
      expect(long.sourceName, 'Huğlu');
    },
  );

  test(
    'verified optic metadata keeps lens and physical objective diameter distinct',
    () {
      ScopeOptic byId(String id) =>
          CatalogRepository.scopes.singleWhere((e) => e.id == id);

      final discovery = byId('discovery-xed');
      expect(discovery.objectiveDiameterMm, 56);
      expect(discovery.objectiveOuterDiameterMm, 67);
      expect(discovery.tubeDiameterMm, 35);
      expect(discovery.elevationRangeMrad, 35);
      expect(discovery.windageRangeMrad, 18);
      expect(discovery.zeroStop, isTrue);
      expect(discovery.sourceName, 'DISCOVERYOPT');

      final gazi = byId('gazi-6-36');
      expect(gazi.tubeDiameterMm, 34);
      expect(gazi.elevationRangeMrad, 26);
      expect(gazi.windageRangeMrad, 14.5);
      expect(gazi.lengthMm, 335);
      expect(gazi.weightG, 870);

      final arken = byId('arken-ep5');
      expect(arken.minMagnification, 7);
      expect(arken.maxMagnification, 35);
      expect(arken.tubeDiameterMm, 34);
      expect(arken.elevationRangeMrad, 30);
      expect(arken.windageRangeMrad, 15);
      expect(arken.reticle, 'VPR-MIL');
    },
  );

  test('scope integrity rejects impossible physical objective diameter', () {
    const scope = ScopeOptic(
      id: 'bad-scope',
      brand: 'Test',
      model: 'Bad',
      objectiveDiameterMm: 56,
      objectiveOuterDiameterMm: 50,
      clickValue: 0.1,
      clickUnit: AngularUnit.mrad,
    );
    final issues = const CatalogIntegrity().validate(
      rifles: const [],
      ammunition: const [],
      scopes: const [scope],
    );
    expect(issues.any((e) => e.message.contains('cannot be smaller')), isTrue);
  });

  test(
    'JSB Exact King .25 family keeps manufacturer-backed weights without invented BC',
    () {
      Ammunition byId(String id) =>
          CatalogRepository.ammunition.singleWhere((e) => e.id == id);
      final king = byId('jsb-exact-king-25');
      final heavy = byId('jsb-exact-king-heavy-25');
      final heavyMk2 = byId('jsb-exact-king-heavy-mkii-25');

      expect(king.caliberMm, 6.35);
      expect(king.grain, 25.39);
      expect(heavy.grain, 33.95);
      expect(heavyMk2.grain, 33.95);
      expect(king.type, AmmunitionType.pellet);
      expect(heavy.type, AmmunitionType.pellet);
      expect(heavyMk2.type, AmmunitionType.pellet);
      expect(king.ballisticCoefficient, isNull);
      expect(heavy.ballisticCoefficient, isNull);
      expect(heavyMk2.ballisticCoefficient, isNull);
      expect(king.sourceName, 'JSB Match Diabolo');
    },
  );

  test(
    'verified PCP ammunition preserves manufacturer provenance without invented BC',
    () {
      Ammunition byId(String id) =>
          CatalogRepository.ammunition.singleWhere((e) => e.id == id);
      final fx177 = byId('fx-premium-177-8_4');
      expect(fx177.caliberMm, 4.52);
      expect(fx177.grain, 8.4);
      expect(fx177.sourceName, 'FX Airguns');
      expect(fx177.ballisticCoefficient, isNull);

      final fx22Light = byId('fx-premium-22-15_9');
      final fx22Heavy = byId('fx-premium-22-18_1');
      expect(fx22Light.caliberMm, 5.52);
      expect(fx22Light.grain, 15.9);
      expect(fx22Heavy.caliberMm, 5.52);
      expect(fx22Heavy.grain, 18.1);
      expect(fx22Heavy.ballisticModel, isNull);

      final fx = byId('fx-premium-25-34');
      expect(fx.caliberMm, 6.35);
      expect(fx.grain, 34);
      expect(fx.sourceName, 'FX Airguns');
      expect(fx.ballisticCoefficient, isNull);
      expect(fx.ballisticModel, isNull);

      final jsb = byId('jsb-knockout-mkii-25');
      expect(jsb.caliberMm, 6.35);
      expect(jsb.grain, closeTo(33.49, 0.01));
      expect(jsb.type, AmmunitionType.slug);
      expect(jsb.sourceName, 'JSB Match Diabolo');
    },
  );

  test(
    'FX 6.35 rifle expansion preserves only manufacturer-backed metadata',
    () {
      Rifle byId(String id) =>
          CatalogRepository.rifles.singleWhere((e) => e.id == id);

      final p500 = byId('fx-panthera-500-635');
      final p600 = byId('fx-panthera-600-635');
      final p700 = byId('fx-panthera-700-635');
      expect(p500.barrelLengthMm, 500);
      expect(p500.airCapacityCc, 300);
      expect(p500.barrelType, 'FX Superior STX');
      expect(
        p500.plenumCc,
        isNull,
      ); // page does not pair a larger plenum to this configuration
      expect(p600.barrelLengthMm, 600);
      expect(p600.plenumCc, 156);
      expect(p600.barrelType, 'FX Superior Heavy STX');
      expect(p700.barrelLengthMm, 700);
      expect(p700.plenumCc, 156);

      final fxDynamic = byId('fx-dynamic-635');
      expect(fxDynamic.airCapacityCc, 480);
      expect(fxDynamic.plenumCc, 156);
      expect(fxDynamic.moderatorThread, '1/2 UNF');

      final king = byId('fx-king-635');
      expect(king.plenumCc, 156);
      expect(king.rail, 'Picatinny 30 MOA');
      expect(
        king.airCapacityCc,
        isNull,
      ); // multiple bottle options; no variant guessed

      final drs = byId('fx-drs-mkii-tactical-635');
      expect(drs.airCapacityCc, 760);
      expect(drs.plenumCc, 53);
      expect(drs.rail, contains('30 MOA'));
      expect(drs.sourceName, 'FX Airguns');
    },
  );

  test(
    'FX current 6.35 family expansion keeps provenance and avoids guessed variant data',
    () {
      Rifle byId(String id) =>
          CatalogRepository.rifles.singleWhere((e) => e.id == id);

      final impact = byId('fx-impact-m4-635');
      expect(impact.plenumCc, 75);
      expect(impact.sourceName, 'FX Airguns');
      expect(impact.airCapacityCc, isNull);

      final crown = byId('fx-crown-mkii-635');
      expect(crown.rail, 'Picatinny 20 MOA');
      expect(crown.barrelType, contains('STX'));
      expect(crown.airCapacityCc, isNull);

      final wildcat = byId('fx-wildcat-mkiii-635');
      expect(wildcat.caliberMm, 6.35);
      expect(
        wildcat.airCapacityCc,
        isNull,
      ); // tube/bottle variants are not collapsed

      final classic = byId('fx-drs-mkii-classic-635');
      final pro = byId('fx-drs-mkii-pro-635');
      expect(classic.rail, 'Picatinny 30 MOA');
      expect(classic.barrelType, contains('APB'));
      expect(pro.rail, contains('M-LOK'));
      expect(pro.sourceDocument, contains('official product page'));
    },
  );

  test('ammunition integrity rejects half-specified provenance', () {
    const ammo = Ammunition(
      id: 'bad-source',
      brand: 'Test',
      model: 'Pellet',
      platform: WeaponPlatform.pcp,
      caliberMm: 6.35,
      grain: 34,
      type: AmmunitionType.pellet,
      sourceName: 'Maker',
    );
    final issues = const CatalogIntegrity().validate(
      rifles: const [],
      ammunition: const [ammo],
      scopes: const [],
    );
    expect(
      issues.any((e) => e.message.contains('sourceName and sourceDocument')),
      isTrue,
    );
  });

  test(
    'non-manual branded catalog records cannot silently lose provenance',
    () {
      const rifle = Rifle(
        id: 'unsourced-rifle',
        brand: 'Example',
        model: 'Model',
        platform: WeaponPlatform.pcp,
        caliberMm: 6.35,
      );
      const ammo = Ammunition(
        id: 'unsourced-ammo',
        brand: 'Example',
        model: 'Pellet',
        platform: WeaponPlatform.pcp,
        caliberMm: 5.52,
        grain: 15.89,
        type: AmmunitionType.pellet,
      );
      const scope = ScopeOptic(
        id: 'unsourced-scope',
        brand: 'Example',
        model: 'Scope',
        objectiveDiameterMm: 50,
        clickValue: 0.1,
        clickUnit: AngularUnit.mrad,
      );
      final issues = const CatalogIntegrity().validate(
        rifles: [rifle],
        ammunition: [ammo],
        scopes: [scope],
      );
      expect(
        issues.where(
          (e) => e.message == 'non-manual catalog records require provenance',
        ),
        hasLength(3),
      );
    },
  );

  test(
    'manual templates remain intentionally usable without fake provenance',
    () {
      const rifle = Rifle(
        id: 'manual-rifle-test',
        brand: 'Manuel',
        model: 'Tüfek',
        platform: WeaponPlatform.pcp,
        caliberMm: 6.35,
      );
      const ammo = Ammunition(
        id: 'manual-ammo-test',
        brand: 'Manuel',
        model: 'Mühimmat',
        platform: WeaponPlatform.pcp,
        caliberMm: 6.35,
        grain: 34,
        type: AmmunitionType.pellet,
      );
      final issues = const CatalogIntegrity().validate(
        rifles: [rifle],
        ammunition: [ammo],
        scopes: const [],
      );
      expect(issues, isEmpty, reason: issues.join('\n'));
    },
  );

  test('JSB 4.5 and 5.5 manufacturer records keep exact verified weights', () {
    Ammunition byId(String id) =>
        CatalogRepository.ammunition.singleWhere((e) => e.id == id);
    final exact177 = byId('jsb-exact-177-8_44');
    final heavy177 = byId('jsb-exact-heavy-177-10_34');
    final jumbo22 = byId('jsb-exact-jumbo-22-15_89');
    final jumboHeavy22 = byId('jsb-exact-jumbo-heavy-22-18_13');

    expect((exact177.caliberMm, exact177.grain), (4.52, 8.44));
    expect((heavy177.caliberMm, heavy177.grain), (4.52, 10.34));
    expect((jumbo22.caliberMm, jumbo22.grain), (5.52, 15.89));
    expect((jumboHeavy22.caliberMm, jumboHeavy22.grain), (5.52, 18.13));
    for (final ammo in [exact177, heavy177, jumbo22, jumboHeavy22]) {
      expect(ammo.sourceName, 'JSB Match Diabolo');
      expect(ammo.ballisticCoefficient, isNull);
      expect(ammo.ballisticModel, isNull);
    }
  });

  test(
    'scope lower-bound provenance cannot exist without a published range',
    () {
      const scope = ScopeOptic(
        id: 'orphan-lower-bound',
        brand: 'Test',
        model: 'Scope',
        objectiveDiameterMm: 56,
        clickValue: 0.1,
        clickUnit: AngularUnit.mrad,
        elevationRangeIsLowerBound: true,
        windageRangeIsLowerBound: true,
        sourceName: 'Test',
        sourceDocument: 'Test source',
      );
      final issues = const CatalogIntegrity().validate(
        rifles: const [],
        ammunition: const [],
        scopes: const [scope],
      );
      expect(
        issues.any(
          (e) =>
              e.message ==
              'elevationRangeIsLowerBound requires elevationRangeMrad',
        ),
        isTrue,
      );
      expect(
        issues.any(
          (e) =>
              e.message == 'windageRangeIsLowerBound requires windageRangeMrad',
        ),
        isTrue,
      );
    },
  );

  test(
    'scope lower-bound provenance is valid when the published ranges exist',
    () {
      const scope = ScopeOptic(
        id: 'valid-lower-bound',
        brand: 'Test',
        model: 'Scope',
        objectiveDiameterMm: 56,
        clickValue: 0.1,
        clickUnit: AngularUnit.mrad,
        elevationRangeMrad: 17.5,
        windageRangeMrad: 16,
        elevationRangeIsLowerBound: true,
        windageRangeIsLowerBound: true,
        sourceName: 'Test',
        sourceDocument: 'Test source',
      );
      final issues = const CatalogIntegrity().validate(
        rifles: const [],
        ammunition: const [],
        scopes: const [scope],
      );
      expect(issues, isEmpty, reason: issues.join('\n'));
    },
  );
}
