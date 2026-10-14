# BC geri hesap: 30 fabrika fişeğine üreticinin kendi BC'si

Tarih: 14.10.2026 (İstanbul). Dal: `data/bc-geri-hesap`. Taslak PR; birleştirme sahibin ana oturumunda.

## Ne yapıldı

Sahip kararı (14.10.2026 10:54): "Uygun olanları ekle, oranlar çok iyi." Araştırma #290'daki
(docs/research/bc_gelistirme.md, data/bc_gelistirme/) BC'siz 30 fabrika fişeğine BC eklendi:
10 yüksek güvenli, 20 kabul edilen orta güvenli. Değerlerin hepsi üreticinin kendisinden:

- **üretici sayfasında yazılı** (`bcSource: 'printed'`): Lapua, Weatherby.
- **üretici hız tablosundan geri hesap** (`bcSource: 'maker-table-backsolve'`): üreticinin kendi
  menzil–hız tablosundan G1 BC (Army Standard Metro) geri hesaplandı. Yöntem, BC'si yayımlanmış
  16 fişekte denendi: ortanca sapma %0,19, p90 %0,53.
- **içindeki merminin üretici BC'si** (`bcSource: 'component-bullet'`): Winchester 22 WMR 30 gr
  V-MAX (Hornady V-MAX mermisi, Hornady tablosundan) ve Black Hills .223 36 gr Varmint Grenade
  (Barnes'ın yazdığı BC). Bu ikisinde ayrıca `bcFromBullet: true` (mevcut anlamı: BC, aynı merminin
  mermi üreticisinden).

Değerler backsolve_results.csv / bc_less_mapping.csv'deki hassasiyetten kütüphane gibi 3 haneye
yuvarlandı. Her satırda `bcSourceUrl` (üreticinin sayfası), `bcSource` ve kısa Türkçe `note` var.
Eşleşme marka + ad + kalibre + grain ile tek tek doğrulandı (her kod tam bir satıra denk geldi).
Başka hiçbir satır ve alan değişmedi.

## Eklenen 30 fişek

