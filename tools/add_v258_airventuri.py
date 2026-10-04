from pathlib import Path
p=Path(__file__).resolve().parents[1]/'lib/data/catalog_repository.dart'
s=p.read_text()
marker='  static const rifles = <Rifle>[\n'
entry="    // v258: Official current Seneca listing distributed by Air Venturi; do not infer other caliber variants.\n    Rifle(id:'airventuri-seneca-dragon-claw-ii-tactical-50', brand:'Seneca (Air Venturi)', model:'Dragon Claw II Tactical', platform:WeaponPlatform.pcp, caliberMm:12.7, airCapacityCc:500, barrelLengthMm:549.91, weightKg:3.447, sourceName:'Air Venturi', sourceDocument:'https://www.airventuri.com/products/seneca-dragon-claw-ii-pcp-air-rifle-tactical-stock — official current listing, verified 2026-09-30'),\n"
if "airventuri-seneca-dragon-claw-ii-tactical-50" not in s:
 s=s.replace(marker,marker+entry,1)
 p.write_text(s)
