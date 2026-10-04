from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
p=root/'lib/data/catalog_repository.dart'
s=p.read_text()
rifles=[('seneca-light-hunter-ii-wood-45','Light Hunter II Wood','https://www.airventuri.com/products/seneca-light-hunter-ii-wood'),('seneca-light-hunter-ii-tactical-45','Light Hunter II Tactical','https://www.airventuri.com/products/seneca-light-hunter-ii-tactical')]
new='    // v260: manufacturer-confirmed .45 PCP rifles; no inferred alternate calibers.\n'
for rid,name,url in rifles:
 new+=f"    Rifle(id:'airventuri-{rid}', brand:'Seneca (Air Venturi)', model:'{name}', platform:WeaponPlatform.pcp, caliberMm:11.43, airCapacityCc:500, barrelLengthMm:549.91, sourceName:'Air Venturi', sourceDocument:'{url} — manufacturer listing, checked 2026-09-30'),\n"
assert 'airventuri-seneca-light-hunter-ii-wood-45' not in s
s=s.replace('    // v247: Complete RTI rifles',new+'\n    // v247: Complete RTI rifles',1)
ammo=[('av45-454-rb-137','Big Bore .45 .454 round ball [2017 archival]',11.53,137,'AV.45/.454/RB'),('av45-457-rb-143','Big Bore .45 .457 round ball [2017 archival]',11.61,143,'AV.45/.457/RB'),('av45-166-fp','Big Bore .45 166 gr flat point [2017 archival]',11.43,166,'AV.45/166gr/FP')]
block='    // v260: archival 2017 manufacturer catalog, NOT confirmed currently sold.\n'
for aid,name,cal,grain,sku in ammo:
 block+=f"    Ammunition(id:'airventuri-{aid}', brand:'Air Venturi', model:'{name}', platform:WeaponPlatform.pcp, caliberMm:{cal}, grain:{grain}, type:AmmunitionType.bullet, sourceName:'Air Venturi 2017 archival catalog', sourceDocument:'https://www.airventuri.com/images/airventuri/Air-Venturi-Catalog-2017-low-res.pdf — SKU {sku}; historical only, current availability unverified'),\n"
s=s.replace('    // User-specific G Maz entry',block+'\n    // User-specific G Maz entry',1)
p.write_text(s)
source=root/'catalog_sources/air_venturi_2026.json'; data=json.loads(source.read_text());data['active_rifle_ids']+=['airventuri-'+r[0] for r in rifles];data['ammunition']['archival_2017_imported']=[{'id':'airventuri-'+a[0],'sku':a[4],'current_availability':'unverified'} for a in ammo];data['ammunition']['current_site'][0]['status']='excluded_until_BB_type_supported';data['ammunition']['current_site'][1]['status']='excluded_until_BB_type_supported';source.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print('Added 2 current PCP rifle records and 3 explicitly archival bullet records')
