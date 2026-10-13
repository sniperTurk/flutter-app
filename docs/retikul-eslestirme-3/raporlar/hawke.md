# Hawke retikül raporu (okuma tarihi 2026-10-12)

Kaynak olarak yalnız hawkeoptics.com alt alan adları kullanıldı (us., life.). Ürün sayfalarında retikül adı, retikül grubu, odak düzlemi ve klik değeri var. Retikül ölçüsü (aralık, uzanım vb.) hiçbir okunabilen sayfada yazmıyor. Bu yüzden yeni kayıtların hepsinde ölçek alanları null ve hiçbiri çizilemiyor; kayıtlar yalnız eşleştirme ve birim için oluşturuldu.

## Eklenen kayıtlar (17)
| id | ad | birim | odak düzlemi | ana kaynak |
|---|---|---|---|---|
| hawke-ffp-half-mil-mil | FFP Half Mil | mil | FFP | sidewinder-30-ffp-4-16x50-ffp-half-mil.html |
| hawke-ffp-mil-pro-ext-mil | FFP Mil Pro Ext. | mil | FFP | frontier-34-ffp-3-18x50-mil-pro-ext.html |
| hawke-ffp-moa-pro-ext-moa | FFP MOA Pro Ext. | moa | FFP | frontier-34-ffp-3-18x50-moa-pro-ext.html |
| hawke-ffp-moa-hunter-moa | FFP MOA Hunter | moa | FFP | frontier-30-ffp-4-20x50-moa-hunter.html |
| hawke-mil-fd-mil | Mil FD | mil | SFP 10x | frontier-30-fd-1-10x24-mil-fd.html |
| hawke-moa-fd-moa | MOA FD | moa | SFP 10x | frontier-30-fd-1-10x24-moa-fd.html |
| hawke-tactical-dot-mil | Tactical Dot | mil | SFP | frontier-30-1-6x24-tactical-dot.html + life.hawkeoptics.com/press-tactical-riflescope/ ("10 mil spacing when on 6x") |
| hawke-20x-half-mil-mil | 20x Half Mil | mil | SFP | sidewinder-30-sf-8-32x56-20x-half-mil.html |
| hawke-10x-half-mil-mil | 10x Half Mil | mil | SFP | sidewinder-30-sf-4-16x50-10x-half-mil.html |
| hawke-10x-half-mil-dot-mil | 10x Half Mil Dot | mil | SFP | vantage-30-wa-sf-4-16x50-half-mil-dot-ir.html |
| hawke-ffp-half-mil-dot-mil | FFP Half Mil Dot | mil | FFP | vantage-30-wa-ffp-4-16x50-half-mil-dot-ir.html |
| hawke-mil-pro-ii-10x-mil | Mil Pro II (10x) | mil | SFP | vantage-hd-30-4-16x50-sf-mil-pro-ii.html |
| hawke-mil-pro-ii-20x-mil | Mil Pro II (20x) | mil | SFP | vantage-hd-30-6-24x50-sf-mil-pro-ii.html |
| hawke-l4a-dot-2-moa-moa | L4A Dot (2 MOA) | moa | SFP | vantage-30-wa-1-4x24-l4a-dot.html |
| hawke-l4a-dot-moa | L4A Dot | moa | SFP | vantage-ir-4-12x50-l4a-dot.html (sayfada "L4A Dot (2.5 MOA)") |
| hawke-l4a-dot-4x-moa | L4A Dot (4x) | moa | SFP | vantage-hd-30-1-8x24-l4a-dot.html |
| hawke-30-30-duplex-moa | 30/30 Duplex | moa | SFP, family=duplex | vantage-2-7x32-3030.html (birim taret biriminden alındı, sayfada ölçü yok) |

Birimin nereden geldiği: retikül adındaki Mil/MOA sözcüğü; FFP kayıtlarında ayrıca Hawke'nin "All Hawke FFP riflescopes are currently designed with Mil spaced reticles" cümlesi; L4A Dot kayıtlarında üreticinin MOA cinsinden verdiği tek değer ("2 MOA", "2.5 MOA", "(4x) 2 MOA"); Tactical Dot'ta basın bülteni. Bu değerlerin nokta çapı olduğu metinde açıkça yazmadığı için ölçek alanlarına konmadı.

