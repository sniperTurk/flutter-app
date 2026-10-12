# Türkiye'de satılan PCP saçma/slug — resmi kaynak taraması (2026-10-12)

Görev: Türkiye'de satılan PCP saçma ve slug'ları `lib/data/bullet_library.dart` (PCP) listesine eklemek.
Değerler yalnızca markanın kendi resmi sitesinden okundu. Satıcı sitelerinden yalnızca marka ve model adı
(ipucu olarak) alındı. Forum, blog, satıcı değeri, ChairGun, Strelok, Applied Ballistics, JBM, QuickLOAD ve
GRT verisi kullanılmadı. Erişim yalnızca WebFetch/WebSearch ile yapıldı. robots.txt'in yasakladığı ya da
okunamayan sayfalar için başka bir yol denenmedi.

Kayıtlar `data/muhimmat/bullets-pcp/*.json` dosyalarında, şema `spoton.json` ile aynı. Her kaydın
`source_url` alanı değerin okunduğu sayfadır, `notes` alanı ham metni ve okuma tarihini
(erişim 2026-10-12) içerir. Kayıtlar kütüphaneye `tools/data_gen/add_muhimmat_bullets.py` ile eklendi.
Betik var olan satırları değiştirmez, çoğaltmaz (aynı marka ve ad) ve tekrar çalıştırılabilir.
Testler: `tools/test_v401_tr_sacma.py`.

BC: Üretici sayısal BC yayımlamıyorsa `bc` null kalır, formdaki BC kutusu da boş kalır. BC modeli üretici
tarafından yazılmamışsa JSON'da `bc_model` null'dır. Kütüphane satırındaki sürükleme modeli alanı boş
olamadığı için, mevcut PCP satırlarındaki gibi G1 yazılır (sahibin kuralı).

## Eklenen kayıtlar

| Marka | Dosya | Eklenen | BC'li | Resmi kaynak |
|---|---|---|---|---|
| Hatsan (Apolo serisi) | hatsan_apolo.json | 35 (8 slug, 27 saçma) | 0 | https://hatsanairgunsusa.com/product-category/ammo/ (sahibin belirttiği sayfa: /product/apolo-slug/) |
| H&N | hn.json | 27 | 10 | https://www.hn-sport.de/en/ |
| Diana | diana.json | 14 | 0 | https://www.diana-airguns.de |
| Gamo | gamo.json | 32 | 0 | https://gamousa.com (Gamo USA; gamo.com ürün sayfalarında grain değeri yok) |
| SkyPellets | skypellets.json | 12 | 0 | https://skypellets.com (SKY METAL San. ve Tic. A.Ş., İzmir Torbalı) |
| **Toplam** | | **120** | **10** | |

Değişmeyenler:

- My Bullet: 6,35 mm 32/38/45/60 gr ve 5,5 mm 22/30/38 gr kayıtları kütüphanede zaten var. Resmi
  sayfa (https://mybullet.com.tr/urunler-635.php) yeniden okundu ve başka varyant yok.
- Spoton: Mercur ve Pars dahil 30 kayıt zaten var.
- Hatsan: Pointed Head, Vortex Strike ve Vortex Big Bore kayıtları zaten var.
- Air Arms: resmi sayfadaki (https://resources.air-arms.co.uk/airarmspellets) bütün ürünler zaten var.
- Crosman: crosman.com'daki 7 saçma sayfasının hepsi zaten var.

## Eklenmeyenler ve nedenleri

| Marka / ürün | Neden |
|---|---|
| Hatsan Flash 32 gr, Hercules 45 gr saçma | Resmi sitelerde (hatsan.com.tr, hatsanairgunsusa.com) böyle bir saçma ürünü yok. "Flash" ve "Hercules" yalnızca tüfek ve şarjör adı olarak geçiyor. |
| Apolo Slug Star, Apolo Jumbo .22 | Ürün sayfası kendi içinde iki farklı ağırlık veriyor (32/21 gr ve 21/22 gr). |
| Apolo kendi sitesi (apoloammo.com) | robots.txt yasaklıyor; okunmadı. |
| JSB | jsb-match-diabolo.com, jsbmatchdiabolo.com ve jsb-match.cz robots.txt ile kapalı. Başka resmi alan adı bulunamadı. |
| RWS | rws-ammunition.com robots.txt'i Anthropic botlarını (ClaudeBot, anthropic-ai) adıyla yasaklıyor. Mevcut 44 RWS kaydına dokunulmadı. |
| Shock (Shock Solid Bullet / Shock Slugs) | Resmi site bulunamadı. Aday alan adları (shockslugs.com, shockslug.com) robots.txt ile kapalı ve sahiplikleri doğrulanamadı. |
| Hunthink | Resmi site bulunamadı. hunthink.com.tr robots.txt ile kapalı, hunthink.com açılmadı. |
| SkyPellets Hunter Premium (Light) 6,35 mm | Resmi sitede yok (yalnızca Dome, Flat ve Point serileri var). |
| İnce Mehmet, Beta Solid / Hawk Slug, EB Solid, Golden Eagle, Vurgun, Shotmaxx, Engin Sak | Resmi site bulunamadı. Arama sonuçlarında yalnızca satıcı siteleri çıktı. |
| Kral Arms | Resmi sitede (kralarms.com) saçma veya slug ürünü yok. |
| Diana Magnum (44906002) | Sayfada "6,35 mm (.23)" ile "1,30 g (20.06 grs)" birlikte yazıyor; çelişkili olduğu için eklenmedi. |
| Gamo Blue Flame .177 | Tabloda 5.1 gr, açıklamada 5.4 grain yazıyor. |
| H&N Rabbit Magnum Power, Hornet Pistol | Ürün sayfaları açılmadı. |
| Çelik BB, ok, kombo paketler | Görev dışı. |

## İpucu kaynakları (değer kaynağı değil)

- https://www.izmiravmarket.com/kategori/pellet-sacma (359 ürün): robots.txt sorgulu kategori adreslerini
  (`/kategori/*?*`, sayfalama dahil) yasaklıyor. Bu yüzden yalnızca 1. sayfa, marka site haritası
  (`/xml/sitemap_brand_*.xml`) ve JSB marka sayfası okundu. Hatsan, Skypellets, Shock ve Hunthink marka
  sayfaları HTTP 429 (proxy) verdi ve yeniden denenmedi. Bu yüzden 359 ürünün hepsi gezilemedi.
  Saçma satan markalar 1. sayfadan ve marka listesinden çıkarıldı: H&N, JSB, Hatsan, Spoton,
  Skypellets, Shock, Hunthink, Air Arms, Crosman, Diana, Gamo, RWS, Kral Arms, İnce Mehmet, Beta, Hawk.
- https://www.hatsanstore.com/635-mm-pelletler-pmk34: sunucu hatası verdi, okunamadı.