| # | Kod | Marka | Fişek | Kalibre | BC | Model | Güven | Nasıl | Kaynak URL |
|---|---|---|---|---|---|---|---|---|---|
| 1 | FA002 | Hornady | Varmint Express Rimfire 17 gr V-MAX · 17 gr | .17 HMR | 0,125 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rimfire/17-hmr-17-gr-v-max |
| 2 | FA003 | Hornady | Varmint Express Rimfire 20 gr HP XTP · 20 gr | .17 HMR | 0,125 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rimfire/17-hmr-20-gr-xtp |
| 3 | FA029 | Hornady | 30 gr V-MAX Varmint Express Rimfire · 30 gr | .22 WMR | 0,095 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rimfire/22-wmr-30-gr-v-max |
| 4 | FA062 | Hornady | 170 gr MonoFlex Black · 170 gr | .338 ARC | 0,309 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rifle/338-arc-170-gr-monoflex-black |
| 5 | FA063 | Hornady | 175 gr HP Match BLACK · 175 gr | .338 ARC | 0,385 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rifle/338-arc-175-gr-hp-match-black |
| 6 | FA064 | Hornady | 215 gr FTX Black · 215 gr | .338 ARC | 0,371 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rifle/338-arc-215-gr-ftx-black |
| 7 | FA067 | Hornady | 210 gr InterLock American Whitetail · 210 gr | .400 Legend | 0,198 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rifle/400-legend-210-gr-interlock-american-whitetail |
| 8 | FA082 | Hornady | American Gunner 123 gr HP Match · 123 gr | 7.62x39 | 0,272 | G1 | yüksek | üretici hız tablosundan geri hesap | https://www.hornady.com/ammunition/rifle/7.62-x-39mm-123-gr-hp-match-american-gunner |
| 9 | FA042 | Lapua | Lapua 4.5 g (69 gr) Scenar · 69 gr | .223 Rem | 0,341 | G1 (G7 0,171) | yüksek | üretici sayfasında yazılı | https://www.lapua.com/product/223-rem-target-cartridge-scenar-l-45g-69gr-4315015/ |
| 10 | FA044 | Weatherby | 240 Weatherby Magnum 72 gr Hammer Custom · 72 gr | .240 Weatherby Mag | 0,320 | G1 | yüksek | üretici sayfasında yazılı | https://weatherby.com/ammunition-org/ballistics-charts/ |
| 11 | FA004 | Aguila | 22 Long Rifle Interceptor Copper-Plated Hollow Point · 40 gr | .22 LR | 0,140 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-interceptor-hollow-point |
| 12 | FA005 | Aguila | 22 Long Rifle Interceptor Copper-Plated Solid Point · 40 gr | .22 LR | 0,140 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-interceptor-long-rifle-high-velocity-copper-plated-solid-point |
| 13 | FA006 | Aguila | 22 Long Rifle Sniper Subsonic Lead Solid Point · 60 gr | .22 LR | 0,139 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-sniper-subsonic-long-rifle-subsonic-lead-solid-point |
| 14 | FA008 | Aguila | 22 Long Rifle Subsonic Lead Hollow Point · 38 gr | .22 LR | 0,111 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-subsonic-hollow-point |
| 15 | FA009 | Aguila | 22 Long Rifle Subsonic Lead Solid Point · 40 gr | .22 LR | 0,158 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-subsonic-solid-point-long-rifle-subsonic-lead |
| 16 | FA010 | Aguila | 22 Long Rifle SuperMaximum Copper-Plated Hollow Point · 30 gr | .22 LR | 0,110 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-supermaximum-hollow-point-1 |
| 17 | FA011 | Aguila | 22 Long Rifle SuperMaximum Copper-Plated Solid Point · 30 gr | .22 LR | 0,110 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-supermaximum-long-rifle-hyper-velocity-copper-plated-solid-point |
| 18 | FA012 | Aguila | 22 Long Rifle Target Competition Lead Solid Point · 40 gr | .22 LR | 0,168 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-target-competition-long-rifle-standard-velocity-solid-lead-point |
| 19 | FA028 | Aguila | 22 Win Mag Semi-Jacketed Soft Point · 40 gr | .22 WMR | 0,150 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/22-win-mag-high-velocity-semi-jacketed-soft-point |
| 20 | FA047 | Aguila | 110 Grain Full Metal Jacket · 110 gr | .30 Carbine | 0,127 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/30-carbine-full-metal-jacket |
| 21 | FA048 | Aguila | 30-06 SPRG 150 Grain Soft Point · 150 gr | .30-06 Springfield | 0,339 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/30-06-sprg-150-gr-soft-point |
| 22 | FA050 | Aguila | 300 AAC Blackout 150 Grain Full Metal Jacket · 150 gr | .300 Blackout | 0,303 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/300-aac-blackout-full-metal-jacket |
| 23 | FA056 | Aguila | 308 WIN 150 Grain Full Metal Jacket Boat Tail · 150 gr | .308 Win | 0,323 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/308-win-full-metal-jacket-boat-tail |
| 24 | FA083 | Aguila | 7.62 x 51mm 150 Grain Full Metal Jacket Boat Tail · 150 gr | 7.62x51 NATO | 0,323 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/7.62-x-51mm-full-metal-jacket-boat-tail |
| 25 | FA068 | Aguila | 5.56 x 45mm 55 Grain Full Metal Jacket Boat Tail · 55 gr | 5.56x45 NATO | 0,301 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/5.56-x-45mm-full-metal-jacket-boat-tail-bulk-pack |
| 26 | FA069 | Aguila | 5.56 x 45mm 62 Grain Full Metal Jacket Boat Tail · 62 gr | 5.56x45 NATO | 0,284 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/5.56-x-45mm-full-metal-jacket-boat-tail |
| 27 | FA070 | Aguila | 5.56 x 45mm NATO 55 Grain FMJ · 55 gr | 5.56x45 NATO | 0,252 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/5-56-x-45mm-nato-55-grain-full-metal-jacket |
| 28 | FA075 | Aguila | 140 Grain Full Metal Jacket Boat Tail · 140 gr | 6.5 Creedmoor | 0,500 | G1 | orta | üretici hız tablosundan geri hesap | https://www.aguilaammo.com/products/6.5-creedmoor-full-metal-jacket-boat-tail |
| 29 | FA031 | Winchester | Varmint HV 22 Win Mag 30 gr V-MAX · 30 gr | .22 WMR | 0,095 | G1 | orta | içindeki merminin üretici BC'si | https://www.hornady.com/ammunition/rimfire/22-wmr-30-gr-v-max |
| 30 | FA034 | Black Hills | Black Hills 36 gr Varmint Grenade · 36 gr | .223 Rem | 0,149 | G1 | orta | içindeki merminin üretici BC'si | https://barnesbullets.com/content/barnes-loaddata/rifle/224/223RemingtonWeb.pdf |

