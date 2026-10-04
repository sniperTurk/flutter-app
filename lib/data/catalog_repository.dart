// dart format off
import '../models/domain.dart';
import 'catalog_integrity.dart';
import 'user_catalog.dart';

class CatalogRepository {
  const CatalogRepository();
  static const rifles = <Rifle>[
    // v308: Aselkon Arms current official PCP pages; model/caliber variants only where manufacturer confirms them.
    Rifle(id:'aselkon-mx10-black-45', brand:'Aselkon Arms', model:'MX10 Black', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-black-55', brand:'Aselkon Arms', model:'MX10 Black', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-black-635', brand:'Aselkon Arms', model:'MX10 Black', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-camo-max5-45', brand:'Aselkon Arms', model:'MX10 Camo Max5', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-camo-max5-55', brand:'Aselkon Arms', model:'MX10 Camo Max5', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-camo-max5-635', brand:'Aselkon Arms', model:'MX10 Camo Max5', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-wood-45', brand:'Aselkon Arms', model:'MX10 Wood', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-wood/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-wood-55', brand:'Aselkon Arms', model:'MX10 Wood', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-wood/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-wood-635', brand:'Aselkon Arms', model:'MX10 Wood', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:550, airCapacityCc:320, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-wood/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-black-45', brand:'Aselkon Arms', model:'MX10-S Black', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-black-55', brand:'Aselkon Arms', model:'MX10-S Black', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-black-635', brand:'Aselkon Arms', model:'MX10-S Black', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-black/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-camo-max5-45', brand:'Aselkon Arms', model:'MX10-S Camo Max5', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-camo-max5-55', brand:'Aselkon Arms', model:'MX10-S Camo Max5', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-camo-max5-635', brand:'Aselkon Arms', model:'MX10-S Camo Max5', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-camo-max5/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-wood-45', brand:'Aselkon Arms', model:'MX10-S Wood', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-wood/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-wood-55', brand:'Aselkon Arms', model:'MX10-S Wood', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-wood/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'aselkon-mx10-s-wood-635', brand:'Aselkon Arms', model:'MX10-S Wood', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:275, overallLengthMm:850, weightKg:2.85, sourceName:'Aselkon Arms', sourceDocument:'https://aselkonarms.com/urun/pcp-mx10-s-wood/ — official manufacturer page, verified 2026-10-02'),
    // v259: Avenge-X verified body/caliber variants; omit configuration-dependent dimensions.
    Rifle(id:'airventuri-avenge-x-tactical-synthetic-177', brand:'Air Venturi', model:'Avenge-X Tactical Synthetic', platform:WeaponPlatform.pcp, caliberMm:4.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-tactical-synthetic-22', brand:'Air Venturi', model:'Avenge-X Tactical Synthetic', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-tactical-synthetic-25', brand:'Air Venturi', model:'Avenge-X Tactical Synthetic', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-synthetic-177', brand:'Air Venturi', model:'Avenge-X Classic Synthetic', platform:WeaponPlatform.pcp, caliberMm:4.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-classic-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-synthetic-22', brand:'Air Venturi', model:'Avenge-X Classic Synthetic', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-classic-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-synthetic-25', brand:'Air Venturi', model:'Avenge-X Classic Synthetic', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-classic-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-tactical-carbine-synthetic-177', brand:'Air Venturi', model:'Avenge-X Tactical Carbine Synthetic', platform:WeaponPlatform.pcp, caliberMm:4.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical-carbine-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-tactical-carbine-synthetic-22', brand:'Air Venturi', model:'Avenge-X Tactical Carbine Synthetic', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical-carbine-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-tactical-carbine-synthetic-25', brand:'Air Venturi', model:'Avenge-X Tactical Carbine Synthetic', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/avenge-x-tactical-carbine-synthetic-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-wood-177', brand:'Air Venturi', model:'Avenge-X Classic Wood', platform:WeaponPlatform.pcp, caliberMm:4.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-classic-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-wood-22', brand:'Air Venturi', model:'Avenge-X Classic Wood', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-classic-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-classic-wood-25', brand:'Air Venturi', model:'Avenge-X Classic Wood', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-classic-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-bullpup-wood-177', brand:'Air Venturi', model:'Avenge-X Bullpup Wood', platform:WeaponPlatform.pcp, caliberMm:4.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-bullpup-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-bullpup-wood-22', brand:'Air Venturi', model:'Avenge-X Bullpup Wood', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-bullpup-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    Rifle(id:'airventuri-avenge-x-bullpup-wood-25', brand:'Air Venturi', model:'Avenge-X Bullpup Wood', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/air-venturi-avenge-x-bullpup-wood-stock — official manufacturer model and caliber options, verified 2026-09-30'),
    // v258: Official current Seneca listing distributed by Air Venturi; do not infer other caliber variants.
    Rifle(id:'airventuri-seneca-dragon-claw-ii-tactical-50', brand:'Seneca (Air Venturi)', model:'Dragon Claw II Tactical', platform:WeaponPlatform.pcp, caliberMm:12.7, airCapacityCc:500, barrelLengthMm:549.91, weightKg:3.447, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/seneca-dragon-claw-ii-pcp-air-rifle-tactical-stock — official current listing, verified 2026-09-30'),

    // v260: manufacturer-confirmed .45 PCP rifles; no inferred alternate calibers.
    Rifle(id:'airventuri-seneca-light-hunter-ii-wood-45', brand:'Seneca (Air Venturi)', model:'Light Hunter II Wood', platform:WeaponPlatform.pcp, caliberMm:11.43, airCapacityCc:500, barrelLengthMm:549.91, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/seneca-light-hunter-ii-wood — manufacturer listing, checked 2026-09-30'),
    Rifle(id:'airventuri-seneca-light-hunter-ii-tactical-45', brand:'Seneca (Air Venturi)', model:'Light Hunter II Tactical', platform:WeaponPlatform.pcp, caliberMm:11.43, airCapacityCc:500, barrelLengthMm:549.91, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/seneca-light-hunter-ii-tactical — manufacturer listing, checked 2026-09-30'),

    // v247: Complete RTI rifles listed in the official AIRGUNS collection; excludes unfinished Naked chassis and custom builds.
    Rifle(id:'rti-mora-compact-v2-gen2-45', brand:'RTI Arms', model:'Mora Compact V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:500, barrelLengthMm:500, weightKg:4.2, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-compact-v2-gen2-55', brand:'RTI Arms', model:'Mora Compact V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:500, barrelLengthMm:500, weightKg:4.2, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-compact-v2-gen2-635', brand:'RTI Arms', model:'Mora Compact V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:500, barrelLengthMm:500, weightKg:4.2, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-compact-v2-gen2-762', brand:'RTI Arms', model:'Mora Compact V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:7.62, airCapacityCc:500, barrelLengthMm:500, weightKg:4.2, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-standard-v2-gen2-45', brand:'RTI Arms', model:'Mora Standard V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:740, barrelLengthMm:600, weightKg:4.4, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-standard-v2-gen2-55', brand:'RTI Arms', model:'Mora Standard V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:740, barrelLengthMm:600, weightKg:4.4, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-standard-v2-gen2-635', brand:'RTI Arms', model:'Mora Standard V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:740, barrelLengthMm:600, weightKg:4.4, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-standard-v2-gen2-762', brand:'RTI Arms', model:'Mora Standard V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:7.62, airCapacityCc:740, barrelLengthMm:600, weightKg:4.4, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-sniper-v2-gen2-55', brand:'RTI Arms', model:'Mora Sniper V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:1100, barrelLengthMm:700, weightKg:4.68, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-sniper — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-sniper-v2-gen2-635', brand:'RTI Arms', model:'Mora Sniper V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:1100, barrelLengthMm:700, weightKg:4.68, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-sniper — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-mora-sniper-v2-gen2-90', brand:'RTI Arms', model:'Mora Sniper V2 Gen 2', platform:WeaponPlatform.pcp, caliberMm:9.0, airCapacityCc:1100, barrelLengthMm:700, weightKg:4.68, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-mora-sniper — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-45', brand:'RTI Arms', model:'P-3 Standard', platform:WeaponPlatform.pcp, caliberMm:4.5, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-55', brand:'RTI Arms', model:'P-3 Standard', platform:WeaponPlatform.pcp, caliberMm:5.5, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-635', brand:'RTI Arms', model:'P-3 Standard', platform:WeaponPlatform.pcp, caliberMm:6.35, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-762', brand:'RTI Arms', model:'P-3 Standard', platform:WeaponPlatform.pcp, caliberMm:7.62, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-compact-45', brand:'RTI Arms', model:'P-3 Standard Compact', platform:WeaponPlatform.pcp, caliberMm:4.5, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-compact-55', brand:'RTI Arms', model:'P-3 Standard Compact', platform:WeaponPlatform.pcp, caliberMm:5.5, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-compact-635', brand:'RTI Arms', model:'P-3 Standard Compact', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-standard-compact-762', brand:'RTI Arms', model:'P-3 Standard Compact', platform:WeaponPlatform.pcp, caliberMm:7.62, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-standard-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-45', brand:'RTI Arms', model:'P-3 Performance', platform:WeaponPlatform.pcp, caliberMm:4.5, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-55', brand:'RTI Arms', model:'P-3 Performance', platform:WeaponPlatform.pcp, caliberMm:5.5, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-635', brand:'RTI Arms', model:'P-3 Performance', platform:WeaponPlatform.pcp, caliberMm:6.35, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-762', brand:'RTI Arms', model:'P-3 Performance', platform:WeaponPlatform.pcp, caliberMm:7.62, weightKg:3.3, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-compact-45', brand:'RTI Arms', model:'P-3 Performance Compact', platform:WeaponPlatform.pcp, caliberMm:4.5, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-compact-55', brand:'RTI Arms', model:'P-3 Performance Compact', platform:WeaponPlatform.pcp, caliberMm:5.5, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-compact-635', brand:'RTI Arms', model:'P-3 Performance Compact', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance-compact — official shop listing, verified 2026-09-30'),
    Rifle(id:'rti-p3-performance-compact-762', brand:'RTI Arms', model:'P-3 Performance Compact', platform:WeaponPlatform.pcp, caliberMm:7.62, barrelLengthMm:510, sourceName:'RTI Arms Shop', sourceDocument:'https://www.rtiarms.shop/products/rti-p-3-performance-compact — official shop listing, verified 2026-09-30'),
    // v246: Snowpeak manufacturer-verified PCP rifles; variants only when the official page lists the caliber.
    // Spring/CO2 rifles are not mapped to firearm or PCP: the current platform enum cannot represent them.
    Rifle(id:'snowpeak-max2-tb-45', brand:'Snowpeak', model:'MAX2 TB', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:790, barrelLengthMm:700, weightKg:4.5, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/241.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-max2-tb-55', brand:'Snowpeak', model:'MAX2 TB', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:790, barrelLengthMm:700, weightKg:4.5, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/241.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-max2-tb-635', brand:'Snowpeak', model:'MAX2 TB', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:790, barrelLengthMm:700, weightKg:4.5, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/241.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-max2-tb-762', brand:'Snowpeak', model:'MAX2 TB', platform:WeaponPlatform.pcp, caliberMm:7.62, airCapacityCc:790, barrelLengthMm:700, weightKg:4.5, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/241.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-max2-tb-90', brand:'Snowpeak', model:'MAX2 TB', platform:WeaponPlatform.pcp, caliberMm:9.0, airCapacityCc:790, barrelLengthMm:700, weightKg:4.5, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/241.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m60-45', brand:'Snowpeak', model:'M60', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/158.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m60-55', brand:'Snowpeak', model:'M60', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/158.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m60-635', brand:'Snowpeak', model:'M60', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/158.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m60-762', brand:'Snowpeak', model:'M60', platform:WeaponPlatform.pcp, caliberMm:7.62, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/158.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m60-90', brand:'Snowpeak', model:'M60', platform:WeaponPlatform.pcp, caliberMm:9.0, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/158.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m18-45', brand:'Snowpeak', model:'M18', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:350, barrelLengthMm:480, overallLengthMm:1080, weightKg:2.9, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/156.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m18-55', brand:'Snowpeak', model:'M18', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:350, barrelLengthMm:480, overallLengthMm:1080, weightKg:2.9, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/156.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-m18-635', brand:'Snowpeak', model:'M18', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:350, barrelLengthMm:480, overallLengthMm:1080, weightKg:2.9, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/156.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-pr900w-g2-45', brand:'Snowpeak', model:'PR900W G2', platform:WeaponPlatform.pcp, caliberMm:4.5, overallLengthMm:950, weightKg:2.27, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/59.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-pr900w-g2-55', brand:'Snowpeak', model:'PR900W G2', platform:WeaponPlatform.pcp, caliberMm:5.5, overallLengthMm:950, weightKg:2.27, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/59.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-trex-wood-45', brand:'Snowpeak', model:'T-REX WOOD', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:140, barrelLengthMm:530, overallLengthMm:790, weightKg:2.3, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/226.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-trex-wood-55', brand:'Snowpeak', model:'T-REX WOOD', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:140, barrelLengthMm:530, overallLengthMm:790, weightKg:2.3, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/226.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-trex-wood-635', brand:'Snowpeak', model:'T-REX WOOD', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:140, barrelLengthMm:530, overallLengthMm:790, weightKg:2.3, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/226.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-l-m60-taiwan-45', brand:'Snowpeak', model:'L-M60 (Taiwan low-power)', platform:WeaponPlatform.pcp, caliberMm:4.5, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/188.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-l-m60-taiwan-55', brand:'Snowpeak', model:'L-M60 (Taiwan low-power)', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/188.html — official product page, verified 2026-09-30'),
    Rifle(id:'snowpeak-l-m60-taiwan-635', brand:'Snowpeak', model:'L-M60 (Taiwan low-power)', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:205, barrelLengthMm:610, overallLengthMm:925, weightKg:3.0, sourceName:'Snowpeak', sourceDocument:'https://www.snowpeaksports.com/series/details/188.html — official product page, verified 2026-09-30'),
    // v307: Reximex PCP families verified directly against current official manufacturer pages.
    // Only models whose official page explicitly publishes the caliber are included.
    Rifle(id:'reximex-meta-45', brand:'Reximex', model:'Meta', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:480, airCapacityCc:260, overallLengthMm:750, weightKg:3.6, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-meta-55', brand:'Reximex', model:'Meta', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:480, airCapacityCc:260, overallLengthMm:750, weightKg:3.6, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-meta-635', brand:'Reximex', model:'Meta', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:480, airCapacityCc:260, overallLengthMm:750, weightKg:3.6, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-45', brand:'Reximex', model:'Tormenta', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:380, airCapacityCc:380, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-55', brand:'Reximex', model:'Tormenta', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:380, airCapacityCc:380, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-635', brand:'Reximex', model:'Tormenta', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:380, airCapacityCc:380, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-meta-premium-45', brand:'Reximex', model:'Meta Premium', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:700, airCapacityCc:570, overallLengthMm:1000, weightKg:4.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta-premium/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-meta-premium-55', brand:'Reximex', model:'Meta Premium', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:700, airCapacityCc:570, overallLengthMm:1000, weightKg:4.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta-premium/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-meta-premium-635', brand:'Reximex', model:'Meta Premium', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:700, airCapacityCc:570, overallLengthMm:1000, weightKg:4.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/meta-premium/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-lite-45', brand:'Reximex', model:'Tormenta Lite', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:380, airCapacityCc:130, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta-lite/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-lite-55', brand:'Reximex', model:'Tormenta Lite', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:380, airCapacityCc:130, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta-lite/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-tormenta-lite-635', brand:'Reximex', model:'Tormenta Lite', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:380, airCapacityCc:130, overallLengthMm:850, weightKg:2.8, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/tormenta-lite/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-45', brand:'Reximex', model:'Accura', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:380, airCapacityCc:425, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/tr/pcp-havali-tufek/accura/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-55', brand:'Reximex', model:'Accura', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:380, airCapacityCc:425, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/tr/pcp-havali-tufek/accura/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-635', brand:'Reximex', model:'Accura', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:380, airCapacityCc:425, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/tr/pcp-havali-tufek/accura/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-nyx-45', brand:'Reximex', model:'NYX', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:480, airCapacityCc:500, overallLengthMm:1050, weightKg:4.415, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/nyx/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-nyx-55', brand:'Reximex', model:'NYX', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:480, airCapacityCc:500, overallLengthMm:1050, weightKg:4.415, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/nyx/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-nyx-635', brand:'Reximex', model:'NYX', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:480, airCapacityCc:500, overallLengthMm:1050, weightKg:4.415, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/nyx/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-bp-45', brand:'Reximex', model:'Lyra BP', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:420, airCapacityCc:210, overallLengthMm:625, weightKg:3.1, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-bp/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-bp-55', brand:'Reximex', model:'Lyra BP', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:420, airCapacityCc:210, overallLengthMm:625, weightKg:3.1, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-bp/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-bp-635', brand:'Reximex', model:'Lyra BP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:420, airCapacityCc:210, overallLengthMm:625, weightKg:3.1, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-bp/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-carbon-45', brand:'Reximex', model:'Accura Carbon', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:420, airCapacityCc:480, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/accura-carbon/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-carbon-55', brand:'Reximex', model:'Accura Carbon', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:420, airCapacityCc:480, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/accura-carbon/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-accura-carbon-635', brand:'Reximex', model:'Accura Carbon', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:420, airCapacityCc:480, overallLengthMm:1010, weightKg:3.5, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/accura-carbon/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lieva-45', brand:'Reximex', model:'Lieva', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, barrelLengthMm:520, airCapacityCc:105, overallLengthMm:980, weightKg:2.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lieva/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lieva-55', brand:'Reximex', model:'Lieva', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, barrelLengthMm:520, airCapacityCc:105, overallLengthMm:980, weightKg:2.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lieva/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lieva-635', brand:'Reximex', model:'Lieva', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:520, airCapacityCc:105, overallLengthMm:980, weightKg:2.2, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lieva/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-k-45', brand:'Reximex', model:'Lyra-K', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:14, airCapacityCc:250, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-k/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-k-55', brand:'Reximex', model:'Lyra-K', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:12, airCapacityCc:250, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-k/ — official manufacturer page, verified 2026-10-02'),
    Rifle(id:'reximex-lyra-k-635', brand:'Reximex', model:'Lyra-K', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, airCapacityCc:250, sourceName:'Reximex', sourceDocument:'https://reximex.com/airgun/pcp-airgun/lyra-k/ — official manufacturer page, verified 2026-10-02'),

    // v306: Rossi 2026 official PCP catalog expansion discovered via Mundo da Carabina.
    // Only manufacturer-published model/caliber/physical facts are recorded.
    Rifle(id:'rossi-outlander-55', brand:'Rossi', model:'Outlander', platform:WeaponPlatform.pcp, caliberMm:5.5, barrelLengthMm:580, airCapacityCc:145, overallLengthMm:1130, weightKg:2.45, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Outlander PCP 5.5 mm, verified 2026-10-02'),
    Rifle(id:'rossi-outlander-635', brand:'Rossi', model:'Outlander', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:145, overallLengthMm:1130, weightKg:2.60, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Outlander PCP 6.35 mm, verified 2026-10-02'),
    Rifle(id:'rossi-trex-635', brand:'Rossi', model:'T-Rex', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:9, barrelLengthMm:480, airCapacityCc:230, overallLengthMm:1048, weightKg:3.15, sourceName:'Rossi', sourceDocument:'Rossi official T-Rex manual and 2026 catalog — 6.35 mm, verified 2026-10-02'),
    Rifle(id:'rossi-trex-bullpup-635', brand:'Rossi', model:'T-Rex Bullpup', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:9, barrelLengthMm:530, airCapacityCc:150, overallLengthMm:842, weightKg:2.30, sourceName:'Rossi', sourceDocument:'Rossi official T-Rex manual and 2026 catalog — Bullpup 6.35 mm, verified 2026-10-02'),
    Rifle(id:'rossi-outlander-bullpup-55', brand:'Rossi', model:'Outlander Bullpup', platform:WeaponPlatform.pcp, caliberMm:5.5, barrelLengthMm:580, overallLengthMm:845, weightKg:2.95, sourceName:'Rossi', sourceDocument:'Rossi official product page / 2026 catalog — Outlander Bullpup 5.5 mm, verified 2026-10-02'),
    Rifle(id:'rossi-outlander-bullpup-635', brand:'Rossi', model:'Outlander Bullpup', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:8, barrelLengthMm:580, overallLengthMm:845, weightKg:2.92, sourceName:'Rossi', sourceDocument:'Rossi official product page / 2026 catalog — Outlander Bullpup 6.35 mm, verified 2026-10-02'),
    Rifle(id:'rossi-kodiak-635', brand:'Rossi', model:'Kodiak', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:275, overallLengthMm:1230, weightKg:3.70, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Kodiak 6.35 mm, verified 2026-10-02'),
    Rifle(id:'rossi-kodiak-762', brand:'Rossi', model:'Kodiak', platform:WeaponPlatform.pcp, caliberMm:7.62, airCapacityCc:325, overallLengthMm:1230, weightKg:3.70, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Kodiak 7.62 mm, verified 2026-10-02'),
    Rifle(id:'rossi-kodiak-90', brand:'Rossi', model:'Kodiak', platform:WeaponPlatform.pcp, caliberMm:9.0, airCapacityCc:325, overallLengthMm:1230, weightKg:3.70, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Kodiak 9.0 mm, verified 2026-10-02'),
    Rifle(id:'rossi-dione-pcp-55', brand:'Rossi', model:'Dione PCP', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:145, overallLengthMm:990, weightKg:2.60, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — Dione PCP 5.5 mm, verified 2026-10-02'),
    Rifle(id:'rossi-r35-bullpup-55', brand:'Rossi', model:'R35 Bullpup', platform:WeaponPlatform.pcp, caliberMm:5.5, airCapacityCc:300, overallLengthMm:836, weightKg:3.05, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — R35 Bullpup 5.5 mm, verified 2026-10-02'),
    Rifle(id:'rossi-r35-bullpup-635', brand:'Rossi', model:'R35 Bullpup', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:300, overallLengthMm:836, weightKg:3.05, sourceName:'Rossi', sourceDocument:'Rossi 2026 official product catalog — R35 Bullpup 6.35 mm, verified 2026-10-02'),

    // v305: Huben K1 rifle family. Only model/caliber facts directly verified
    // from the current Huben/Wolfiek K1 collection are recorded; unverified
    // numeric specifications are intentionally left absent. GK1 pistols are
    // excluded because the current catalog entity is Rifle.
    Rifle(id:'huben-k1-55', brand:'Huben', model:'K1', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Air Rifle .22 (5.5 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-635', brand:'Huben', model:'K1', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Air Rifle .25 (6.35 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-762', brand:'Huben', model:'K1', platform:WeaponPlatform.pcp, caliberMm:7.62, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Air Rifle .30 (7.62 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-special-edition-55', brand:'Huben', model:'K1 Special Edition', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Special Edition Air Rifle .22 (5.5 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-special-edition-635', brand:'Huben', model:'K1 Special Edition', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Special Edition Air Rifle .25 (6.35 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-special-edition-762', brand:'Huben', model:'K1 Special Edition', platform:WeaponPlatform.pcp, caliberMm:7.62, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/k1-rifle — K1 Special Edition Air Rifle .30 (7.62 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-lite-55', brand:'Huben', model:'K1 Lite Carbon Fiber', platform:WeaponPlatform.pcp, caliberMm:5.5, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/airguns/all-k1 — Wolfiek Huben K1 Lite Carbon Fiber Air Rifle .22 (5.5 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-lite-635', brand:'Huben', model:'K1 Lite Carbon Fiber', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/airguns — Wolfiek Huben K1 Lite Carbon Fiber Air Rifle .25 (6.35 mm), verified 2026-10-02'),
    Rifle(id:'huben-k1-lite-762', brand:'Huben', model:'K1 Lite Carbon Fiber', platform:WeaponPlatform.pcp, caliberMm:7.62, sourceName:'Huben / Wolfiek Group', sourceDocument:'https://www.hubenairguns.shop/collections/airguns — Wolfiek Huben K1 Lite Carbon Fiber Air Rifle .30 (7.62 mm), verified 2026-10-02'),
    Rifle(id:'hatsan-sniper-long-635', brand:'HATSAN', model:'Factor Sniper Long', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:760, airCapacityCc:700, overallLengthMm:1180, weightKg:5, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', moderatorThread:'1/2 UNF', sourceName:'HATSAN', sourceDocument:'HATSAN Factor Sniper L product page, verified 2026-09-24'),
    Rifle(id:'hatsan-hercules-635', brand:'HATSAN', model:'Hercules', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:13, barrelLengthMm:585, airCapacityCc:1000, overallLengthMm:1230, weightKg:5.9, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', sourceName:'HATSAN', sourceDocument:'HATSAN Hercules product page, verified 2026-09-24'),
    // v119: additional HATSAN 6.35 PCP variants verified against current manufacturer pages.
    Rifle(id:'hatsan-hercules-666-635', brand:'HATSAN', model:'Hercules 666', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:13, barrelLengthMm:660, airCapacityCc:1000, overallLengthMm:1270, weightKg:6.2, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', sourceName:'HATSAN', sourceDocument:'HATSAN Hercules 666 official product page, verified 2026-09-26'),
    Rifle(id:'hatsan-hercules-bully-635', brand:'HATSAN', model:'Hercules Bully', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:13, barrelLengthMm:585, airCapacityCc:500, overallLengthMm:920, weightKg:4.65, barrelType:'precision rifled, choked', sourceName:'HATSAN', sourceDocument:'HATSAN Hercules Bully official product page, verified 2026-09-26'),
    // v152: current HATSAN Hercules Bully 777 .25 configuration verified from the manufacturer page.
    Rifle(id:'hatsan-hercules-bully-777-635', brand:'HATSAN', model:'Hercules Bully 777', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:13, barrelLengthMm:760, airCapacityCc:700, overallLengthMm:1080, weightKg:5.3, sourceName:'HATSAN', sourceDocument:'HATSAN Hercules Bully 777 official product page, verified 2026-09-27'),
    Rifle(id:'hatsan-blitz-mevzi-ii-635', brand:'HATSAN', model:'Blitz Mevzi II', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:1160, barrelType:'precision rifled, choked', sourceName:'HATSAN', sourceDocument:'https://hatsan.com.tr/urun/blitz-mevzi/ — official manufacturer page, 580 cc per bottle × 2, verified 2026-09-29'),
    Rifle(id:'hatsan-blitz-mevzi-iii-635', brand:'HATSAN', model:'Blitz Mevzi III', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:1740, barrelType:'precision rifled, choked', sourceName:'HATSAN', sourceDocument:'https://hatsan.com.tr/urun/blitz-mevzi/ — official manufacturer page, 580 cc per bottle × 3, verified 2026-09-29'),
    Rifle(id:'hatsan-blitz-mevzi-iv-635', brand:'HATSAN', model:'Blitz Mevzi IV', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:2320, barrelType:'precision rifled, choked', sourceName:'HATSAN', sourceDocument:'https://hatsan.com.tr/urun/blitz-mevzi/ — official manufacturer page, 580 cc per bottle × 4, verified 2026-09-29'),
    Rifle(id:'hatsan-blitz-635', brand:'HATSAN', model:'Blitz', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:580, overallLengthMm:1150, weightKg:4, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', sourceName:'HATSAN', sourceDocument:'HATSAN Blitz product page, verified 2026-09-24'),
    Rifle(id:'hatsan-factor-635', brand:'HATSAN', model:'Factor', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:500, overallLengthMm:1025, weightKg:3.6, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', moderatorThread:'1/2 UNF', sourceName:'HATSAN', sourceDocument:'HATSAN Factor product page, verified 2026-09-24'),
    Rifle(id:'hatsan-factor-rc-635', brand:'HATSAN', model:'Factor RC', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:580, overallLengthMm:1025, weightKg:3.6, sourceName:'HATSAN', sourceDocument:'HATSAN Factor RC product page, verified 2026-09-24'),
    Rifle(id:'hatsan-factor-bp-635', brand:'HATSAN', model:'Factor BP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:580, overallLengthMm:870, weightKg:3.8, sourceName:'HATSAN', sourceDocument:'HATSAN Factor BP product page, verified 2026-09-24'),
    Rifle(id:'hatsan-factor-sniper-s-635', brand:'HATSAN', model:'Factor Sniper S', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:480, overallLengthMm:1005, weightKg:4.6, sourceName:'HATSAN', sourceDocument:'HATSAN Factor Sniper S product page, verified 2026-09-24'),
    Rifle(id:'hatsan-blitz-bp-635', brand:'HATSAN', model:'Blitz BP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:610, overallLengthMm:905, weightKg:4, barrelType:'precision rifled, choked', rail:'11 mm + 22 mm Picatinny', sourceName:'HATSAN', sourceDocument:'HATSAN Blitz BP product page, verified 2026-09-24'),
    // v151: current HATSAN Blitz 777 .25 configuration verified from the manufacturer page.
    Rifle(id:'hatsan-blitz-777-635', brand:'HATSAN', model:'Blitz 777', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:19, barrelLengthMm:585, airCapacityCc:700, overallLengthMm:905, weightKg:4, sourceName:'HATSAN', sourceDocument:'HATSAN Blitz 777 official product page, verified 2026-09-27'),
    Rifle(id:'hatsan-flash-635', brand:'HATSAN', model:'Flash', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:165, overallLengthMm:915, weightKg:2.5, sourceName:'HATSAN', sourceDocument:'HATSAN Flash product page, verified 2026-09-24'),
    Rifle(id:'hatsan-flash-qe-635', brand:'HATSAN', model:'Flash QE', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:450, airCapacityCc:165, overallLengthMm:1075, weightKg:2.68, sourceName:'HATSAN', sourceDocument:'HATSAN Flash product page, verified 2026-09-24'),
    Rifle(id:'hatsan-repex-635', brand:'HATSAN', model:'Repex', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:432, airCapacityCc:165, overallLengthMm:800, weightKg:2.25, sourceName:'HATSAN', sourceDocument:'HATSAN Repex product page, verified 2026-09-24'),
    // Huğlu 2025 manufacturer catalog lists two Spark configurations. Keep
    // them as separate variants so barrel/reservoir/plenum values are never
    // mixed into one ambiguous record. Weight is a family range in the source,
    // so it is intentionally left null on each variant.
    Rifle(id:'huglu-spark-420-635', brand:'Huğlu', model:'Spark 420', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:420, airCapacityCc:350, plenumCc:70, moderatorThread:'1/2 UNF', sourceName:'Huğlu', sourceDocument:'Huğlu 2025 TR Catalog, pp. 53–54, verified 2026-09-24'),
    Rifle(id:'huglu-spark-600-635', brand:'Huğlu', model:'Spark 600', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:600, airCapacityCc:500, plenumCc:100, moderatorThread:'1/2 UNF', sourceName:'Huğlu', sourceDocument:'Huğlu 2025 TR Catalog, pp. 53–54, verified 2026-09-24'),
    // Current AirMaks manufacturer pages verified 2026-09-27. Keep exact
    // configurations instead of the former unsourced generic "Krait" row.
    Rifle(id:'airmaks-krait-s-635', brand:'AirMaks Arms', model:'Krait S', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:14, barrelLengthMm:400, airCapacityCc:300, overallLengthMm:610, weightKg:2.5, plenumCc:60, barrelType:'choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AirMaks Arms Krait S official product page, verified 2026-09-27'),
    Rifle(id:'airmaks-krait-mkii-s-635', brand:'AirMaks Arms', model:'Krait MK2 S', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:12, barrelLengthMm:400, airCapacityCc:300, overallLengthMm:640, weightKg:3.13, plenumCc:30, barrelType:'choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AirMaks Arms Krait MK2 S official product page, verified 2026-09-27'),
    // AirMaks Arms 2026 manufacturer catalog. Variant-specific values are kept
    // explicit instead of being guessed across the whole Krait family.
    Rifle(id:'airmaks-krait-mkii-lhp-635', brand:'AirMaks Arms', model:'Krait MKII L HP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:12, barrelLengthMm:520, airCapacityCc:580, overallLengthMm:760, weightKg:3.48, plenumCc:115, barrelType:'non-choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-krait-mkii-xhp-635', brand:'AirMaks Arms', model:'Krait MKII X HP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:12, barrelLengthMm:700, airCapacityCc:700, overallLengthMm:940, weightKg:3.82, plenumCc:115, barrelType:'non-choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-krait-pro-635', brand:'AirMaks Arms', model:'Krait PRO', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:14, barrelLengthMm:400, airCapacityCc:300, overallLengthMm:630, weightKg:3.3, barrelType:'choked', rail:'ARCA + M-LOK + Picatinny', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-krait-pro-lhp-635', brand:'AirMaks Arms', model:'Krait PRO L HP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:14, barrelLengthMm:520, airCapacityCc:580, overallLengthMm:750, weightKg:3.8, barrelType:'non-choked', rail:'ARCA + M-LOK + Picatinny', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-krait-pro-xhp-635', brand:'AirMaks Arms', model:'Krait PRO X HP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:14, barrelLengthMm:700, airCapacityCc:700, overallLengthMm:930, weightKg:4.2, barrelType:'non-choked', rail:'ARCA + M-LOK + Picatinny', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-krait-mkii-pro-xhp-635', brand:'AirMaks Arms', model:'Krait MK2 PRO X HP', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:12, barrelLengthMm:700, airCapacityCc:700, overallLengthMm:940, weightKg:4.45, plenumCc:115, barrelType:'non-choked', rail:'Extended top rail + ARCA/M-LOK/Picatinny', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AirMaks Arms KRAIT MK2 PRO X HP official product page, verified 2026-09-27'),
    Rifle(id:'airmaks-caiman-635', brand:'AirMaks Arms', model:'Caiman', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:8, barrelLengthMm:400, barrelType:'choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    Rifle(id:'airmaks-caiman-x-635', brand:'AirMaks Arms', model:'Caiman X', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:8, barrelLengthMm:520, barrelType:'choked', rail:'Picatinny 20 MOA', moderatorThread:'1/2 UNF', sourceName:'AirMaks Arms', sourceDocument:'AMA Catalog 2026'),
    // Challenger Pro .25 values cross-checked against the current Airgun
    // Armoury product listing on 2026-09-27. Keep retailer provenance explicit
    // rather than presenting third-party specifications as manufacturer data.
    Rifle(id:'aea-challenger-pro-635', brand:'AEA', model:'Challenger Pro', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:610, airCapacityCc:350, overallLengthMm:840, weightKg:3.72, rail:'Picatinny/Weaver', sourceName:'Airgun Armoury', sourceDocument:'AEA Challenger PRO product page (.25 / 6.35 mm), verified 2026-09-27'),
    // FX Airguns current/legacy manufacturer pages verified 2026-09-25.
    // Only values unambiguously published for the family/configuration are
    // imported; unspecified variant dimensions remain null rather than guessed.
    Rifle(id:'fx-dreamline-classic-45', brand:'FX Airguns', model:'Dreamline Classic', platform:WeaponPlatform.pcp, caliberMm:4.5, magazineCapacity:22, barrelLengthMm:500, airCapacityCc:220, overallLengthMm:975, weightKg:2.6, barrelType:'FX Smooth Twist X Match grade', rail:'11 mm dovetail', moderatorThread:'1/2 UNF', sourceName:'FX Airguns', sourceDocument:'FX Airguns Dreamline Classic official brochure; .177 synthetic configuration, verified 2026-09-27'),
    Rifle(id:'fx-dreamline-classic-55', brand:'FX Airguns', model:'Dreamline Classic', platform:WeaponPlatform.pcp, caliberMm:5.5, magazineCapacity:18, barrelLengthMm:500, airCapacityCc:220, overallLengthMm:975, weightKg:2.6, barrelType:'FX Smooth Twist X Match grade', rail:'11 mm dovetail', moderatorThread:'1/2 UNF', sourceName:'FX Airguns', sourceDocument:'FX Airguns Dreamline Classic official brochure; .22 synthetic configuration, verified 2026-09-27'),
    Rifle(id:'fx-dreamline-classic-635', brand:'FX Airguns', model:'Dreamline Classic', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:16, barrelLengthMm:600, airCapacityCc:290, overallLengthMm:1090, weightKg:2.6, barrelType:'FX Smooth Twist X Match grade', rail:'11 mm dovetail', moderatorThread:'1/2 UNF', sourceName:'FX Airguns', sourceDocument:'FX Airguns Dreamline Classic official brochure; .25 synthetic configuration, verified 2026-09-27'),
    Rifle(id:'fx-panthera-500-635', brand:'FX Airguns', model:'Panthera 500', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelLengthMm:500, airCapacityCc:300, barrelType:'FX Superior STX', rail:'Picatinny 20 MOA + ARCA/M-LOK', sourceName:'FX Airguns', sourceDocument:'FX Panthera official legacy product page, verified 2026-09-25'),
    Rifle(id:'fx-panthera-600-635', brand:'FX Airguns', model:'Panthera 600', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelLengthMm:600, airCapacityCc:300, plenumCc:156, barrelType:'FX Superior Heavy STX', rail:'Picatinny 20 MOA + ARCA/M-LOK', sourceName:'FX Airguns', sourceDocument:'FX Panthera official legacy product page, verified 2026-09-25'),
    Rifle(id:'fx-panthera-700-635', brand:'FX Airguns', model:'Panthera 700', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelLengthMm:700, airCapacityCc:300, plenumCc:156, barrelType:'FX Superior Heavy STX', rail:'Picatinny 20 MOA + ARCA/M-LOK', sourceName:'FX Airguns', sourceDocument:'FX Panthera official legacy product page, verified 2026-09-25'),
    Rifle(id:'fx-dynamic-635', brand:'FX Airguns', model:'Dynamic', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:480, plenumCc:156, rail:'ARCA + M-LOK', moderatorThread:'1/2 UNF', sourceName:'FX Airguns', sourceDocument:'FX Dynamic official legacy product page, verified 2026-09-25'),
    Rifle(id:'fx-king-635', brand:'FX Airguns', model:'King', platform:WeaponPlatform.pcp, caliberMm:6.35, plenumCc:156, rail:'Picatinny 30 MOA', sourceName:'FX Airguns', sourceDocument:'FX King official product page, verified 2026-09-25'),
    Rifle(id:'fx-drs-mkii-tactical-635', brand:'FX Airguns', model:'DRS Tactical MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:760, plenumCc:53, rail:'Picatinny 30 MOA + M-LOK', sourceName:'FX Airguns', sourceDocument:'FX DRS Tactical MKII official product page, verified 2026-09-25'),
    // v106: additional current FX 6.35 models verified from manufacturer pages.
    // Variant-dependent bottle/barrel/plenum values are deliberately omitted unless the
    // current page unambiguously binds them to this catalog record.
    Rifle(id:'fx-impact-m4-635', brand:'FX Airguns', model:'Impact M4', platform:WeaponPlatform.pcp, caliberMm:6.35, plenumCc:75, barrelType:'FX STX liner system', sourceName:'FX Airguns', sourceDocument:'FX Impact M4 official product page, verified 2026-09-25'),
    Rifle(id:'fx-crown-mkii-635', brand:'FX Airguns', model:'Crown MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelType:'Superlight Smooth Twist X (STX)', rail:'Picatinny 20 MOA', sourceName:'FX Airguns', sourceDocument:'FX Crown MKII official product page, verified 2026-09-25'),
    Rifle(id:'fx-wildcat-mkiii-635', brand:'FX Airguns', model:'Wildcat MKIII', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'FX Airguns', sourceDocument:'FX Wildcat MKIII official product page, verified 2026-09-25'),
    Rifle(id:'fx-drs-mkii-classic-635', brand:'FX Airguns', model:'DRS Classic MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelType:'APB barrel with FX interchangeable liner system', rail:'Picatinny 30 MOA', sourceName:'FX Airguns', sourceDocument:'FX DRS Classic MKII official product page, verified 2026-09-25'),
    Rifle(id:'fx-drs-mkii-pro-635', brand:'FX Airguns', model:'DRS Pro MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, barrelType:'APB barrel with FX interchangeable liner system', rail:'Picatinny 30 MOA + M-LOK', sourceName:'FX Airguns', sourceDocument:'FX DRS Pro MKII official product page, verified 2026-09-25'),
    // v207: current FX lineup gaps, manufacturer-verified 2026-09-29. Only values explicitly published on the official pages are stored.
    Rifle(id:'fx-leopard-635', brand:'FX Airguns', model:'Leopard', platform:WeaponPlatform.pcp, caliberMm:6.35, airCapacityCc:890, plenumCc:54, barrelType:'APB barrel with FX interchangeable liner system', sourceName:'FX Airguns', sourceDocument:'FX Leopard official product page, verified 2026-09-29'),
    Rifle(id:'fx-panthera-mkii-635', brand:'FX Airguns', model:'Panthera MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, rail:'30 MOA extended scope rail + full-length ARCA + M-LOK', sourceName:'FX Airguns', sourceDocument:'FX Panthera MKII official product page, verified 2026-09-29'),
    Rifle(id:'fx-dynamic-mkii-635', brand:'FX Airguns', model:'Dynamic MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, rail:'30 MOA extended scope rail + full-length ARCA + M-LOK', sourceName:'FX Airguns', sourceDocument:'FX Dynamic MKII official product page, verified 2026-09-29'),

    // Verified PCP catalog expansion v72. Model names come from current manufacturer sources.
    Rifle(id:'niksan-elf-s', brand:'Niksan', model:'ELF-S', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-elf-w', brand:'Niksan', model:'ELF-W', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-elf-c', brand:'Niksan', model:'ELF-C', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-ozark-w', brand:'Niksan', model:'OZARK-W', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-ozark-tw', brand:'Niksan', model:'OZARK-TW', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-ozark-ts', brand:'Niksan', model:'OZARK-TS', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-ozark-tc', brand:'Niksan', model:'OZARK-TC', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-escalade-s', brand:'Niksan', model:'ESCALADE-S', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-escalade-c', brand:'Niksan', model:'ESCALADE-C', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-escalade-t', brand:'Niksan', model:'ESCALADE-T', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-escalade-tc', brand:'Niksan', model:'ESCALADE-TC', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-archero-s', brand:'Niksan', model:'ARCHERO-S', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-archero-c', brand:'Niksan', model:'ARCHERO-C', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-tacto-s', brand:'Niksan', model:'TACTO-S', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'niksan-tacto-c', brand:'Niksan', model:'TACTO-C', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Niksan Defence', sourceDocument:'Niksan Defence official PCP Air Rifles catalog, verified 2026-09-24'),
    Rifle(id:'effecto-px5-standard', brand:'Effecto', model:'PX-5 Standard', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Effecto Airguns', sourceDocument:'Effecto official shop current airguns collection, verified 2026-09-24'),
    Rifle(id:'effecto-px5-pro', brand:'Effecto', model:'PX-5 Pro', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Effecto Airguns', sourceDocument:'Effecto official shop current airguns collection, verified 2026-09-24'),
    Rifle(id:'effecto-px5-sport', brand:'Effecto', model:'PX-5 Sport', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Effecto Airguns', sourceDocument:'Effecto official shop current airguns collection, verified 2026-09-24'),
    Rifle(id:'effecto-zeon', brand:'Effecto', model:'Zeon', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Effecto Airguns', sourceDocument:'Effecto official shop current airguns collection, verified 2026-09-24'),
    Rifle(id:'daystate-alpha-wolf', brand:'Daystate', model:'Alpha Wolf', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-blackwolf', brand:'Daystate', model:'Blackwolf', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-delta-wolf', brand:'Daystate', model:'Delta Wolf', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-red-wolf', brand:'Daystate', model:'Red Wolf', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-huntsman-revere', brand:'Daystate', model:'Huntsman Revere', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-wolverine-r', brand:'Daystate', model:'Wolverine R', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    Rifle(id:'daystate-red-wolf-grand-prix', brand:'Daystate', model:'Red Wolf Grand Prix', platform:WeaponPlatform.pcp, caliberMm:6.35, sourceName:'Daystate', sourceDocument:'Daystate official product range / 2026 brochure, verified 2026-09-24'),
    // v210: current Kral Arms Puncher PCP 6.35 mm lineup, copied only from
    // manufacturer-published product pages. Values not published by Kral are
    // intentionally left null rather than inferred from related variants.
    Rifle(id:'kral-nish-s-635', brand:'Kral Arms', model:'NISH S', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:530, airCapacityCc:280, overallLengthMm:1000, weightKg:3.30, sourceName:'Kral Arms', sourceDocument:'Kral Arms NISH S official product page, verified 2026-09-29'),
    Rifle(id:'kral-nish-w-635', brand:'Kral Arms', model:'NISH W', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:530, airCapacityCc:280, overallLengthMm:1000, weightKg:3.65, sourceName:'Kral Arms', sourceDocument:'Kral Arms NISH W official product page, verified 2026-09-29'),
    Rifle(id:'kral-empire-635', brand:'Kral Arms', model:'Empire', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:480, airCapacityCc:330, overallLengthMm:760, weightKg:3.90, sourceName:'Kral Arms', sourceDocument:'Kral Arms Empire official product page, verified 2026-09-29'),
    Rifle(id:'kral-empire-x-635', brand:'Kral Arms', model:'Empire X', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:480, airCapacityCc:600, overallLengthMm:760, weightKg:3.60, sourceName:'Kral Arms', sourceDocument:'Kral Arms Empire X official product page, verified 2026-09-29'),
    Rifle(id:'kral-knight-635', brand:'Kral Arms', model:'Knight', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:580, airCapacityCc:500, overallLengthMm:875, weightKg:4.0, sourceName:'Kral Arms', sourceDocument:'Kral Arms Knight official product page, verified 2026-09-29'),
    Rifle(id:'kral-mortal-x-635', brand:'Kral Arms', model:'Mortal X', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:580, airCapacityCc:330, overallLengthMm:1010, weightKg:4.05, sourceName:'Kral Arms', sourceDocument:'Kral Arms Mortal X official product page, verified 2026-09-29'),
    Rifle(id:'kral-bighorn-635', brand:'Kral Arms', model:'Bighorn', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:580, airCapacityCc:500, overallLengthMm:1050, weightKg:3.70, sourceName:'Kral Arms', sourceDocument:'Kral Arms Bighorn official product page, verified 2026-09-29'),
    Rifle(id:'kral-rambo-635', brand:'Kral Arms', model:'Rambo Pump Action', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:530, airCapacityCc:280, overallLengthMm:915, weightKg:3.40, sourceName:'Kral Arms', sourceDocument:'Kral Arms Rambo Pump Action official product page, verified 2026-09-29'),
    Rifle(id:'kral-pro-500-635', brand:'Kral Arms', model:'PRO 500', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:530, airCapacityCc:500, overallLengthMm:1050, weightKg:3.80, sourceName:'Kral Arms', sourceDocument:'Kral Arms PRO 500 official product page, verified 2026-09-29'),
    Rifle(id:'kral-shadow-635', brand:'Kral Arms', model:'Shadow', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:530, airCapacityCc:500, overallLengthMm:1050, weightKg:3.50, sourceName:'Kral Arms', sourceDocument:'Kral Arms Shadow official product page, verified 2026-09-29'),
    Rifle(id:'kral-np03-635', brand:'Kral Arms', model:'Puncher NP-03', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:407, airCapacityCc:180, overallLengthMm:572, weightKg:3.00, sourceName:'Kral Arms', sourceDocument:'Kral Arms Puncher NP-03 official product page, verified 2026-09-29'),
    Rifle(id:'kral-np02-635', brand:'Kral Arms', model:'Puncher NP-02', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:330, airCapacityCc:530, overallLengthMm:770, weightKg:3.10, sourceName:'Kral Arms', sourceDocument:'Kral Arms Puncher NP-02 official product page, verified 2026-09-29'),
    Rifle(id:'kral-np500-635', brand:'Kral Arms', model:'NP 500', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:407, airCapacityCc:500, overallLengthMm:770, weightKg:3.70, sourceName:'Kral Arms', sourceDocument:'Kral Arms NP 500 official product page, verified 2026-09-29'),
    Rifle(id:'kral-auto-635', brand:'Kral Arms', model:'Auto', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:480, airCapacityCc:425, overallLengthMm:730, weightKg:3.65, sourceName:'Kral Arms', sourceDocument:'Kral Arms Auto official product page, verified 2026-09-29'),
    Rifle(id:'kral-mortal-635', brand:'Kral Arms', model:'Mortal', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:407, airCapacityCc:200, overallLengthMm:840, weightKg:3.51, sourceName:'Kral Arms', sourceDocument:'Kral Arms Mortal official product page, verified 2026-09-29'),
    Rifle(id:'kral-unica-635', brand:'Kral Arms', model:'Unica', platform:WeaponPlatform.pcp, caliberMm:6.35, magazineCapacity:10, barrelLengthMm:580, airCapacityCc:330, overallLengthMm:1050, weightKg:4.20, sourceName:'Kral Arms', sourceDocument:'Kral Arms Unica official product page, verified 2026-09-29'),
    // Manufacturer-verified firearm catalog records. Caliber variants are
    // separate records so profile/ammunition filtering never conflates them.
    Rifle(id:'ata-turqua-308', brand:'ATA Arms', model:'Turqua .308 Win', platform:WeaponPlatform.firearm, caliberMm:7.62, magazineCapacity:5, weightKg:3.4, barrelType:'bolt-action, button-rifled chrome-moly steel, 1:11 twist', rail:'22 mm MIL-STD-1913 Picatinny', sourceName:'ATA Arms', sourceDocument:'ATA official catalog — TURQUA technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-turqua-243', brand:'ATA Arms', model:'Turqua .243 Win', platform:WeaponPlatform.firearm, caliberMm:6.17, magazineCapacity:5, weightKg:3.4, barrelType:'bolt-action, button-rifled chrome-moly steel, 1:10 twist', rail:'22 mm MIL-STD-1913 Picatinny', sourceName:'ATA Arms', sourceDocument:'ATA official catalog — TURQUA technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-turqua-65cm', brand:'ATA Arms', model:'Turqua 6.5 Creedmoor', platform:WeaponPlatform.firearm, caliberMm:6.5, magazineCapacity:5, weightKg:3.4, barrelType:'bolt-action, button-rifled chrome-moly steel, 1:8 twist', rail:'22 mm MIL-STD-1913 Picatinny', sourceName:'ATA Arms', sourceDocument:'ATA official catalog — TURQUA technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-asr-308', brand:'ATA Arms', model:'ASR .308 Win', platform:WeaponPlatform.firearm, caliberMm:7.62, magazineCapacity:10, overallLengthMm:1180, weightKg:6.0, barrelType:'bolt-action, 1:11 twist', rail:'20/30 MOA STANAG MIL-STD-1913', sourceName:'ATA Arms', sourceDocument:'ATA ASR official technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-asr-300wm', brand:'ATA Arms', model:'ASR .300 Win Mag', platform:WeaponPlatform.firearm, caliberMm:7.62, magazineCapacity:10, overallLengthMm:1180, weightKg:6.2, barrelType:'bolt-action, 1:10 twist', rail:'20/30 MOA STANAG MIL-STD-1913', sourceName:'ATA Arms', sourceDocument:'ATA ASR official technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-asr-338lm', brand:'ATA Arms', model:'ASR .338 Lapua Mag', platform:WeaponPlatform.firearm, caliberMm:8.59, magazineCapacity:10, overallLengthMm:1180, weightKg:6.2, barrelType:'bolt-action, 1:10 twist', rail:'20/30 MOA STANAG MIL-STD-1913', sourceName:'ATA Arms', sourceDocument:'ATA ASR official technical specifications, verified 2026-09-24'),
    Rifle(id:'ata-asr-65cm', brand:'ATA Arms', model:'ASR 6.5 Creedmoor', platform:WeaponPlatform.firearm, caliberMm:6.5, magazineCapacity:10, overallLengthMm:1180, weightKg:6.0, barrelType:'bolt-action, 1:8 twist', rail:'20/30 MOA STANAG MIL-STD-1913', sourceName:'ATA Arms', sourceDocument:'ATA ASR official technical specifications, verified 2026-09-24'),
    Rifle(id:'sarsilmaz-mpt76sh', brand:'Sarsılmaz', model:'MPT 76 SH', platform:WeaponPlatform.firearm, caliberMm:7.62, magazineCapacity:20, barrelLengthMm:406, overallLengthMm:990, weightKg:3.89, barrelType:'rifled, 1:10 twist', sourceName:'Sarsılmaz', sourceDocument:'Sarsılmaz official MPT 76 SH product page, verified 2026-09-24'),
    Rifle(id:'sarsilmaz-sar308', brand:'Sarsılmaz', model:'SAR 308', platform:WeaponPlatform.firearm, caliberMm:7.62, magazineCapacity:30, barrelLengthMm:413, overallLengthMm:910, weightKg:3.55, barrelType:'rifled, 1:9.8 twist', sourceName:'Sarsılmaz', sourceDocument:'Sarsılmaz official SAR 308 product page, verified 2026-09-24'),
    Rifle(id:'sarsilmaz-sar56-75', brand:'Sarsılmaz', model:'SAR 56 7.5 inch', platform:WeaponPlatform.firearm, caliberMm:5.56, magazineCapacity:30, barrelLengthMm:190, overallLengthMm:670, weightKg:3.05, barrelType:'rifled, 1:7 twist', sourceName:'Sarsılmaz', sourceDocument:'Sarsılmaz official SAR 56 7.5 product page, verified 2026-09-24'),
    Rifle(id:'sarsilmaz-sar56-11', brand:'Sarsılmaz', model:'SAR 56 11 inch', platform:WeaponPlatform.firearm, caliberMm:5.56, magazineCapacity:30, barrelLengthMm:280, overallLengthMm:805, weightKg:3.31, barrelType:'rifled, 1:7 twist', sourceName:'Sarsılmaz', sourceDocument:'Sarsılmaz official SAR 56 11 product page, verified 2026-09-24'),
    Rifle(id:'sarsilmaz-sar56-145', brand:'Sarsılmaz', model:'SAR 56 14.5 inch', platform:WeaponPlatform.firearm, caliberMm:5.56, magazineCapacity:30, barrelLengthMm:369, overallLengthMm:880, weightKg:3.49, barrelType:'rifled, 1:7 twist', sourceName:'Sarsılmaz', sourceDocument:'Sarsılmaz official SAR 56 14.5 product page, verified 2026-09-24'),
    Rifle(id:'manual-firearm', brand:'Manuel', model:'Ateşli Tüfek', platform:WeaponPlatform.firearm, caliberMm:7.62),
  ];
  static const ammunition = <Ammunition>[
    // v260: archival 2017 manufacturer catalog, NOT confirmed currently sold.
    Ammunition(id:'airventuri-av45-454-rb-137', brand:'Air Venturi', model:'Big Bore .45 .454 round ball [2017 archival]', platform:WeaponPlatform.pcp, caliberMm:11.53, grain:137, type:AmmunitionType.bullet, sourceName:'Air Venturi 2017 archival catalog', sourceDocument:'https://www.airventuri.com/images/airventuri/Air-Venturi-Catalog-2017-low-res.pdf — SKU AV.45/.454/RB; historical only, current availability unverified'),
    Ammunition(id:'airventuri-av45-457-rb-143', brand:'Air Venturi', model:'Big Bore .45 .457 round ball [2017 archival]', platform:WeaponPlatform.pcp, caliberMm:11.61, grain:143, type:AmmunitionType.bullet, sourceName:'Air Venturi 2017 archival catalog', sourceDocument:'https://www.airventuri.com/images/airventuri/Air-Venturi-Catalog-2017-low-res.pdf — SKU AV.45/.457/RB; historical only, current availability unverified'),
    Ammunition(id:'airventuri-av45-166-fp', brand:'Air Venturi', model:'Big Bore .45 166 gr flat point [2017 archival]', platform:WeaponPlatform.pcp, caliberMm:11.43, grain:166, type:AmmunitionType.bullet, sourceName:'Air Venturi 2017 archival catalog', sourceDocument:'https://www.airventuri.com/images/airventuri/Air-Venturi-Catalog-2017-low-res.pdf — SKU AV.45/166gr/FP; historical only, current availability unverified'),

    // User-specific G Maz entry is retained, but remains unsourced until a
    // manufacturer/public technical sheet is available. No BC is invented.
    Ammunition(id:'gmaz-51', brand:'G Maz', model:'No:30 Slug', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:51, type:AmmunitionType.slug, sourceName:'Kullanıcı girdisi', sourceDocument:'Kullanıcı tarafından bildirilen ürün adı/ağırlığı; kamuya açık üretici teknik föyü doğrulanamadı, 2026-09-27'),
    // Manufacturer-verified PCP ammunition. Source provenance is stored with
    // every imported record; BC is intentionally null unless the manufacturer
    // publishes both a coefficient and drag model.
    Ammunition(id:'fx-premium-177-8_4', brand:'FX Airguns', model:'Premium Pellet .177 8.4 gr', platform:WeaponPlatform.pcp, caliberMm:4.52, grain:8.4, type:AmmunitionType.pellet, sourceName:'FX Airguns', sourceDocument:'FX Premium Pellets official product page, verified 2026-09-25'),
    Ammunition(id:'fx-premium-22-15_9', brand:'FX Airguns', model:'Premium Pellet .22 15.9 gr', platform:WeaponPlatform.pcp, caliberMm:5.52, grain:15.9, type:AmmunitionType.pellet, sourceName:'FX Airguns', sourceDocument:'FX Premium Pellets official product page, verified 2026-09-25'),
    Ammunition(id:'fx-premium-22-18_1', brand:'FX Airguns', model:'Premium Pellet .22 18.1 gr', platform:WeaponPlatform.pcp, caliberMm:5.52, grain:18.1, type:AmmunitionType.pellet, sourceName:'FX Airguns', sourceDocument:'FX Premium Pellets official product page, verified 2026-09-25'),
    Ammunition(id:'fx-premium-25-25_4', brand:'FX Airguns', model:'Premium Pellet .25 25.4 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:25.4, type:AmmunitionType.pellet, sourceName:'FX Airguns', sourceDocument:'FX Premium Pellets official product page, verified 2026-09-24'),
    Ammunition(id:'fx-premium-25-34', brand:'FX Airguns', model:'Premium Pellet .25 34 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:34, type:AmmunitionType.pellet, sourceName:'FX Airguns', sourceDocument:'FX Premium Pellets official product page, verified 2026-09-24'),
    // v153: current JSB manufacturer catalog coverage for the two smaller PCP calibers.
    // Values are copied from JSB's current official catalog filters/product family; no BC is inferred.
    Ammunition(id:'jsb-exact-177-8_44', brand:'JSB Match Diabolo', model:'Exact .177', platform:WeaponPlatform.pcp, caliberMm:4.52, grain:8.44, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB official EXACT catalog; 4.52 mm / 0.547 g / 8.44 gr, verified 2026-09-27'),
    Ammunition(id:'jsb-exact-heavy-177-10_34', brand:'JSB Match Diabolo', model:'Exact Heavy .177', platform:WeaponPlatform.pcp, caliberMm:4.52, grain:10.34, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB official Exact Heavy product/catalog; 4.52 mm / 0.670 g / 10.34 gr, verified 2026-09-27'),
    Ammunition(id:'jsb-exact-jumbo-22-15_89', brand:'JSB Match Diabolo', model:'Exact Jumbo .22', platform:WeaponPlatform.pcp, caliberMm:5.52, grain:15.89, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB official EXACT JUMBO catalog; 5.52 mm / 1.030 g / 15.89 gr, verified 2026-09-27'),
    Ammunition(id:'jsb-exact-jumbo-heavy-22-18_13', brand:'JSB Match Diabolo', model:'Exact Jumbo Heavy .22', platform:WeaponPlatform.pcp, caliberMm:5.52, grain:18.13, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB official Exact Jumbo Heavy product/catalog; 5.52 mm / 1.175 g / 18.13 gr, verified 2026-09-27'),
    Ammunition(id:'jsb-knockout-mkii-25', brand:'JSB Match Diabolo', model:'KnockOut .25 MKII', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:33.49, type:AmmunitionType.slug, sourceName:'JSB Match Diabolo', sourceDocument:'JSB Slugs official product page; 6.35 mm / 2.17 g, verified 2026-09-24'),
    // v122: official JSB .25 Exact King family. JSB publishes the .25/6.35 mm
    // family and 1.645 g / 2.200 g weight variants. Grain values below are
    // deterministic unit conversions (1 g = 15.4323583529 gr), not BC estimates.
    Ammunition(id:'jsb-exact-king-25', brand:'JSB Match Diabolo', model:'Exact King .25', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:25.39, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB Diabolo Exact King cal .25 official product page; 6.35 mm / 1.645 g, verified 2026-09-26'),
    Ammunition(id:'jsb-exact-king-heavy-25', brand:'JSB Match Diabolo', model:'Exact King Heavy .25', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:33.95, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB Diabolo Exact King Heavy official product page; 6.35 mm / 2.200 g, verified 2026-09-26'),
    Ammunition(id:'jsb-exact-king-heavy-mkii-25', brand:'JSB Match Diabolo', model:'Exact King Heavy MKII .25', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:33.95, type:AmmunitionType.pellet, sourceName:'JSB Match Diabolo', sourceDocument:'JSB Diabolo Exact King Heavy MKII official product page; 6.35 mm / 2.200 g, verified 2026-09-26'),
    // v196: first manufacturer-verified firearm ammunition records. MKE's
    // official product pages publish projectile mass in grams; grain values are
    // deterministic conversions (1 g = 15.4323583529 gr). No BC is inferred.
    Ammunition(id:'mke-556x45-polymer', brand:'MKE', model:'5.56×45 Polimer Tip Fişek', platform:WeaponPlatform.firearm, caliberMm:5.56, grain:49.38, type:AmmunitionType.bullet, sourceName:'MKE', sourceDocument:'MKE official 5.56 mm x 45 Polimer Tip Fişek product page; projectile 3.20 g, verified 2026-09-28'),
    Ammunition(id:'mke-556x45-m193', brand:'MKE', model:'5.56×45 Fişek (M193)', platform:WeaponPlatform.firearm, caliberMm:5.56, grain:54.78, type:AmmunitionType.bullet, sourceName:'MKE', sourceDocument:'MKE official 5.56 mm x 45 Fişek (M193) product page; projectile 3.55 ± 0.1 g, verified 2026-09-28'),
    // v220: My Bullet official website / published manufacturer Q&A, checked 2026-09-29.
    // The manufacturer describes 5.5 mm pellets but does not publish weights on this page,
    // so only the four explicitly named 6.35 mm slug variants are model records.
    Ammunition(id:'mybullet-hp-635-32', brand:'My Bullet', model:'Hollow Point Slug 6.35 mm 32 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:32, type:AmmunitionType.slug, sourceName:'My Bullet', sourceDocument:'https://mybullet.com.tr/ official manufacturer FAQ; 6.35 mm 32 grain Hollow Point Slug, checked 2026-09-29'),
    Ammunition(id:'mybullet-hp-635-38', brand:'My Bullet', model:'Hollow Point Slug 6.35 mm 38 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:38, type:AmmunitionType.slug, sourceName:'My Bullet', sourceDocument:'https://mybullet.com.tr/ official manufacturer FAQ; 6.35 mm 38 grain Hollow Point Slug, checked 2026-09-29'),
    Ammunition(id:'mybullet-hp-635-45', brand:'My Bullet', model:'Hollow Point Slug 6.35 mm 45 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:45, type:AmmunitionType.slug, sourceName:'My Bullet', sourceDocument:'https://mybullet.com.tr/ official manufacturer FAQ; 6.35 mm 45 grain Hollow Point Slug, checked 2026-09-29'),
    Ammunition(id:'mybullet-hp-635-60', brand:'My Bullet', model:'Hollow Point Slug 6.35 mm 60 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:60, type:AmmunitionType.slug, sourceName:'My Bullet', sourceDocument:'https://mybullet.com.tr/ official manufacturer FAQ; 6.35 mm 60 grain Hollow Point Slug, checked 2026-09-29'),
    // Manual templates stay available for data entry but are clearly separate
    // from manufacturer-verified catalog records.
    // v211: current H&N .25 slug families verified from the manufacturer catalog.
    // H&N publishes BC values but the public product pages do not identify a G1/G7
    // drag model, so BC is intentionally left null rather than assigning a model.
    Ammunition(id:'hn-slug-hp2-25-28', brand:'H&N Sport', model:'Slug HP II .25 28 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:28, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Slug HP II .25 28 gr official product listing; verified 2026-09-29'),
    Ammunition(id:'hn-slug-hp2-25-30', brand:'H&N Sport', model:'Slug HP II .25 30 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:30, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Slug HP II .25 30 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-slug-hp2-25-32', brand:'H&N Sport', model:'Slug HP II .25 32 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:32, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Slug HP II .25 32 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-slug-hp2-25-34', brand:'H&N Sport', model:'Slug HP II .25 34 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:34, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Slug HP II .25 34 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-slug-hp2-25-36', brand:'H&N Sport', model:'Slug HP II .25 36 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:36, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Slug HP II .25 36 gr official product listing; verified 2026-09-29'),
    Ammunition(id:'hn-heavy-slug-25-38', brand:'H&N Sport', model:'Heavy Slug .25 38 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:38, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Heavy Slug .25 38 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-heavy-slug-25-42', brand:'H&N Sport', model:'Heavy Slug .25 42 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:42, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Heavy Slug .25 42 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-heavy-slug-25-44', brand:'H&N Sport', model:'Heavy Slug .25 44 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:44, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Heavy Slug .25 44 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-heavy-slug-25-46', brand:'H&N Sport', model:'Heavy Slug .25 46 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:46, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Heavy Slug .25 46 gr official product page; verified 2026-09-29'),
    Ammunition(id:'hn-heavy-slug-25-48', brand:'H&N Sport', model:'Heavy Slug .25 48 gr', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:48, type:AmmunitionType.slug, sourceName:'H&N Sport', sourceDocument:'H&N Heavy Slug .25 48 gr official product page; verified 2026-09-29'),
    Ammunition(id:'pcp-635-34', brand:'Manuel', model:'6.35 Pellet', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:34, type:AmmunitionType.pellet),
    Ammunition(id:'pcp-635-50', brand:'Manuel', model:'6.35 Slug', platform:WeaponPlatform.pcp, caliberMm:6.35, grain:50, type:AmmunitionType.slug),
    Ammunition(id:'firearm-manual', brand:'Manuel', model:'Ateşli Mühimmat', platform:WeaponPlatform.firearm, caliberMm:7.62, grain:150, type:AmmunitionType.bullet),
  ];
  static const scopes = <ScopeOptic>[
    ScopeOptic(
      id:'gazi-6-36', brand:'Gazi Sniper', model:'6–36×56 FFP',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:6, maxMagnification:36,
      elevationRangeMrad:26, windageRangeMrad:14.5, lengthMm:335, weightG:870,
      firstFocalPlane:true, reticle:'FFP', sourceName:'Gazi Sniper',
      sourceDocument:'Gazi Sniper 6-36x56 official product page, verified 2026-09-24',
    ),
    ScopeOptic(
      id:'discovery-xed', brand:'Discovery Optics', model:'XED 6–36×56 FFP MRAD Zero Stop',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:67, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:35, minMagnification:6, maxMagnification:36,
      elevationRangeMrad:35, windageRangeMrad:18, lengthMm:425, weightG:1287,
      firstFocalPlane:true, zeroStop:true, reticle:'MRAD', sourceName:'DISCOVERYOPT',
      sourceDocument:'DISCOVERYOPT XED 6-36X56 official product page, verified 2026-09-24',
    ),
    ScopeOptic(
      id:'discovery-xed-moa', brand:'Discovery Optics', model:'XED 6–36×56 FFP MOA Zero Stop',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:67, clickValue:0.25, clickUnit:AngularUnit.moa,
      tubeDiameterMm:35, minMagnification:6, maxMagnification:36,
      lengthMm:425, weightG:1287, firstFocalPlane:true, zeroStop:true, reticle:'MOA',
      sourceName:'DISCOVERYOPT', sourceDocument:'https://discoveryopt.com/products/xed-6-36x56-scope — official MRAD/MOA variant listing, verified 2026-09-29',
    ),
    ScopeOptic(
      id:'arken-ep5', brand:'Arken Optics', model:'EP-5 GENII 7–35×56 FFP VPR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:7, maxMagnification:35,
      elevationRangeMrad:30, windageRangeMrad:15, lengthMm:406.4, weightG:1190.68,
      firstFocalPlane:true, zeroStop:true, reticle:'VPR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken Optics official EP-5 GENII 7-35x56 product page, verified 2026-09-28',
    ),
    ScopeOptic(
      id:'arken-ep5-gen2-7-35-tor-mil', brand:'Arken Optics', model:'EP-5 GENII 7–35×56 FFP TOR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:7, maxMagnification:35,
      elevationRangeMrad:30, windageRangeMrad:15, lengthMm:406.4, weightG:1190.68,
      firstFocalPlane:true, zeroStop:true, reticle:'TOR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken Optics official EP-5 GENII 7-35x56 product page, verified 2026-09-28',
    ),
    // v116: manufacturer-verified optics requested for the production catalog.
    // MRAD variants are represented explicitly so click/range units cannot be
    // confused with the MOA versions sold on the same manufacturer pages.
    ScopeOptic(
      id:'arken-sh4j-gen2-6-24', brand:'Arken Optics', model:'SH-4J GENII 6–24×50 FFP VPR (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:6, maxMagnification:24,
      elevationRangeMrad:30, windageRangeMrad:16, lengthMm:353.06, weightG:1020.58,
      firstFocalPlane:true, zeroStop:true, reticle:'VPR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'SH-4J GENII 6-24x50 official product page, verified 2026-09-26',
    ),
    ScopeOptic(
      id:'discovery-hd-gen2-5-30', brand:'Discovery Optics', model:'HD GEN II 5–30×56 FFP-Z (MRAD)',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:67, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:30,
      elevationRangeMrad:33, windageRangeMrad:17, lengthMm:380, weightG:1080,
      firstFocalPlane:true, zeroStop:true, reticle:'MRAD', sourceName:'DISCOVERYOPT',
      sourceDocument:'HD GEN II 5-30x56 official product page, verified 2026-09-26',
    ),

    // v155: DISCOVERYOPT official product-page expansion (MRAD/MIL variants).
    ScopeOptic(
      id:'discovery-ed-prs-gen2-5-25', brand:'Discovery Optics', model:'ED-PRS GEN II 5–25×56 FFP-Z (MRAD)',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:67, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      elevationRangeMrad:36, windageRangeMrad:17, lengthMm:415, weightG:1260,
      firstFocalPlane:true, zeroStop:true, reticle:'MRAD', sourceName:'DISCOVERYOPT',
      sourceDocument:'DISCOVERYOPT ED-PRS GEN II 5-25x56 official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'discovery-ed-elr-gen2-5-40', brand:'Discovery Optics', model:'ED-ELR GEN II 5–40×56 FFP-Z (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:35, minMagnification:5, maxMagnification:40,
      elevationRangeMrad:25, windageRangeMrad:18, lengthMm:423, weightG:1279,
      firstFocalPlane:true, zeroStop:true, reticle:'MRAD', sourceName:'DISCOVERYOPT',
      sourceDocument:'DISCOVERYOPT ED-ELR GEN II 5-40x56 official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'discovery-lhd-8-32-56', brand:'Discovery Optics', model:'LHD 8–32×56 FFP-Z (MRAD)',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:66, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:8, maxMagnification:32,
      elevationRangeMrad:36, windageRangeMrad:18, lengthMm:378, weightG:1010,
      firstFocalPlane:true, zeroStop:true, reticle:'MRAD', sourceName:'DISCOVERYOPT',
      sourceDocument:'DISCOVERYOPT LHD 8-32x56 official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'discovery-hd-2-12-24', brand:'Discovery Optics', model:'HD 2–12×24 FFP (MIL)',
      objectiveDiameterMm:24, objectiveOuterDiameterMm:33, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:2, maxMagnification:12,
      elevationRangeMrad:33.8, windageRangeMrad:33.8, lengthMm:215, weightG:470,
      firstFocalPlane:true, zeroStop:false, reticle:'MIL', sourceName:'DISCOVERYOPT',
      sourceDocument:'DISCOVERYOPT HD 2-12x24 official product page, verified 2026-09-27',
    ),

    // v156: models discovered from Balistik Market, but every technical
    // value below is sourced from the manufacturer's own product page/manual.
    ScopeOptic(
      id:'bushnell-match-pro-ed-5-30', brand:'Bushnell', model:'Match Pro ED 5–30×56 FFP G5I (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:30,
      elevationRangeMrad:29, windageRangeMrad:14.5, weightG:907.18,
      firstFocalPlane:true, zeroStop:true, reticle:'G5I MRAD', sourceName:'Bushnell',
      sourceDocument:'Bushnell Match Pro 5-30x56 G5I official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'nightforce-atacr-7-35-f1-milc', brand:'Nightforce Optics', model:'ATACR 7–35×56 F1 MIL-C (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:7, maxMagnification:35,
      elevationRangeMrad:29, windageRangeMrad:17, lengthMm:406, weightG:1113,
      firstFocalPlane:true, zeroStop:true, reticle:'MIL-C F1', sourceName:'Nightforce Optics',
      sourceDocument:'Nightforce ATACR 7-35x56 F1 official product page / 2026 catalog, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'element-helix-4-16-ffp-mrad', brand:'Element Optics', model:'HELIX 4–16×44 FFP APR-1C (MRAD)',
      objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:4, maxMagnification:16,
      elevationRangeMrad:23.3, windageRangeMrad:13.1, lengthMm:360, weightG:675,
      firstFocalPlane:true, zeroStop:true, reticle:'APR-1C MRAD', sourceName:'Element Optics',
      sourceDocument:'Element Optics HELIX 4-16x44 FFP official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'dnt-theone-7-35-tor', brand:'DNT Optics', model:'TheOne 7–35×56 FFP TOR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:7, maxMagnification:35,
      elevationRangeMrad:32, windageRangeMrad:16, lengthMm:406.4, weightG:1190.68,
      firstFocalPlane:true, zeroStop:true, reticle:'TOR MIL', sourceName:'DNT Optics',
      sourceDocument:'DNT Optics TheOne 7-35x56 official global product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'riton-7-conquer-4-32', brand:'Riton Optics', model:'7 Conquer 4–32×56 FFP PSR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:4, maxMagnification:32,
      elevationRangeMrad:31, lengthMm:381, weightG:1049,
      firstFocalPlane:true, zeroStop:true, reticle:'PSR MRAD', sourceName:'Riton Optics',
      sourceDocument:'Riton Optics 7 Conquer 4-32x56 official product spec sheet, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'primary-arms-plxc-1-8-griffin', brand:'Primary Arms', model:'PLxC 1–8×24 FFP ACSS Griffin MIL',
      objectiveDiameterMm:24, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:1, maxMagnification:8,
      elevationRangeMrad:29.1, windageRangeMrad:29.1, lengthMm:235.71, weightG:480.52,
      firstFocalPlane:true, reticle:'ACSS Griffin MIL', sourceName:'Primary Arms',
      sourceDocument:'Primary Arms PLxC 1-8x24 FFP official product page/manual, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'elcan-specterdr-1-4', brand:'ELCAN', model:'SpecterDR 1×/4× 32 mm',
      objectiveDiameterMm:32, clickValue:0.5, clickUnit:AngularUnit.moa,
      minMagnification:1, maxMagnification:4, elevationRangeMrad:34.9066,
      firstFocalPlane:false, zeroStop:false, reticle:'5.56 / 7.62 options', sourceName:'Armament Technology / ELCAN',
      sourceDocument:'ELCAN SpecterDR 1x/4x official product page and spec sheet, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'meopta-optika6-5-30-mrad', brand:'Meopta', model:'MeoPro Optika6 5–30×56 RD FFP MRAD',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      minMagnification:5, maxMagnification:30,
      firstFocalPlane:true, reticle:'MRAD RD', sourceName:'Meopta',
      sourceDocument:'Meopta official Optika6 reticle/specification PDF, verified 2026-09-27',
    ),


    // v157: additional manufacturer-verified optics from official product
    // pages/family sheets. Store MRAD variants explicitly and do not infer
    // missing physical dimensions from retailer listings.
    ScopeOptic(
      id:'bushnell-xrs3-6-36-g4p', brand:'Bushnell', model:'Elite Tactical XRS3 6–36×56 FFP G4P (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:6, maxMagnification:36,
      elevationRangeMrad:29, windageRangeMrad:15, weightG:1102.81,
      firstFocalPlane:true, zeroStop:true, reticle:'G4P MRAD', sourceName:'Bushnell',
      sourceDocument:'Bushnell Elite Tactical XRS3 6-36x56 G4P official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'bushnell-dmr3-3-5-21-g4p', brand:'Bushnell', model:'Elite Tactical DMR3 3.5–21×50 FFP G4P (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:3.5, maxMagnification:21,
      elevationRangeMrad:32, windageRangeMrad:20, weightG:1006.41,
      firstFocalPlane:true, zeroStop:true, reticle:'G4P MRAD', sourceName:'Bushnell',
      sourceDocument:'Bushnell Elite Tactical DMR3 3.5-21x50 G4P official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'nightforce-nx8-4-32-f1', brand:'Nightforce Optics', model:'NX8 4–32×50 F1 (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:4, maxMagnification:32,
      elevationRangeMrad:26, windageRangeMrad:20, lengthMm:340, weightG:811,
      firstFocalPlane:true, zeroStop:true, reticle:'MIL-C / MIL-XT options', sourceName:'Nightforce Optics',
      sourceDocument:'Nightforce NX8 Family official specification sheet, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'element-titan-5-25-ffp', brand:'Element Optics', model:'TITAN 5–25×56 FFP APR-1C (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      elevationRangeMrad:26.2, windageRangeMrad:14.5, lengthMm:385, weightG:1105,
      firstFocalPlane:true, zeroStop:true, reticle:'APR-1C MRAD', sourceName:'Element Optics',
      sourceDocument:'Element Optics TITAN 5-25x56 FFP official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'element-titan-3-18-ffp', brand:'Element Optics', model:'TITAN 3–18×50 FFP APR-2D (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:3, maxMagnification:18,
      elevationRangeMrad:43.6, windageRangeMrad:14.5, lengthMm:370, weightG:976,
      firstFocalPlane:true, zeroStop:true, reticle:'APR-2D MRAD', sourceName:'Element Optics',
      sourceDocument:'Element Optics TITAN 3-18x50 FFP official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'primary-arms-glx-4-5-27-athena', brand:'Primary Arms', model:'GLx 4.5–27×56 FFP ACSS Athena BPR MIL',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:4.5, maxMagnification:27,
      elevationRangeMrad:34.9066, windageRangeMrad:24.4346, lengthMm:367.03,
      firstFocalPlane:true, reticle:'ACSS Athena BPR MIL', sourceName:'Primary Arms',
      sourceDocument:'Primary Arms GLx 4.5-27x56 FFP official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'us-optics-fdn-25x', brand:'U.S. Optics', model:'FDN 25X 5–25×52 (MIL)',
      objectiveDiameterMm:52, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      firstFocalPlane:true, zeroStop:true, reticle:'PR2 / H59 / H102 options', sourceName:'U.S. Optics',
      sourceDocument:'U.S. Optics FDN 25X official product page and official reticle sheets, verified 2026-09-27',
    ),
    // v158: Vector Optics Türkiye discovery + manufacturer-global verification.
    // Retail availability is discovered from vectoroptics.com.tr; technical
    // values below come from Vector Optics' official global pages/catalog.
    ScopeOptic(
      id:'vector-continental-x6-6-36-scff70', brand:'Vector Optics', model:'Continental x6 6–36×56 FFP PRS (SCFF-70)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:6, maxMagnification:36,
      elevationRangeMrad:31, firstFocalPlane:true, zeroStop:true, reticle:'VEC-MBR2 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-70 product page / long-range academy, verified 2026-09-27',
    ),
    // v168: additional current Vector Optics long-range FFP models,
    // verified directly against the manufacturer's live product pages.
    ScopeOptic(
      id:'vector-continental-x6-5-30-vct-scff30', brand:'Vector Optics', model:'Continental x6 5–30×56 VCT FFP PRS (SCFF-30)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:30,
      elevationRangeMrad:30, windageRangeMrad:16, lengthMm:393, weightG:810,
      firstFocalPlane:true, zeroStop:true, reticle:'VCT-34 FFP', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-30 product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-tauron-gen2-5-30-scff66', brand:'Vector Optics', model:'Tauron 5–30×56 GenII FFP (SCFF-66)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:5, maxMagnification:30,
      elevationRangeMrad:17.5, windageRangeMrad:16, lengthMm:394.5, weightG:924,
      elevationRangeIsLowerBound:true, windageRangeIsLowerBound:true,
      firstFocalPlane:true, zeroStop:true, reticle:'MPX1', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-66 product page, verified 2026-09-27; adjustment ranges published as >17.5/>16 MIL',
    ),
    ScopeOptic(
      id:'vector-continental-x10-1-10-scff68', brand:'Vector Optics', model:'Continental x10 1–10×28 ED RAR FDE FFP (SCFF-68)',
      objectiveDiameterMm:28, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:1, maxMagnification:10,
      elevationRangeMrad:30, windageRangeMrad:30, lengthMm:278, weightG:651,
      elevationRangeIsLowerBound:true, windageRangeIsLowerBound:true,
      firstFocalPlane:true, zeroStop:true, reticle:'VET-CTR MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-68 product page, verified 2026-09-27; ranges published as >30 MIL',
    ),
    ScopeOptic(
      id:'vector-tauron-6-24-scff81', brand:'Vector Optics', model:'Tauron 6–24×50 HD MIL FFP PRS (SCFF-81)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:6, maxMagnification:24,
      elevationRangeMrad:32, firstFocalPlane:true, zeroStop:true, reticle:'VTA-3 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-81 product page, verified 2026-09-27; elevation published as up to 32 MIL',
    ),
    ScopeOptic(
      id:'vector-veyron-gen2-6-24-scff74', brand:'Vector Optics', model:'Veyron GenII 6–24×44 HD CTR FFP (SCFF-74)',
      objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:30, minMagnification:6, maxMagnification:24,
      elevationRangeMrad:25, lengthMm:277, firstFocalPlane:true, zeroStop:false, reticle:'VVE-1 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-74 product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-tauron-5-40-scff35', brand:'Vector Optics', model:'Tauron 5–40×56 ED FFP PRS (SCFF-35)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:40,
      elevationRangeMrad:25, lengthMm:365, weightG:978, firstFocalPlane:true, reticle:'VTA-8 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official 2026 Premium Line catalog / SCFF-35 product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-tauron-3-24-scff33', brand:'Vector Optics', model:'Tauron 3–24×56 ED FFP (SCFF-33)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:3, maxMagnification:24,
      elevationRangeMrad:30, firstFocalPlane:true, zeroStop:true, reticle:'VTA-5 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official long-range academy / rifle-scope catalog, verified 2026-09-27',
    ),

    ScopeOptic(
      id:'arken-ep5-gen2-5-25', brand:'Arken Optics', model:'EP-5 GENII 5–25×56 FFP VPR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      elevationRangeMrad:28, windageRangeMrad:12, lengthMm:396.24, weightG:1168.0,
      firstFocalPlane:true, zeroStop:true, reticle:'VPR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken Optics official EP-5 series comparison; GENII 5-25x56 MRAD configuration, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'arken-ep5-gen2-5-25-tor-mil', brand:'Arken Optics', model:'EP-5 GENII 5–25×56 FFP TOR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      elevationRangeMrad:28, windageRangeMrad:12, lengthMm:396.24, weightG:1168.0,
      firstFocalPlane:true, zeroStop:true, reticle:'TOR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken Optics official EP-5 GENII 5-25x56 product page, verified 2026-09-28',
    ),
    ScopeOptic(
      id:'arken-ep5-gen1-5-25', brand:'Arken Optics', model:'EP-5 5–25×56 FFP VPR (MRAD)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad,
      tubeDiameterMm:34, minMagnification:5, maxMagnification:25,
      elevationRangeMrad:32, windageRangeMrad:16, lengthMm:355.6, weightG:1111.3,
      firstFocalPlane:true, zeroStop:true, reticle:'VPR-MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken Optics official EP-5 series comparison; original EP-5 5-25x56 MRAD configuration, verified 2026-09-27',
    ),
    // v159: Bozkurt Av discovery -> manufacturer-verified optics only.
    ScopeOptic(
      id:'element-helix-gen2-4-16-ffp-mrad', brand:'Element Optics', model:'HELIX GEN 2 4–16×44 FFP MPR-1C (MRAD)',
      objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30,
      minMagnification:4, maxMagnification:16, elevationRangeMrad:26.1, windageRangeMrad:13,
      lengthMm:350, weightG:808, firstFocalPlane:true, zeroStop:true, reticle:'MPR-1C MRAD', sourceName:'Element Optics',
      sourceDocument:'Element Optics HELIX GEN 2 4-16x44 FFP official product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'element-helix-gen2-6-24-ffp-mrad', brand:'Element Optics', model:'HELIX GEN 2 6–24×50 FFP APR-1C (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30,
      minMagnification:6, maxMagnification:24, elevationRangeMrad:18.9, windageRangeMrad:11.6,
      lengthMm:356, weightG:830, firstFocalPlane:true, zeroStop:true, reticle:'APR-1C MRAD', sourceName:'Element Optics',
      sourceDocument:'Element Optics HELIX GEN 2 6-24x50 FFP official product page, verified 2026-09-27',
    ),
    // v160: Izmir Av Market discovery -> official manufacturer verification only.
    ScopeOptic(
      id:'sightmark-latitude-6-25-25-prs', brand:'Sightmark', model:'Latitude 6.25–25×56 FFP PRS (SM13042PRS)',
      objectiveDiameterMm:56, objectiveOuterDiameterMm:61, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34,
      minMagnification:6.25, maxMagnification:25, elevationRangeMrad:31, windageRangeMrad:20,
      lengthMm:350, weightG:938.93, firstFocalPlane:true, zeroStop:true, reticle:'PRS', sourceName:'Sightmark',
      sourceDocument:'Sightmark official Latitude 6.25-25x56 FFP PRS product page (SM13042PRS), verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-continental-x6-4-24-mbr-scff40', brand:'Vector Optics', model:'Continental x6 4–24×56 MBR FFP PRS (SCFF-40)',
      objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34,
      minMagnification:4, maxMagnification:24, elevationRangeMrad:34, windageRangeMrad:16,
      lengthMm:362, weightG:841, firstFocalPlane:true, zeroStop:true, reticle:'VEC-MBR MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-40 Continental x6 4-24x56 MBR FFP product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-orion-max-3-18-scff49', brand:'Vector Optics', model:'Orion MAX 3–18×44 HD FFP (SCFF-49)',
      objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30,
      minMagnification:3, maxMagnification:18, elevationRangeMrad:30, windageRangeMrad:16,
      lengthMm:340, weightG:798, firstFocalPlane:true, zeroStop:true, reticle:'VOR-4 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-49 Orion MAX 3-18x44 HD FFP product page, verified 2026-09-27',
    ),
    ScopeOptic(
      id:'vector-veyron-4-16-scff22', brand:'Vector Optics', model:'Veyron 4–16×44 FFP (SCFF-22)',
      objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30,
      minMagnification:4, maxMagnification:16, elevationRangeMrad:17.5, windageRangeMrad:17.5,
      lengthMm:267, weightG:530, firstFocalPlane:true, zeroStop:false, reticle:'MPR-4 MIL', sourceName:'Vector Optics',
      sourceDocument:'Vector Optics official SCFF-22 Veyron 4-16x44 FFP product page, verified 2026-09-27',
    ),

    // v161: additional active Vector Optics riflescopes verified against the
    // manufacturer's current product pages. MOA adjustment ranges are stored
    // internally as MRAD only after exact unit conversion; click units remain MOA.
    ScopeOptic(id:'vector-continental-x6-6-36-scff93', brand:'Vector Optics', model:'Continental x6 6–36×56 FFP (SCFF-93)', objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34, minMagnification:6, maxMagnification:36, elevationRangeMrad:31, windageRangeMrad:18, lengthMm:404, weightG:861, firstFocalPlane:true, zeroStop:true, reticle:'VCT-34 MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-93 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-veyron-gen2-3-12-scff72', brand:'Vector Optics', model:'Veyron GenII 3–12×44 HD CTR FFP (SCFF-72)', objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30, minMagnification:3, maxMagnification:12, elevationRangeMrad:30, windageRangeMrad:25, lengthMm:257, weightG:629, firstFocalPlane:true, zeroStop:false, reticle:'VVE-1 MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-72 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-veyron-gen2-4-16-scff78', brand:'Vector Optics', model:'Veyron GenII 4–16×44 HD DCR FFP (SCFF-78)', objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30, minMagnification:4, maxMagnification:16, elevationRangeMrad:30, windageRangeMrad:25, lengthMm:251, weightG:645, firstFocalPlane:true, zeroStop:false, reticle:'VVE-2 MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-78 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-tauron-5-25-scff71', brand:'Vector Optics', model:'Tauron 5–25×56 HD MIL FFP PRS (SCFF-71)', objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34, minMagnification:5, maxMagnification:25, elevationRangeMrad:32, windageRangeMrad:30, lengthMm:361, weightG:1023, firstFocalPlane:true, zeroStop:true, reticle:'VTA-8 MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-71 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-tauron-4-16-scff80', brand:'Vector Optics', model:'Tauron 4–16×44 HD MOA FFP (SCFF-80)', objectiveDiameterMm:44, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:34, minMagnification:4, maxMagnification:16, elevationRangeMrad:42.1794, windageRangeMrad:29.0888, lengthMm:334, weightG:951, firstFocalPlane:true, zeroStop:true, reticle:'VTA-4 MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-80 product page, verified 2026-09-27; 145/100 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-tauron-6-24-scff82', brand:'Vector Optics', model:'Tauron 6–24×50 HD MOA FFP PRS (SCFF-82)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:34, minMagnification:6, maxMagnification:24, elevationRangeMrad:31.9977, windageRangeMrad:31.9977, lengthMm:361, weightG:986, firstFocalPlane:true, zeroStop:true, reticle:'VTA-4 MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-82 product page, verified 2026-09-27; 110 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-sentinel-6-24-scff57', brand:'Vector Optics', model:'Sentinel 6–24×50 FFP (SCFF-57)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:6, maxMagnification:24, elevationRangeMrad:15.9989, windageRangeMrad:11.6355, lengthMm:369, weightG:775, firstFocalPlane:true, zeroStop:true, reticle:'VSE-3 MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-57 product page, verified 2026-09-27; 55/40 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-sentinel-5-25-scff58', brand:'Vector Optics', model:'Sentinel 5–25×50 HD FFP (SCFF-58)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:5, maxMagnification:25, elevationRangeMrad:23.2711, windageRangeMrad:17.4533, lengthMm:355, weightG:792, firstFocalPlane:true, zeroStop:true, reticle:'VSE-5 MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-58 product page, verified 2026-09-27; 80/60 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-orion-pro-max-6-24-scff44', brand:'Vector Optics', model:'Orion Pro Max 6–24×50 FFP HD (SCFF-44)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:6, maxMagnification:24, elevationRangeMrad:23.2711, windageRangeMrad:17.4533, lengthMm:340, weightG:782, firstFocalPlane:true, zeroStop:true, reticle:'VE-RDF MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-44 product page, verified 2026-09-27; 80/60 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-orion-pro-max-3-18-scol57', brand:'Vector Optics', model:'Orion Pro MAX 3–18×50 HD SFP (SCOL-57)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:3, maxMagnification:18, elevationRangeMrad:29.0888, windageRangeMrad:17.4533, lengthMm:338, weightG:825, firstFocalPlane:false, zeroStop:true, reticle:'VOR-5 MOA', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOL-57 product page, verified 2026-09-27; 100/60 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-continental-x6-3-18-scff43', brand:'Vector Optics', model:'Continental x6 3–18×50 FFP (SCFF-43)', objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34, minMagnification:3, maxMagnification:18, elevationRangeMrad:44, windageRangeMrad:16, lengthMm:337, weightG:790, firstFocalPlane:true, zeroStop:true, reticle:'VEC-MBR MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCFF-43 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-continental-1-6-scoc44', brand:'Vector Optics', model:'Continental 1–6×24i Fiber Tactical LPVO (SCOC-44)', objectiveDiameterMm:24, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30, minMagnification:1, maxMagnification:6, elevationRangeMrad:40, windageRangeMrad:40, lengthMm:283, weightG:510, firstFocalPlane:false, zeroStop:false, reticle:'VEC-FDR MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOC-44 product page, verified 2026-09-27'),


    // v164: additional active Vector Optics Forester/Paragon models verified
    // against manufacturer product pages. MOA ranges are converted to MRAD
    // only for the existing internal range fields; native click units remain MOA.
    ScopeOptic(id:'vector-forester-2-10-scom02', brand:'Vector Optics', model:'Forester 2–10×40 SFP (SCOM-02)', objectiveDiameterMm:40, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:2, maxMagnification:10, elevationRangeMrad:17.4533, windageRangeMrad:17.4533, lengthMm:340, weightG:500, firstFocalPlane:false, zeroStop:true, reticle:'VFD-2 Etched Glass', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOM-02 product page, verified 2026-09-27; 60/60 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-forester-3-15-scom16', brand:'Vector Optics', model:'Forester 3–15×50 SFP (SCOM-16)', objectiveDiameterMm:50, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:3, maxMagnification:15, elevationRangeMrad:17.4533, windageRangeMrad:17.4533, lengthMm:384, weightG:575, firstFocalPlane:false, zeroStop:true, reticle:'VFD-2 Etched Glass', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOM-16 product page, verified 2026-09-27; 60/60 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-forester-jr-3-9-scom35', brand:'Vector Optics', model:'Forester JR. 3–9×40 SFP (SCOM-35)', objectiveDiameterMm:40, clickValue:0.25, clickUnit:AngularUnit.moa, tubeDiameterMm:30, minMagnification:3, maxMagnification:9, elevationRangeMrad:14.5444, windageRangeMrad:14.5444, lengthMm:296, weightG:430, firstFocalPlane:false, zeroStop:false, reticle:'VFD-3', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOM-35 product page, verified 2026-09-27; 50/50 MOA ranges converted to MRAD'),
    ScopeOptic(id:'vector-paragon-gen2-3-15-scom25', brand:'Vector Optics', model:'Paragon 3–15×50 SFP GenII (SCOM-25)', objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30, minMagnification:3, maxMagnification:15, elevationRangeMrad:26, windageRangeMrad:26, lengthMm:336, weightG:625, firstFocalPlane:false, zeroStop:false, reticle:'VPA-2 Etched Glass MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOM-25 product page, verified 2026-09-27'),
    ScopeOptic(id:'vector-paragon-gen2-6-30-scol27', brand:'Vector Optics', model:'Paragon 6–30×56 SFP GenII (SCOL-27)', objectiveDiameterMm:56, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:30, minMagnification:6, maxMagnification:30, elevationRangeMrad:17.5, windageRangeMrad:17.5, lengthMm:399, weightG:700, firstFocalPlane:false, zeroStop:false, reticle:'VPA-2 Etched Glass MIL', sourceName:'Vector Optics', sourceDocument:'Vector Optics official SCOL-27 product page, verified 2026-09-27'),

    ScopeOptic(
      id:'arken-ep8-1-8-klgrid-mil', brand:'Arken Optics', model:'EP-8 1–8×28 FFP KLGRID (MIL)',
      objectiveDiameterMm:28, clickValue:0.1, clickUnit:AngularUnit.mrad, tubeDiameterMm:34,
      minMagnification:1, maxMagnification:8, elevationRangeMrad:30, windageRangeMrad:30,
      lengthMm:261.62, weightG:595.34, firstFocalPlane:true, zeroStop:false, reticle:'KLGRID MIL', sourceName:'Arken Optics USA',
      sourceDocument:'Arken EP-8 1-8x28 FFP KLGRID official product page, verified 2026-09-27',
    ),  ];
  /// Validates the catalog shipped with this application build. This is used
  /// at startup as well as by tests so corrupt catalog data cannot silently
  /// reach profile creation or other feature screens.
  static List<CatalogIssue> bundledIntegrityIssues() => const CatalogIntegrity().validate(
    rifles: rifles,
    ammunition: ammunition,
    scopes: scopes,
  );

  /// The user's personal (manual) catalog, converted and installed by
  /// `UserCatalogLoader`. Built-in [rifles]/[ammunition]/[scopes] stay the
  /// manufacturer-sourced lists; the `all*` views add the personal records,
  /// which carry `userEntered: true` and a "Kullanıcı girdisi" source.
  static UserCatalog _user = UserCatalog.empty;
  static UserCatalog get userCatalog => _user;
  static void installUserCatalog(UserCatalog catalog) => _user = catalog;

  static List<Rifle> get allRifles => [...rifles, ..._user.rifles];
  static List<Ammunition> get allAmmunition => [...ammunition, ..._user.ammunition];
  static List<ScopeOptic> get allScopes => [...scopes, ..._user.scopes];

  /// Rifles for [p]. Personal records are included unless [includeUser] is
  /// false (the catalog browser lists them in their own section).
  List<Rifle> riflesFor(WeaponPlatform p, {bool includeUser = true}) =>
      (includeUser ? allRifles : rifles).where((x)=>x.platform==p).toList(growable:false);
  List<Ammunition> ammunitionFor(WeaponPlatform p, {double? caliberMm, bool includeUser = true}) =>
      (includeUser ? allAmmunition : ammunition).where((x)=>x.platform==p && (caliberMm==null || (x.caliberMm-caliberMm).abs()<0.001)).toList(growable:false);
}
