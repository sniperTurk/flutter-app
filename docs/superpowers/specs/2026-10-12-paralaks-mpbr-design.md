# Ö8 Paralaks mesafe tablosu + Ö7 Avcı sıfırı (MPBR) — tasarım

Kaynak: `docs/yeni-hesaplar-2026-10-11.md` (PR #153), Ö7 ve Ö8.
Sınıf: mimari (iki yeni araç sayfası, iki yeni hesap modülü, bir yeni kayıt).
Sahibi bu çalışmada yanıt vermiyor; görev "kendin makul cevapla" dediği için
kararlar aşağıda yazılı.

## Anlaşılan amaç

İlk atışta isabet. PCP'de belirleyici hata mesafe (50 m'de ±5 m = ±2,3 cm);
Ö8 dürbünün paralaks tekerleğini telemetre gibi kullanmayı sağlar. Ö7 mesafe
ölçülemeyen avda tutuş yapmadan vurulabilecek en uzun menzili ve sıfır
mesafesini önerir.

## Kararlar (varsayımlar)

| # | Karar | Gerekçe |
|---|-------|---------|
| D1 | İkisi de Araçlar altında ayrı sayfa: `Paralaks Mesafesi`, `Avcı Sıfırı`. | Görev önerisi; Atış ekranıyla çakışma az. |
| D2 | Paralaks kartı Araçlar'da yalnız etkin profil PCP iken görünür. Pro > Atış mesafesi kartında PCP'de "Paralakstan" düğmesi; seçilen mesafe kutuya yazılır, kullanıcı değiştirebilir. | "Yalnızca PCP profilde görünür"; "atış mesafesine yazılır (kullanıcı değiştirebilir)". Haritadan ölç ile aynı desen. |
| D3 | Tekerlek işareti sayıdır (tekerlekteki rakam veya çentik sırası). | Ara değerleme sayısal sıra ister. |
| D4 | Kayıt profil başına (`sniper_turk.parallax.<profilId>`), mesafe metre. Aynı işaret tekrar girilirse mesafesi güncellenir. | Profil = tüfek + dürbün; ShotSettings ile aynı desen. |
| D5 | Sahada liste: kayıtlı işaretler ve her ardışık çiftin ortası. Doğrusal ara değer; aralık dışı uç değerle sınırlanır; 2'den az farklı işaret → hesap yok. | "En az 2 nokta, uydurma ekstrapolasyon yok". |
| D6 | MPBR havası ICAO (15 °C, 1013,25 hPa, %0), profil hızı, standart yerçekimi, düz atış, rüzgârsız. | Uygulamanın sıfır varsayımı ile aynı; öneri profil özelliğidir, günlük hava değil. |
| D7 | Tarama: sıfır mesafesi adım adım artırılır; yörünge hedef bölgenin üst sınırını aşınca son uygun ile ilk uygunsuz arasında ikiye bölme. Yörünge ızgarası PCP 1 m / 150 m, ateşli 5 m / 600 m; sıfır adımı PCP 2 m, ateşli 10 m. | "Mevcut çözücüyle tarama" (McCoy, düz atış: en uzun menzil tepe noktası = yarıçap iken). |
| D8 | Gösterim: Sıfır mesafesi (uzak kesişim), Yakın kesişim, Tutuşsuz aralık. Yakın sınır yukarı, uzak sınır aşağı yuvarlanır (güvenli taraf). Satır: "Sıfır 203 m: 0–237 m arası tutuşsuz". | Raporun iki örneği farklı kesişimi "sıfır" diyor (P1 16 m yakın, T1 200 m uzak); ikisi aynı yörünge, ikisi de gösterilir. |
| D9 | Profil değişmez; sonuç altında "Profilinizdeki sıfır: X m" bilgisi. | "Profili değiştirmez, öneri olarak gösterir." |
| D10 | Hedef bölge çapı cm listesi, birim sistemi ne olursa olsun cm (sahibinin listesi). Menzil profilin mesafe biriminde (m/yd). | Görev listesi cm. |

## Bağımsız denetim değerleri

`tools/formula_reference.py` (uygulama kodundan bağımsız Python çözücü) ile
aynı tarama (D7) yapıldı:

| Silah | Bölge | Yakın kes. | Sıfır | Tutuşsuz |
|-------|-------|-----------|-------|----------|
| T1 .308 175 gr G7 0,243 790 m/s 45 mm | 15 cm | 24,9 m | 203,0 m | 0–237,7 m |
| P1 .22 18 gr G1 0,031 275 m/s 50 mm | 2,5 cm | 15,9 m | 39,9 m | 10,6–44,6 m |
| P2 .22 25 gr G1 0,090 290 m/s 50 mm | 4 cm | 15,6 m | 50,2 m | 8,2–57,2 m |

Rapordaki değerlerle uyumlu (T1 200 m / 10–230 m kaba ızgara; P1 16 m,
11–44 m; P2 50 m, 9–57 m). Dart testleri bu tablodan toleranslı olarak
türetilir.

## Bileşenler

- `lib/core/parallax_range.dart` — `ParallaxPoint`, `ParallaxRange.distanceAt`,
  `pickMarks`, `upsert` (saf).
- `lib/services/parallax_table_store.dart` — SharedPreferences, sessiz hata.
- `lib/core/mpbr.dart` — `Mpbr.solve(build, zoneDiameterM, grid)`;
  `build(zeroM, ranges)` çağıranın `BallisticInput` kurucusu (çözücü değişmez).
- `lib/features/tools/parallax_screen.dart`, `mpbr_screen.dart` (+ ⓘ metinleri).
- `tools_screen.dart`: iki kart; Paralaks yalnız PCP. `home_screen.dart`:
  etkin platformu geçirir. `ballistics_screen.dart`: Pro kartında
  "Paralakstan" (yalnız PCP).

## Arayüz kuralları

Kısa Türkçe; her girilen/seçilen değerde ⓘ; kutu altında yardım yazısı ve
kutu içinde örnek yok; etiketlerde parantez yok; kalın yok; liste kutuları
"Seçiniz"; İşaret | Mesafe yan yana; Hedef bölge çapı ve Tekerlek işareti tam
satır; ayrı aç/kapa düğmesi yok.

## Hata durumları

Profil yok → durum mesajı. Ammo BC'siz → MPBR yine çalışır (vakum çözücü,
etiketli değil; çözücü ne veriyorsa). Çözüm yok → "Bu bölge çapında tutuşsuz
menzil bulunamadı." Paralaks: geçersiz sayı → kutu hatası; < 2 işaret →
"Mesafe için en az 2 işaret kaydedin."

## Test

Saf birim testleri (ara değer, sınırlama, orta noktalar, MPBR değerleri ve
yörünge özelliği), widget testleri (kayıt/seçim/geri dönüş, PCP görünürlüğü,
MPBR sonucu ve profilin değişmemesi).