Hepsi G1. Lapua .223 69 gr Scenar-L için üretici G7 0,171'i de yazıyor; bu, sınıfa eklenen tek yeni
alan `bcG7` ile saklandı (yalnız bu satırda dolu, hesap G1 ile yapılır; arayüzde ek alan yok).

## Uygulamada nasıl görünüyor

Fişek seçilince BC kutusu dolar (G1). BC ⓘ açıklamasının sonuna mevcut düzenle
"Bu fişek: …" notu eklenir, örneğin:

- "Bu fişek: BC üreticinin kendi hız tablosundan geri hesaplandı (G1, Army Standard Metro), 14.10.2026."
- Aguila: "… (G1, Army Standard Metro; tabloda yalnız namlu ağzı ve 100 yd hızı var), 14.10.2026."
- Lapua: "Bu fişek: BC üreticinin kendi sayfasında yazılı: G1 0,341 / G7 0,171, 14.10.2026."
- Weatherby: "Bu fişek: BC üreticinin balistik tablosunda yazılı (üretici "320 (G1)" diye basıyor, 0,320 okundu), 14.10.2026."
- Black Hills: "Bu fişek: BC, içindeki Barnes Varmint Grenade 36 gr mermisinin üretici BC'si; Barnes G1/G7 etiketi vermiyor, G1 kabul edildi, 14.10.2026."

Yeni `bcSource` değerleri için ayrı arayüz metni gerekmedi: not zaten nasıl alındığını söylüyor
(NATO satırlarındaki gibi ek metin yok). `bcProbable` hepsinde `false` kaldı (bu alan "üretici
standardı adlandırmıyor" demek; burada mermi/fişek adı açık).

**Akla yatkınlık uyarısı:** 30 değerin hiçbiri Profil'deki BC uyarısını (G1: ağırlık/(7000·çap²)/BC
0,32–4,6 arası) tetiklemiyor; en düşük oran 0,518 (Aguila 5.56 55 gr FMJBT), en yüksek 1,305
(Aguila .30 Carbine 110 gr).

## Uç durumlar / dikkat

- Aguila satırlarının tablosu yalnız iki nokta (namlu ağzı + 100 yd); bu yüzden orta güven.
- Aguila .308 Win ve 7.62x51 150 gr FMJBT: kütüphanedeki hız 2750 fps, BC'nin hesaplandığı
  üretici sayfası 2760 fps diyor. Hız değiştirilmedi (görev dışı); BC merminin özelliği olduğu için
  etkilenmez.
- Lapua .223 69 gr: kütüphanedeki ad "Scenar", üreticinin bugünkü ürünü "Scenar-L"; kütüphane hızı
  2789 fps, katalog 2723 fps (830 m/s). Ad ve hız değiştirilmedi.
- Weatherby değeri "320" diye basıyor; 0,320 G1 okundu (üreticinin ürün sayfasında da "B/C (G1) - 320").
- `lib/data/factory_ammo_library.dart` başında "GENERATED … Do not edit" yazıyor; üreteç
  (tools/data_gen/generate_profile_lists.py) bu ortamda olmayan veri dallarını okuyor. Üreteç yeniden
  çalıştırılırsa bu 30 BC kaybolur; üreteç güncellenmedi (istenmedi). Sahibe not.

