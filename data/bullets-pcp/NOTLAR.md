# PCP saçma ve slug verisi — toplama notları (2026-10-10)

Kaynak kuralı: yalnızca üreticinin kendi sitesi / föyü / resmi mağazası. ChairGun, forum, perakendeci kullanılmadı.
BC üretici tarafından yayınlanmıyorsa `bc: null`. BC modeli belirtilmemişse `bc_model: null` ve not düşüldü.

## Dosyalar
| Dosya | Kayıt | BC'li |
|---|---|---|
| nsa.json | 117 | 113 |
| zan.json | 89 | 4 |
| hn.json | 46 | 46 |
| rws.json | 44 | 0 |
| crosman_benjamin.json | 17 | 0 |
| hatsan.json | 15 | 0 |
| air_arms.json | 11 | 0 |
| my_bullet.json | 7 | 0 |
| fx.json | 1 | 0 |
| **Toplam** | **347** | **163** |

## Verilen kararlar
- **JSB: veri yok.** jsb-match.com, jsb-match.cz, jsbmatchdiabolo.com robots.txt ile erişimi engelliyor. jsbdiabolo.com bir distribütöre (AIR CHRONY s.r.o.) ait olduğu için kullanılmadı.
- **Daystate: veri yok.** daystate.com Rangemaster sayfaları sürekli HTTP 429 döndü; boş dosya eklenmedi.
- **FX:** Hybrid Slug artık fxairguns.com'da yok (yalnızca perakendecilerde). FX Premium sayfası kalibre–ağırlık eşleşmesini vermediği için 9 kayıt (tahmin olacağından) çıkarıldı. Sadece FX Halo .30 46 gr kaldı.
- **H&N:** uygulamadaki 37 kayıt tekrarlanmadı. Üreticinin "kafa ölçüleri 4.50–4.52" gibi aralıklarında her 0.01 mm ayrı kayıt yapıldı. Inç cinsinden slug çapları mm'ye çevrildi. Rate limit nedeniyle Terminator, Rabbit Magnum II, Silver Point, Spitzkugel, Finale Match, Excite serisi alınamadı.
- **H&N BC:** üretici G1/GA belirtmiyor → `bc_model: null`.
- **NSA:** BC modeli belirtilmiyor (yalnızca .35 125 gr'da "G1"). Nominal kalibreler: .45/.457 → 11.43, .50 → 12.7, .357 → 9.0.
- **Zan:** Hyper Line varyantlarının çoğunun BC'si 429 nedeniyle okunamadı (null). .30 kurşunsuz saçmada site "o.056" yazıyor; 0.056 olarak kaydedildi. .25 Hyper Line (11 ağırlık / 4 varyant belirsiz) atlandı.
- **RWS:** rws-airguns.com robots.txt ile engelli; tüm veriler RWS resmi föyünden (PDF), gram → gr çevrildi (×15.4324). Ürün kodu yok. Föydeki isimsiz iki .25 değeri atlandı.
- **Crosman/Benjamin:** crosman.com'da ve 2026-27 kataloğunda Benjamin saçma/slug yok; tüm kayıtlar Crosman. Wadcutter: sayfa 7.40 gr, katalog 7.6 gr → sayfa değeri.
- **Hatsan:** hatsan.com.tr (Pointed) + Hatsan USA resmi mağazası (Vortex Strike, Vortex Big Bore Supreme). BC yayınlanmıyor.
- **My Bullet:** 22 gr slug için liste 1.45 g, detay sayfası 1.43 g; 22 gr yazıldı.
- **Bulunamayan / erişilemeyen:** Spoton (spoton.com.tr ürün sayfaları 429), Altaros (altaros.cz 429), İnce Mehmet, EB Solid, Shock Slugs, Beta Solid/Hawk Slug, Öztay (resmi site/özellik bulunamadı). Kral Arms saçma üretmiyor.

## Sonraki çalıştırma için
JSB (tarayıcıyla kaydedilmiş sayfa/PDF gerekiyor), Daystate, Spoton, Altaros, H&N eksik seriler ve Zan Hyper Line BC'leri.
