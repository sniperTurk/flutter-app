# Üretici yayınlı ücretsiz sürüklenme eğrileri (Cd–Mach) — katalog

Tarama tarihi: 2026-10-10 (otomatik zamanlanmış görev, sahibi çevrimdışı; kararlar aşağıda notlandı).
Kural: yalnızca üreticinin kendi sitesinde, hesap/ödeme/onay kutusu olmadan indirilebilen veriler.
Applied Ballistics, ChairGun, Strelok, Wikipedia/Wikimedia, forumlar ve arşiv kopyaları kaynak olarak KULLANILMADI.

## Sonuç

**Repoya eklenen eğri (JSON) sayısı: 0.**
Aşağıdaki iki kaynak teknik olarak ücretsiz erişilebilir, ancak biri sitenin kullanım şartı
nedeniyle, diğeri hem şart hem de indirilemediği için JSON'a dönüştürülmedi.
Karar mantığı: lisans şüpheliyse veriyi repoya koymak yerine bağlantı + şart metni katalogla.

## Bulunanlar (veri var, JSON yok)

### Warner Tool — Flatline (Doppler Cd–Mach PDF tabloları)
- Sayfa: https://www.warner-tool.com/doppler-data/ (giriş/ödeme gerekmiyor)
- Biçim: pdf-table (Mach, Cd, G1, G7 sütunları; ~Mach 0.5–2.5+, birden çok atış serisi)
- PDF'ler (hepsi `https://www.warner-tool.com/wp-content/uploads/2020/12/` altında):
  - `375-400GR-FLATINE-DOPPLER.pdf` — .375 400 gr
  - `375-361GR-FLATINE-DOPPLER.pdf` — .375 361 gr
  - `338-285GR-FLATINE-DOPPLER.pdf` — .338 285 gr
  - `338-256GR-FLATINE-DOPPLER.pdf` — .338 256 gr
  - `30-198GR-FLATINE-DOPPLER.pdf` — .30 198 gr
  - `30-180GR-FLATINE-DOPPLER.pdf` — .30 180 gr (1:8 twist)
  - `30-160GR-FLATINE-DOPPLER.pdf` — .30 160 gr
  - `30-155GR-FLATINE-DOPPLER.pdf` — .30 155.5 gr
  - `7MM-151GR-FLATINE-DOPPLER.pdf` — 7 mm 151 gr
  - `6.5MM-123GR-FLATINE-DOPPLER.pdf` — 6.5 mm 123 gr
  - `6.5MM-121GR-FLATINE-DOPPLER.pdf` — 6.5 mm 121 gr
  - `6MM-88GR-FLATINE-DOPPLER.pdf` — 6 mm 88 gr
  - .416 550 gr / 505 gr: sayfada başlık var, bağlantı yok.
- PDF içindeki not: "For more data sheets, videos and to order online, visit: warner-tool.com" (ayrı lisans yok).
- Site kullanım şartı (https://www.warner-tool.com/terms-and-conditions/, aynen):
  - "The content displayed on the Site (“Content”) is the property of Warner Tool or its licensors, and is protected by U.S. and international copyright and other intellectual property laws."
  - "User agrees not to copy, reproduce, modify, display, perform, publish, create derivative works from, or store any Content on the Site."
  - "User also agrees not to distribute, transmit, broadcast or circulate any Content to others, except User may, on an occasional and irregular basis, reproduce, distribute, display or transmit ... Used with permission from Warner Tool."
  - "Use of all Site Content is for non-commercial purposes only."
- **Durum: ATLANDI (JSON yok).** Şartlar kopyalama/saklama/yayımlamayı ve ticari kullanımı yasaklıyor.
  Uygulamaya eklemek için Warner Tool'dan yazılı izin gerekir. Kullanıcı kendi indirdiği PDF'yi
  uygulamanın mevcut özel eğri (CSV Mach–Cd) içe aktarımıyla kendisi yükleyebilir.

### Lapua — QuickTARGET Unlimited Lapua Edition (Doppler drag dosyaları içerdiği belirtiliyor)
- İndirme sayfası: https://www.lapua.com/downloads/ → `https://www.lapua.com/wp-content/uploads/2020/07/QTU.zip` (giriş gerekmiyor)
- Broşür: https://www.lapua.com/wp-content/uploads/2019/03/QTU-Lapua-Edition-brochure.pdf
  (".338 Lapua GB528 Scenar 19.44g (300gr)" Cd–Mach grafiği var, sayısal tablo yok;
  aynen: "QuickLOAD© and QuickTarget© are Copyright 1988-2009 of H.G.Broemel.")
- Eski ayrı Cd veri paketi `lapua.com/uploads/media/LapuaBulletsCD-Data.zip` artık erişilemiyor (hata).
- Lapua indirme sayfası şartı (aynen): "Please note that all materials are protected by copyright laws and may not be altered or used for unauthorized purposes."
- **Durum: ALINAMADI.** Bu bulut ortamında lapua.com ikili dosya indirmesi proxy tarafından engellendi (403),
  WebFetch zip içeriğini okuyamadı. Engel aşılmaya çalışılmadı. Ayrıca şart metni "unauthorized purposes"
  kullanımını yasaklıyor; uygulamaya dahil etmeden önce Lapua'dan izin alınması önerilir.
  Scenar-L ve Naturalis için ayrı Doppler dosyası lapua.com'da bulunamadı.

## Bulunamayanlar / uygun değil

| Üretici | Durum |
|---|---|
| Hornady | Cd eğrileri yalnızca 4DOF hesaplayıcısı/uygulaması içinde; indirilebilir dosya/tablo yok (https://www.hornady.com/team-hornady/ballistic-information/ballistic-resources/4dof-overview). |
| Berger | Özel sürüklenme modelleri Applied Ballistics üzerinden — kural gereği hariç. |
| Sierra | Ücretsiz makaleler var; sayısal Cd–Mach tablosu yayını bulunamadı. |
| Norma | Bulunamadı (yalnızca Norma hesaplayıcı). |
| Nosler | Bulunamadı. |
| Barnes | Bulunamadı. |
| Sako / RWS | Bulunamadı. |
| Cutting Edge, GS Custom, Lehigh | Bulunamadı. |

## Öneri (sahip için)
1. Warner Tool ve Lapua'ya ticari kullanım izni için yazılı talep.
2. İzin gelirse `<marka>-<mermi>.json` şeması: `{"brand","bullet","diameter_in","weight_gr","points":[[Mach,Cd],...],"source_url","license_note","format"}`.
3. İzin gelmezse kullanıcılar kendi indirdikleri dosyaları mevcut .drg/CSV içe aktarımıyla yükleyebilir.
