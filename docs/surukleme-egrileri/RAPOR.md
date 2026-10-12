# Mermiye özel ölçülmüş sürüklenme eğrileri — rapor

Tarih: 2026-10-11 · Zamanlanmış görev (sahibi çevrimdışı) · Dallar: `data/surukleme-egrileri`
(veri), `feat/surukleme-egrileri` (uygulama).

## Kısa sonuç

- Kendi ölçtüğü Cd–Mach eğrisini sayısal olarak **ve yeniden kullanım izniyle** yayımlayan
  mermi/fişek üreticisi **bulunamadı**. Sayısal tablo yayımlayan tek üretici Warner Tool;
  kullanım şartı kopyalamayı ve ticari kullanımı yasaklıyor.
- Devletin açık yayımladığı raporlarda bir kullanılabilir tablo bulundu: ARL-TR-5182,
  5.56 mm M855 (kıvılcım menzili, 6 nokta, Mach 1,18–2,62). Veri dalına **başvuru kaydı**
  olarak eklendi; ses altı ve ses geçişi bölgesi olmadığı ve kütüphanede aynı mermi olmadığı
  için **uygulamaya bağlanmadı**.
- Uygulamada şu an ölçülmüş eğrisi olan kütüphane mermisi sayısı: **0**. Bu yüzden
  G1/G7 sonuçları da, ekran da değişmedi (ekran görüntüsü gerekmedi, sim-screens
  çalıştırılmadı).
- Altyapı hazır: veri biçimi, denetleyen generator, kütüphane bağlantısı ve testler.
  İzinli bir eğri geldiğinde JSON eklenip generator çalıştırılınca kütüphaneden o mermi
  seçilince eğri kendiliğinden kullanılır.

## 1. Mevcut durum (incelendi)

- **Kullanıcı eğrisi:** `lib/core/drag_curve.dart` `.drg`/CSV metnini `[Mach, Cd]` noktalarına
  çevirir (5–500 nokta, son nokta ≥ Mach 1,2). Profil formu (`profiles_screen.dart`,
  `DragCurveField`) eğriyi mühimmat kaydına `dragCurve: [[Mach, Cd], …]`, `bc:` kesit
  yoğunluğu (lb/in²), `bcModel: g1` olarak yazar (`manual_catalog_store.dart` doğrular,
  `user_catalog.dart` okur). `Ammunition.dragTable` eğriyi `DragTable`'a çevirir; çözücü
  (`aerodynamic_trajectory_solver.dart`) `input.dragTable ?? StandardDragTables.forModel(model)`
  ile eğri varsa onu, yoksa G1/G7/GA tablosunu kullanır. Eğri dışındaki Mach'ta `DragTable`
  ilk/son değeri sabit tutar (uç değer dışına taşma yok) — bu yüzden kapsamı eksik eğri
  tehlikelidir.
- **Mermi kütüphanesi:** `lib/data/bullet_library.dart` (üretilmiş, `LibraryBullet`; marka, ad,
  grain, G1/G7, hız bantları, kaynak). Profilde El dolumu → Marka | Model seçilince
  `_applyBullet` BC'yi doldurur ve özel eğriyi kapatıyordu.
- **PR #72 / `data/drag-curves`:** yalnızca `data/drag-curves/INDEX.md` (katalog, 0 eğri):
  Warner Tool PDF'leri (şart nedeniyle atlandı), Lapua QTU paketi (indirilemedi, şart belirsiz).
  **Ana dala alınmamış.** İçerik `data/surukleme-egrileri` dalına güncellenerek taşındı.

## 2. Üreticiler — kim yayımlıyor?

