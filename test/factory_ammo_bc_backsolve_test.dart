// BC geri hesap (owner, 2026-10-14): "Uygun olanları ekle, oranlar çok
// iyi." 30 BC'siz fabrika fişeğine üreticinin kendi BC'si (yazılı, üreticinin
// hız tablosundan geri hesap veya içindeki merminin üretici BC'si) eklendi.
// Kaynak: docs/research/bc_gelistirme.md, data/bc_gelistirme/*.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/models/domain.dart';

/// (research id, brand, name, cartridge, BC G1, bcSource, URL host).
const _added = <(String, String, String, String, double, String, String)>[
  (
    'FA002',
    'Hornady',
    'Varmint Express Rimfire 17 gr V-MAX',
    '.17 HMR',
    0.125,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA003',
    'Hornady',
    'Varmint Express Rimfire 20 gr HP XTP',
    '.17 HMR',
    0.125,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA029',
    'Hornady',
    '30 gr V-MAX Varmint Express Rimfire',
    '.22 WMR',
    0.095,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA062',
    'Hornady',
    '170 gr MonoFlex Black',
    '.338 ARC',
    0.309,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA063',
    'Hornady',
    '175 gr HP Match BLACK',
    '.338 ARC',
    0.385,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA064',
    'Hornady',
    '215 gr FTX Black',
    '.338 ARC',
    0.371,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA067',
    'Hornady',
    '210 gr InterLock American Whitetail',
    '.400 Legend',
    0.198,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA082',
    'Hornady',
    'American Gunner 123 gr HP Match',
    '7.62x39',
    0.272,
    'maker-table-backsolve',
    'www.hornady.com',
  ),
  (
    'FA042',
    'Lapua',
    'Lapua 4.5 g (69 gr) Scenar',
    '.223 Rem',
    0.341,
    'printed',
    'www.lapua.com',
  ),
  (
    'FA044',
    'Weatherby',
    '240 Weatherby Magnum 72 gr Hammer Custom',
    '.240 Weatherby Mag',
    0.32,
    'printed',
    'weatherby.com',
  ),
  (
    'FA004',
    'Aguila',
    '22 Long Rifle Interceptor Copper-Plated Hollow Point',
    '.22 LR',
    0.14,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA005',
    'Aguila',
    '22 Long Rifle Interceptor Copper-Plated Solid Point',
    '.22 LR',
    0.14,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA006',
    'Aguila',
    '22 Long Rifle Sniper Subsonic Lead Solid Point',
    '.22 LR',
    0.139,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA008',
    'Aguila',
    '22 Long Rifle Subsonic Lead Hollow Point',
    '.22 LR',
    0.111,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA009',
    'Aguila',
    '22 Long Rifle Subsonic Lead Solid Point',
    '.22 LR',
    0.158,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA010',
    'Aguila',
    '22 Long Rifle SuperMaximum Copper-Plated Hollow Point',
    '.22 LR',
    0.11,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA011',
    'Aguila',
    '22 Long Rifle SuperMaximum Copper-Plated Solid Point',
    '.22 LR',
    0.11,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA012',
    'Aguila',
    '22 Long Rifle Target Competition Lead Solid Point',
    '.22 LR',
    0.168,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA028',
    'Aguila',
    '22 Win Mag Semi-Jacketed Soft Point',
    '.22 WMR',
    0.15,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA047',
    'Aguila',
    '110 Grain Full Metal Jacket',
    '.30 Carbine',
    0.127,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA048',
    'Aguila',
    '30-06 SPRG 150 Grain Soft Point',
    '.30-06 Springfield',
    0.339,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA050',
    'Aguila',
    '300 AAC Blackout 150 Grain Full Metal Jacket',
    '.300 Blackout',
    0.303,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA056',
    'Aguila',
    '308 WIN 150 Grain Full Metal Jacket Boat Tail',
    '.308 Win',
    0.323,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA083',
    'Aguila',
    '7.62 x 51mm 150 Grain Full Metal Jacket Boat Tail',
    '7.62x51 NATO',
    0.323,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA068',
    'Aguila',
    '5.56 x 45mm 55 Grain Full Metal Jacket Boat Tail',
    '5.56x45 NATO',
    0.301,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA069',
    'Aguila',
    '5.56 x 45mm 62 Grain Full Metal Jacket Boat Tail',
    '5.56x45 NATO',
    0.284,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA070',
    'Aguila',
    '5.56 x 45mm NATO 55 Grain FMJ',
    '5.56x45 NATO',
    0.252,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA075',
    'Aguila',
    '140 Grain Full Metal Jacket Boat Tail',
    '6.5 Creedmoor',
    0.5,
    'maker-table-backsolve',
    'www.aguilaammo.com',
  ),
  (
    'FA031',
    'Winchester',
    'Varmint HV 22 Win Mag 30 gr V-MAX',
    '.22 WMR',
    0.095,
    'component-bullet',
    'www.hornady.com',
  ),
  (
    'FA034',
    'Black Hills',
    'Black Hills 36 gr Varmint Grenade',
    '.223 Rem',
    0.149,
    'component-bullet',
    'barnesbullets.com',
  ),
];

