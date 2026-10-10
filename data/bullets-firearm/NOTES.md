# Ateşli silah mermi verisi — eksik markalar (2026-10-10, otomatik çalışma)

Kaynak kuralı: değerler yalnızca üreticinin kendi sitesinden okundu; mağaza/forum/başka uygulama verisi yok.
Okunmayan değer null. G1 ve G7 ikisi de yoksa kayıt yazılmadı. Tüm dosyalar `json.load` ile doğrulandı.
Uygulama kodu değişmedi; bu dosyalar henüz `bullet_library.dart`'a bağlı değil.

## Kayıt sayıları

| Dosya | Kayıt | Durum |
|---|---|---|
| woodleigh.json | 134 | tamam (BC türü varsayımı, aşağıda) |
| peregrine.json | 210 | tamam |
| swift.json | 70 | tamam (Break-Away: BC yok) |
| lapua.json | 22 | tamam — yalnızca uygulamada OLMAYAN Lapua çekirdekleri |
| rws.json | 20 | kısmi (hız sınırı) |
| warner.json | 14 | tamam |
| federal.json | 8 | kısmi (29 çekirdekten 8'i) |
| norma.json | 1 | kısmi (hız sınırı) |
| **Toplam** | **479** | |

## Engellenenler / eksikler
- **WebFetch hız sınırı (HTTP 429):** çalışma ortasında tüm alan adlarında devam etti; curl de bulut proxy'si tarafından reddedildi (403). Bu nedenle şunlar alınamadı:
  Norma (yaklaşık 46 ürün daha), Sako (0), Federal Fusion / kalan TBT / Bear Claw / Sledgehammer, RWS'nin .270 ve üstü kalibreleri, Geco (0), Sellier & Bellot (0), Prvi Partizan (0), MKE (0).
  Bir sonraki çalışmada, istekler sıra ile ve aralarına bekleme koyarak gönderilerek tamamlanabilir.
- **GS Custom:** gscustombullets.com robots.txt ile otomatik erişimi yasaklıyor; atlandı.
- **MKE:** mke.gov.tr küçük silah mühimmatı kataloğu (PDF) bulundu ama hız sınırı yüzünden okunamadı; BC yayımlanıp yayımlanmadığı belirsiz.
- **Prvi Partizan:** ppu-usa.com'un PPU'nun kendi sitesi olup olmadığı doğrulanamadı.
- Hiçbir sitede yaş doğrulaması görülmedi (erişilen sitelerde).

## Varsayımlar (gözden geçirin)
- **Woodleigh, Swift, RWS:** sayfalar BC'yi "BC" diye veriyor, G1/G7 belirtmiyor. Sektör geleneği (ve RWS'nin kendi hız tablosuyla uyum) gereği `g1_bc` olarak kaydedildi, `g7_bc` null.
- **Lapua:** uygulamadaki 33 Lapua kaydı tekrarlanmadı (madde kodu ile eşleştirildi). G573 ve G574 BC olmadığından atlandı. B343 (6.5 mm FMJBT 144 gr) sayfada G1 0.636 yazıyor — yüksek görünüyor, olduğu gibi bırakıldı.
- **Warner:** görevde verilen warnertool.com başka bir firma; üretici warner-tool.com. Uzunluk birimsiz basılmış, inç kabul edildi; çap kalibre adından alındı.
- **Peregrine:** sayfada 0.000 yazan BC null yapıldı; ikisi de 0 olan satırlar atlandı. Glider .509 750 gr G1 "0.1043" (yazım hatası) null yapıldı; ".209 132 gr" satırı yazım hatası sayılıp atlandı.
- **RWS:** ağırlık sayfada grain yoksa gram×15.4324 ile çevrildi.
- **Swift:** muzzleloader sayfaları revolver çekirdekleriyle aynı, tekrar yazılmadı (.452 325 gr: revolver sayfasındaki .171 tutuldu, muzzleloader sayfasında .153).
- Dikkat çeken ama sayfada böyle basılmış değerler: Lapua .32 wadcutter G1 0.029/0.041, Warner .416 550 gr G1 1.31, Peregrine Glider .509 870 gr G1 1.302.