## Eklenmeyenler (sahibe sorulacak)

| Kod | Fişek | Neden |
|---|---|---|
| FA061 | Hornady .338 ARC 285 gr FMJ Frontier (ses altı) | Geri hesapta mesafeye göre kayma %3,4–3,6; ses altı hızda G1 tutarsız. |
| FA045 | Lapua .243 Win 90 gr FMJ | Değer Lapua kataloğu PDF'inden; metin çıkarımı karışık, basılı sayfayla elle kontrol gerekli. |
| FA046 | Lapua .243 Win 100 gr Soft Point | Aynı neden (FA045). |
| FA007 | Aguila 22 LR Standard Velocity Lead Solid Point | **Olası ağırlık hatası:** kütüphanede 29 gr, üretici sayfası 40 gr. Sayfa: https://www.aguilaammo.com/products/22-super-extra-long-rifle-standard-velocity-lead-solid-point (okunma 14.10.2026; tablo "0 yd: 1130 / 100 yd: 981 fps"; araştırma notu: "Library row says 29 gr; Aguila page for 'Standard Velocity Lead Solid Point' is 40 gr"). Geri hesap 0,170 G1 40 gr'a ait. Kütüphane satırı değiştirilmedi. |
| FA014 | Geco Rifle .22 2,6 g | Düşük güven: kayma %4,2, hızlar 5–10 m/s yuvarlanmış. |
| FA015 | Geco Semi-Auto .22 2,6 g | Düşük güven: kayma %7,3. |

## Testler

- Yeni `test/factory_ammo_bc_backsolve_test.dart`: 30 satırda BC>0 ve beklenen değer, model G1,
  `bcSource`, `bcSourceUrl` üreticinin alan adında (https), not tarihli; FA042'de G7 0,171; 6
  dışarıda kalan satır değişmemiş (BC/model/kaynak/not boş, FA007 hâlâ 29 gr); 30 değerin hiçbiri
  akla yatkınlık bandının dışında değil.
- Python testlerinde iki küçük uyarlama: `tools/test_nato_bc_generation.py` (NATO dışı satırlarda
  `bcSourceUrl` artık yalnız bu üç yeni kaynakta olabilir) ve `tools/test_v400_muhimmat_tamamlama.py`
  (Aguila "BC yalnız av tablosundan" testi, hız tablosundan geri hesaplanan satırları atlar; diğer 8
  satır aynı).
- Yerelde: `python3 tools/offline_dart_lint.py` → PASS (331 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 740 test OK.
- Bu ortamda Flutter SDK yok; `tools/claude_flutter_verify.sh` çalıştırılmadı (BLOCKED).

## CI

Hepsi `data/bc-geri-hesap` dalında, commit `e197936` üzerinde çalıştı:

- Biçim (format-fix, iş akışı 375209577): başarılı, biçim commit'i `e197936` dala eklendi ve
  çekildi — https://github.com/sniperTurk/flutter-app/actions/runs/38532012959
- Testler (`test-diag.yml`, files=test, tüm `test/` klasörü): **başarılı** (yeşil) —
  https://github.com/sniperTurk/flutter-app/actions/runs/38532212251
- Analiz (`analyze-diag.yml`, `flutter analyze --fatal-infos --fatal-warnings`): **başarılı**
  (yeşil) — https://github.com/sniperTurk/flutter-app/actions/runs/38532215535

Bu rapor commit'i yalnız belge içerir (kod/test değişmedi). `iOS CI / verify`, Simulator,
TestFlight ve App Store çalıştırılmadı; geçti denemez.

## Yapılmayanlar

- Birleştirme yok (taslak PR). TestFlight yok.
- 6 satır eklenmedi (yukarıda). Kütüphane hızları ve adları değiştirilmedi.
- Üreteç betiği güncellenmedi.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