/// Not added now (sahibe sorulacak): (research id, brand, name, cartridge, grain).
const _excluded = <(String, String, String, String, double)>[
  ('FA061', 'Hornady', '(Subsonic) 285 gr FMJ Frontier', '.338 ARC', 285.0),
  ('FA045', 'Lapua', 'Lapua 5.8 g (90 gr) FMJ', '.243 Win', 90.0),
  ('FA046', 'Lapua', 'Lapua 6.5 g (100 gr) Soft Point', '.243 Win', 100.0),
  (
    'FA007',
    'Aguila',
    '22 Long Rifle Standard Velocity Lead Solid Point',
    '.22 LR',
    29.0,
  ),
  ('FA014', 'Geco', 'GECO RIFLE .22 2,6g', '.22 LR', 40.0),
  ('FA015', 'Geco', 'GECO SEMI-AUTO .22 2,6g', '.22 LR', 40.0),
];

FactoryAmmo _one(String brand, String name, String cartridge) =>
    FactoryAmmoLibrary.all.singleWhere(
      (a) => a.brand == brand && a.name == name && a.cartridge == cartridge,
    );

void main() {
  test('the 30 rounds carry the maker BC, G1, source and maker URL', () {
    expect(_added, hasLength(30));
    for (final (id, brand, name, cartridge, bc, source, host) in _added) {
      final a = _one(brand, name, cartridge);
      expect(a.bc, bc, reason: id);
      expect(a.model, BallisticModel.g1, reason: id);
      expect(a.bcSource, source, reason: id);
      expect(Uri.parse(a.bcSourceUrl!).scheme, 'https', reason: id);
      expect(Uri.parse(a.bcSourceUrl!).host, host, reason: id);
      expect(a.note, contains('14.10.2026'), reason: id);
      expect(a.bcProbable, isFalse, reason: id);
      expect(a.bcStandard, isNull, reason: id);
      expect(a.bcReport, isNull, reason: id);
      expect(a.bcFromBullet, source == 'component-bullet', reason: id);
      expect(a.bcG7, id == 'FA042' ? 0.171 : null, reason: id);
    }
  });

  test('Lapua .223 69 gr Scenar-L: printed G1 0.341 and G7 0.171', () {
    final a = _one('Lapua', 'Lapua 4.5 g (69 gr) Scenar', '.223 Rem');
    expect(a.bc, 0.341);
    expect(a.model, BallisticModel.g1);
    expect(a.bcG7, 0.171);
    expect(a.note, contains('G7 0,171'));
  });

  test('the 6 rounds left for the owner stay without BC', () {
    for (final (id, brand, name, cartridge, grain) in _excluded) {
      final a = _one(brand, name, cartridge);
      expect(a.grain, grain, reason: id);
      expect(a.bc, isNull, reason: id);
      expect(a.model, isNull, reason: id);
      expect(a.bcSource, isNull, reason: id);
      expect(a.bcSourceUrl, isNull, reason: id);
      expect(a.note, isNull, reason: id);
      expect(a.bcG7, isNull, reason: id);
    }
  });

  test('no added BC trips the firearm G1 plausibility band', () {
    // Same band as the Profil BC warning: grain/(7000·d²)/BC in 0.32..4.6.
    for (final (id, brand, name, cartridge, _, _, _) in _added) {
      final a = _one(brand, name, cartridge);
      final d = a.diameterMm / 25.4;
      final i = a.grain / (7000 * d * d) / a.bc!;
      expect(i, inInclusiveRange(0.32, 4.6), reason: id);
    }
  });
}