| Üretici | Sayısal Cd–Mach kendi sitesinde | Koşul | Karar |
|---|---|---|---|
| Warner Tool (Flatline) | Var — Doppler PDF'leri, https://www.warner-tool.com/doppler-data/ | Şartlar (https://www.warner-tool.com/terms-and-conditions/, 2026-10-10 okundu): "User agrees not to copy, reproduce, modify, … or store any Content"; "Use of all Site Content is for non-commercial purposes only." 2026-10-11'de şart sayfası bu ortamdan açılamadı. | EKLENMEDİ (yasak) |
| Lapua | Ayrı tablo yok; Doppler verisi Lapua Ballistics uygulaması ve QuickTARGET Lapua Edition paketinde (QTU.zip) | "all materials are protected by copyright laws and may not be altered or used for unauthorized purposes" (https://www.lapua.com/support/downloads_/); ayrıca QuickTARGET yasak kaynak | EKLENMEDİ |
| Hornady | Yok (Heat Shield sayfasında sayısız grafik; 4DOF eğrileri yalnız uygulama içinde — yasak) | — | YOK |
| Berger | Yok; CDM'ler Applied Ballistics üzerinden (yasak) | — | YOK |
| Sierra, Norma, Sako, Nosler, Barnes, Federal, Sellier & Bellot, Hammer, Cutting Edge, Lehigh, Peregrine, Woodleigh, Prvi Partizan, MKE, Geco, Nammo, RUAG/RWS | Bulunamadı (yalnızca G1/G7 BC veya kendi uygulamaları) | — | YOK |
| PCP: JSB, H&N, FX, NSA, Zan, Air Arms, Hatsan | Bulunamadı (yalnızca tek BC) | — | YOK |

Notlar: Cutting Edge teknik PDF'i, Hornady kullanım şartı ve GS Custom BC sayfası bu ortamdan
açılamadı; engel aşılmaya çalışılmadı. Lapua/Warner ile yazışma sahibi tarafından iptal
edildi; kimseyle iletişim kurulmadı, hesap açılmadı, form doldurulmadı.

## 3. Devletin açık yayınları (DTIC)

| Rapor | İçerik | Dağıtım | Karar |
|---|---|---|---|
| ARL-TR-5182 (Silton & Howell, 2010) https://apps.dtic.mil/sti/tr/pdf/ADA530895.pdf | M855, 62,3 gr, Ø5,69 mm; Tablo 8 CX0: Mach 2,62→0,29 · 2,46→0,33 · 2,23→0,32 · 1,68→0,38 · 1,47→0,40 · 1,18→0,45 | "Approved for public release; distribution is unlimited." | Veri dalına başvuru kaydı; uygulamaya **bağlanmadı** (aşağıda) |
| BRL-MR-3810 (McCoy, 1990) https://apps.dtic.mil/sti/pdfs/ADA219106.pdf | .50 M33/M8/M20; sıfır-yalpa tablo yalnız M20 izli (iz yanarken) | Kapakta Statement A doğrulanamadı | EKLENMEDİ (izli/yanıcı askerî mermi; dağıtım doğrulanmadı) |
| BRL-MR-3733 (McCoy, 1988) https://apps.dtic.mil/sti/tr/pdf/ADA205633.pdf | M118, Sierra 190 gr MatchKing, Sierra 168 gr International: tablolar yalpalı toplam CD; CD0 yalnız grafik | Açık yayın | EKLENMEDİ (grafikten sayı okumak tahmin olur) |
| BRL-MR-3476 (McCoy, 1985) https://apps.dtic.mil/sti/pdfs/ADA162133.pdf | M855/SS109: CD0 yalnız grafik; metinde M855 CD0'ın SS109'dan ses üstünde ~%8 yüksek olduğu yazıyor | Açık yayın | EKLENMEDİ |
| BRL-MR-3877 https://apps.dtic.mil/sti/pdfs/ADA229713.pdf | .22 LR match; CD0 yalnız grafik | Açık yayın | EKLENMEDİ |
| BRL MR-1833 (Piddington, 1967) https://apps.dtic.mil/sti/tr/pdf/AD0815788.pdf | 7.62 M59/M80 tablosu (OCR bozuk) | PDF'te sınırlı dağıtım ibaresi; HTML sayfasında açık yayın — çelişkili | EKLENMEDİ (koşul belirsiz, OCR güvenilmez) |

M855 neden uygulamaya bağlanmadı:

1. **Kapsam:** en düşük nokta Mach 1,18. 5.56 mm M855 yaklaşık 500–600 m'de bu hızın altına
   iner; çözücü eğri altında Cd'yi 0,45'te sabit tutar, gerçek ses altı Cd ~0,15–0,2'dir.
   Sonuç uzak mesafede düşüşü büyük ölçüde abartır — ilk atış isabeti amacına ters.
2. **Eşleşme:** kütüphanede M855 yok. MKE SS109 farklı bir mermi; McCoy M855'in CD0'ının
   SS109'dan ~%8 yüksek olduğunu yazıyor. Başka merminin eğrisini bağlamak "ölçülmüş" iddiasını
   bozar.
3. Yine de veri tutarlı: G7 tablosuna oranla biçim faktörü ~1,10–1,21, buradan G7 BC ≈
   0,15–0,16 çıkıyor; M855 için yaygın G7 değerleriyle uyumlu. Bu kayıt ileride ses altı
   ölçümüyle tamamlanırsa kullanılabilir.

## 4. Uygulamaya eklenen altyapı (feat/surukleme-egrileri)

- `data/drag-curves/measured/*.json` — kayıt biçimi `measured/README.md`'de; her kayıtta
  `source_url`, `license`, `license_note` zorunlu.
- `tools/data_gen/generate_measured_drag_curves.py` — yalnız `use_in_app: true`, izinli lisans
  (`us-government-public-release`, `cc-by-4.0`, `cc0-1.0`, `written-permission`), https kaynak,
  ≥5 nokta, Mach ≤ 0,8'den ≥ 2,0'a kapsama ve kütüphanede birebir aynı mermi (marka, ad,
  grain) şartlarını sağlayanları `lib/data/measured_drag_curves.dart`'a yazar; diğerlerini
  nedeniyle listeler.
- `lib/data/measured_drag_lookup.dart` — kütüphane mermisi → ölçülmüş eğri.
- Profil: El dolumu listesinden eğrisi olan mermi seçilince özel eğri modu açılır ve eğri
  dolar (kayıt mevcut kullanıcı eğrisi yoluyla saklanır, çözücü `dragTable` ile kullanır);
  eğri yoksa davranış aynen eskisi gibi G1/G7 + hız bantları.
- Testler: eğri varsa kullanıldığı, yoksa G1/G7'ye dönüldüğü, eğri eklemenin G1/G7
  çözümünü değiştirmediği; generator denetimleri (Python).

## 5. İsabete beklenen etki

- **Bugün:** sıfır — uygulamada ölçülmüş eğri yok; G1/G7 sonuçları bit düzeyinde aynı.
- **İzinli eğri eklendiğinde:** iyi bir G7 BC ile ses üstü bölgede fark küçüktür; asıl kazanç
  ses geçişi (≈ Mach 1,2 → 0,9) bölgesindedir, yani merminin ses hızına yaklaştığı uzak
  mesafelerde düşüş ve rüzgâr hesabı. Kısa/orta mesafede (ses üstü) ilk atış isabetine
  etkisi sınırlıdır; hız ve sıfırlama hatası hâlâ baskın kalır. İlk atış yine canlı atışla
  doğrulanmalıdır.

## 6. Sahip için öneriler

- Yeni eğri yalnızca açık lisanslı (ör. CC-BY) veya devletin açık yayınladığı, ses altından
  ses üstüne tam tablo içeren kaynaklardan eklenmeli.
- Kullanıcılar kendi indirdikleri Doppler dosyalarını mevcut özel eğri (CSV/.drg) alanıyla
  yükleyebilir — bu kişisel kullanım, uygulamaya veri dağıtımı değildir.
- Not: görevde "font Oswald" dendi; ana dalda #173 ile yazı karakteri Inter yapılmış. Bu işte
  görünür değişiklik olmadığı için yazı karakterine dokunulmadı.