## Düzeltilen mevcut kayıtlar (2), "belirsiz" sonucunu çözmek için
- **hawke-amx**: `scopes` alanındaki "Airmax 30 SF Compact (AMX IR)" girdisi üç tam model adına açıldı (3-12x40, 4-16x44 ve 6-24x50 AMX IR). Kanıt: ürün sayfasında Reticle "AMX IR", Reticle Group "AMX", SFP, 1/10 MRAD. `notes` alanına ek yapıldı. Başka alan değişmedi.
- **hawke-ffp-amx**: `scopes` alanı ["Airmax 30 FFP SF 4-16x50", "Airmax 30 FFP SF 6-24x50"] oldu ("(16x)"/"(24x)" ekleri çıkarıldı, büyütme bilgisi notta). Kanıt: 6-24x50 sayfasında "FFP AMX IR (24x)", FFP, 1/10 MRAD. `notes` alanına ek yapıldı.
- Etkisi: eşleştiricinin `names_scope` kuralı artık Compact dürbünleri hawke-amx'e, FFP dürbünleri hawke-ffp-amx'e bağlıyor. Benzetimde 5 "belirsiz" eşleşme çözüldü.

Benzetim sonucu: repo kütüphanesine bu çıktı eklendiğinde Hawke ad eşleşmeleri ok 53, kayit-yok 52, baska-marka 18, birim-farki 7 çıkıyor.

## Dürbün düzeltmeleri
Yok. `scope_changes.json` boş liste. Retikül adı boş Hawke dürbünü de yok.

## Karar verilemeyenler
- **Birim üretici tarafından verilmiyor**, bu yüzden kayıt oluşturulmadı (tahmin yasağı). Bunlar MOA taretli SFP balistik/BDC retiküller ve SR Pro II:
  - LR2 FD (4 dürbün), LR Dot (4), L4A FD (3), L4A FD (4x) (3), SR Pro II (3, MRAD taret)
  - .223/.308 Marksman, (12x) ve (16x) sürümleri, 223/308, 6.5 Creedmoor Marksman, Straightwall/Straight-Wall Marksman
  - Circle Dot, Tactical BDC 5.56 / "Tactical BDC - 5.56" (ikisi aynı anahtar), Turkey Dot IR, LRX - Tactical FD, LRX - Hunter FD
  - LR2 (16x/20x), LR2 Dot (16x/20x), L4A Dot (3x)
  - 30/30 Centre Cross: ölçeksiz olup olmadığı yazmıyor.
  - Bütün Rimfire çeşitleri (.17 HMR, .17 HMR (12x)/(16x), .22 (Subsonic), .22 LR HV, .22 HV, 22 LR, .22 WMR)
  - Slug Gun ve Muzzleloader: seri tablosunda tek retikül olarak "Slug Gun / Muzzleloader" geçiyor, retikül sayfasında "Slug Gun SR". Dürbün kaydı " / " ile iki ada bölüyor, bu yüzden tek kayıtla eşlenemez.
  - Orkestratör bu retiküller için birimi taret biriminden almayı kabul ederse, isimler ve sayfa kanıtları yukarıda hazır.
- **Mil Dot IR (10 dürbün) ve Mil Dot (8)**, baska-marka: ad "Mil" birimini taşıyor, dürbünler 1/4 MOA taretli. Eşleştirici kuralına göre adda yazan birim taretle uyuşmadığı için hiçbir kayıtla eşleşmez. Mevcut hawke-mil-dot ("Mil Dot (10x)", mil) doğru birimde duruyor. Bu, veri değil kural sorunu.
- **Half Mil Dot (3, Vantage SF)**, birim-farki: ürün sayfasında "Half Mil Dot" var ama Click Value "1/4 MOA". Adda mil yazıyor, yukarıdakiyle aynı durum.
- **AMX (4, 1" Airmax)**, birim-farki: Hawke "the AMX reticle, which is based on mil spacing" diyor, dürbünler 1/4 MOA taretli. MOA kaydı oluşturmak üretici bilgisine aykırı olurdu, bu yüzden oluşturulmadı.
- **FFP MOA (2, Sidewinder 30 FFP)**: ad anahtarı boş çıkıyor (FFP atılıyor, MOA birim sayılıyor), hiçbir kayıtla eşlenemez. Ürün sayfası "FFP MOA (16x)" diyor; ad yine "16X" gibi anlamsız bir anahtara düşeceği için kayıt veya düzeltme önerilmedi.

## Okunamayan kaynaklar
- `https://us.hawkeoptics.com/hawke/reticles/white/*.svg` (retikül çizimleri): ROBOTS_DISALLOWED.
- `https://reticles.hawkeoptics.com/` (ürün sayfasındaki "Reticle Booklet" bağlantısı): CLIENT_ERROR, 2 deneme (https ve http).
- `https://reticle.hawkeoptics.com/16412` ("LR2 FD (10x)" sayfası, aramada bulundu): CLIENT_ERROR, 2 deneme.
- `https://docs.hawkeoptics.com/` ve `https://docs.hawkeoptics.com/14252/`: CLIENT_ERROR.
- Reticle Booklet ve katalog PDF'leri docs.google.com üzerinde. Bu alan izinli değil, denenmedi.
- life.hawkeoptics.com'daki dergi incelemesi PDF'leri üçüncü taraf metni olduğu için kullanılmadı.
