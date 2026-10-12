# Türkçe metin denetimi — 2026-10-11

Kapsam: `lib/` altındaki kullanıcıya görünen tüm metinler (etiketler, ⓘ
açıklamaları, uyarılar, hata iletileri, tablo başlıkları, düğmeler).
Yöntem: Dart dizge sabitleri betikle çıkarıldı (~2 050 satır) ve tek tek
okundu; `MenzilInput` / `MenzilSelect` çağrıları ayrıca `info:`,
`helperText:` ve `hintText:` için tarandı.

Uygulanan kurallar (sahibi, CLAUDE.md ve görev):
"Sight height" İngilizce kalır · etiketlerde parantez yok · kutu altında
yardım yazısı yok (Rüzgâr düzeltmesi kutusundaki sahibinin istediği
açıklamalar hariç) · kalın yazı yok · kutularda örnek değer yok · liste
kutuları "Seçiniz" ile başlar (Tür hariç) · her girilen/seçilen değerin ⓘ
açıklaması olur (marka/model/ad hariç).

Durum sütunu: **D** = bu dalda düzeltildi, **Ö** = öneri, sahibinin kararı
gerekir (davranış değiştirir), uygulanmadı.

## 1. Yazım, noktalama, Türkçe karakter

| Dosya | Eski | Önerilen | Durum |
|---|---|---|---|
| tools/hit_probability_screen.dart | atış kağıdında | atış kâğıdında (uygulamanın geri kalanı "kâğıt") | D |
| ballistics/incline_measure_screen.dart | Nişangahı hedefe yerleştirin ve OK'a basın. | Nişangâhı hedefe yerleştirin ve Tamam'a basın. | D |
| ballistics/incline_measure_screen.dart | düğme "Set 0°" | 0°'a ayarla (Dürbün eğimi ekranındaki "0'a ayarla" ile aynı) | D |
| ballistics/incline_measure_screen.dart | düğme "OK" | Tamam | D |
| ballistics/pro_section_info.dart (Tüfek eğimi) | "Telefonla ölç"e dokun … "OK"a bas | "Kamerayla ölç"e dokun … "Tamam"a bas (düğmenin gerçek adı "Kamerayla ölç") | D |
| ballistics/environment_field_info.dart (shotRange) | "Haritadan" ile seçin | "Haritadan ölç" ile seçin (düğmenin gerçek adı) | D |
| ballistics/ballistics_screen.dart | … rüzgâr yönü 0–360° olmalı. | … rüzgâr yönü saat 1–12 olmalı. (alan artık saat olarak giriliyor) | D |
| ballistics/ballistics_screen.dart | Deterministik vacuum/gravity temel solver. | Vakum temel hesap (yalnızca yerçekimi). | D |
| ballistics/ballistics_screen.dart | * Vacuum solver hava direncini hesaplamaz | * Vakum hesabı hava direncini hesaplamaz | D |
| ballistics/ballistics_screen.dart | vacuum temel hesap yapılır (2 yer) | vakum temel hesap yapılır | D |
| ballistics/ballistics_screen.dart | doğrulanmış drag modeli | doğrulanmış sürüklenme modeli | D |
| ballistics/ballistics_screen.dart | doğrulanmış sürükleme modeli | doğrulanmış sürüklenme modeli ("Sürüklenme eğrisi" ile aynı terim) | D |
| ballistics/ballistics_screen.dart | (chronograph + deneme atışı) | (kronograf + deneme atışı) | D |
| ballistics/ballistics_screen.dart | grup (tüfek ve atıcı) | grup (tüfek ve nişancı) — diğer ekranlarda "nişancı" | D |
| core/velocity_truing.dart | hız farkı düşümü yeterince değiştirmiyor | hız farkı düşüşü yeterince değiştirmiyor | D |
| tools/tools_screen.dart | Sahada gözlenen düşümle namlu hızını doğrula | Sahada gözlenen düşüşle namlu hızı doğrulama | D |
| tools/truing_screen.dart | düşüm ne kadar büyükse | düşüş ne kadar büyükse | D |
| home/empty_states.dart | Açı, Rüzgâr bölgeleri, Coriolis ve Spin Drift | Açı, rüzgâr bölgeleri, Coriolis ve spin drift | D |
| tools/sight_height_screen.dart | Kumpas ile ölçünüz. (3 yer) | Kumpasla ölçün. (diğer metinlerle aynı kip) | D |

## 2. Aynı kavram için farklı terimler

| Kavram | Bulunan | Seçilen | Durum |
|---|---|---|---|
| Kule adımı | klik (Profil, Hedef, DOPE notları) / tık (DOPE tablosu "Tık", Hesaplayıcılar, Pro açıklamaları, Hız Doğrulama) / tıklama | **klik** — Profil'deki "Klik değeri" ile aynı. "Tıklama değeri doğrulama" → "Klik değeri doğrulama". İstisna: Araçlar menüsü alt yazısı ve Hız Doğrulama ⓘ metni "tık" olarak kaldı; `tools/test_m1_tools_scope_contract.py` sözleşmesi Hesaplayıcılar dışındaki araç ekranlarında "klik" kelimesini yasaklıyor (atış talimatı gibi okunmasın diye). | D |
| İsabet olasılığı | "Vuruş Olasılığı" (Araçlar) / "İsabet olasılığı" (Pro) | **İsabet Olasılığı** ("Vuruş noktası" ayrı kavram, değişmedi) | D |
| Sıfırlama mesafesi | "Sıfır mesafesi" (Balistik/DOPE alanı, hata metni) / "Sıfırlama mesafesi" (Profil) | Alan etiketi ve hata etiketi **Sıfırlama mesafesi** | D |
| Namlu çıkış hızı | "Namlu hızı" (profil hata metni) / "Namlu çıkış hızı" (alan) | Hata metni etiketi **Namlu çıkış hızı** | D |
| Sight height | "Dürbün yüksekliği", "Dürbün eksen yüksekliği" (Sight Height aracı, hata metinleri, Hız Doğrulama) / "Sight height" (Profil) | **Sight height** (sahibinin kuralı: İngilizce kalır) | D |
| İrtifa | "Rakım" (Hava laboratuvarı) / "İrtifa" (Hava Durumu) | **İrtifa** | D |
| Mühimmat / fişek / mermi / saçma | Bilinçli ayrım: mühimmat = genel, fişek = fabrika/el dolumu kartuş, mermi = ateşli tüfek çekirdeği, saçma = PCP. Tutarlı kullanılıyor. | değişiklik yok | — |
| Dürbün / optik | Yalnız "dürbün" kullanılıyor | — | — |
| Retikül | Her yerde "retikül" | — | — |

## 3. Birim yazımı ve ondalık virgül

| Dosya | Eski | Önerilen | Durum |
|---|---|---|---|
| ballistics_screen.dart, scope_dial_view.dart, profiles_screen.dart | ekranda gösterilen sayılar `toStringAsFixed` ile nokta ondalıkla (ör. "1.0 cm sağ", "Sıfır mesafesi 30.0 yd", "2.000 mrad", "BC 0.04", DOPE tablosu ve kartı, ateşli kalibre listesindeki çap "7.82 mm", "0.005–1.5 arasında") | virgül: "1,0 cm", "Sıfırlama mesafesi 30,0 yd", "2,000 MRAD", "BC 0,04", "7,82 mm", "0,005–1,5" (Araçlar ekranları zaten virgül kullanıyor). Kutulara otomatik yazılan değerler (Hava Durumu doldurma vb.) değişmedi. | D |
| data/cartridges.dart, data/rifle_library.dart | PCP kalibre listesi "6.35 mm (.25)" (nokta) | "6,35 mm (.25)" olmalı; ancak bu metin aynı zamanda kayıtlı profillerde ve tüfek kataloğunda anahtar olarak saklanıyor. Değiştirmek için ekranda gösterirken çevirmek ya da veri göçü gerekir | Ö |
| ballistics/scope_dial_view.dart | 1 SMOA = 0.27778 mrad = 0.955 MOA · 1 MOA = 0.29089 mrad · 1 mrad = 3.43775 MOA · mesafe(m) × 0.02909 cm | 0,27778 MRAD = 0,955 MOA · 0,29089 MRAD · 3,43775 MOA · 0,02909 cm | D |
| Çeşitli | mrad / MRAD karışık (DOPE tablosu "Yükseklik mrad", "Rüzgâr mrad", ⓘ metinleri "0,1 mrad", klik listesi "0,1 mrad", Hedef ekranı birimi) | **MRAD** (Profil'deki birim adı) | D |
| tools/reticle_screen.dart | "1 mil", "okunan mil", "kaç mil" | MIL (Hesaplayıcılar ile aynı); "mil-dot" ürün adı olarak kalır | D |
| ballistics/ballistics_screen.dart | Mesafe enerjisi ft-lb, Namlu enerjisi ft-lb | ft·lbf (Hesaplayıcılar ile aynı) | D |
| ballistics/environment_field_info.dart | 3–5 %, 1–2 % | %3–5, %1–2 | D |
| tools/weather_screen.dart | Nem "50 %" | %50 | D |
| tools/reticle_screen.dart | kutu ön değeri "4.5" | 4,5 | D |
| °C, m, mm, bar, MOA | Sayı ile birim arasında boşluk ve "°C" yazımı tutarlı | — | — |

## 4. Hitap tutarlılığı (sen / siz)

Alan ⓘ açıklamalarının çoğu "siz" diliyle yazılmış; aşağıdakiler aynı
ekranda "sen" diline kayıyordu. Pro kutularındaki Ne?/Neden önemli?/Nasıl?
anlatımı ve tanıtım ekranı baştan sona "sen" ile yazıldığı için olduğu gibi
bırakıldı.

| Dosya | Eski | Önerilen | Durum |
|---|---|---|---|
| environment_field_info.dart | gravity, proShotRange, windMid, windFar, sd, targetSize, rangeError, bcError, wezShotCount: "Bulunduğun", "ölç", "bırakırsan", "istediğin", "olduğun", "atarsan" | siz kipi: "Bulunduğunuz", "ölçün", "bırakırsanız" … | D |
| ballistics/scope_dial_view.dart | … Hedef çapı'ndan değiştirebilirsin. | değiştirebilirsiniz. | D |
| home/home_screen.dart | Önce bir tüfek profili oluştur. (yanındaki satır "kaydedin") | Önce bir tüfek profili oluşturun. | D |
| profiles/profiles_screen.dart | Yeni profil ile ilk profilini oluştur. | Yeni profil ile ilk profilinizi oluşturun. | D |
| tools/calculators_screen.dart | Bulunduğun yerden girdiğin hedef konuma | Bulunduğunuz yerden girdiğiniz hedef konuma | D |
| tools/calculators_screen.dart | Dürbünü sıfırla, … at, … çevir, … ölç. / Çevirdiğin tık sayısı | Dürbünü sıfırlayın, … atın, … çevirin, … ölçün. / Çevrilen klik sayısı | D |

## 5. Etiketlerde parantez

| Dosya | Eski | Önerilen | Durum |
|---|---|---|---|
| ballistics_screen.dart (Pro) | Atış yönü (azimut) | Atış yönü | D |
| ballistics_screen.dart (Pro) | Hız farkı (SD) | Hız farkı | D |
| ballistics_screen.dart (Pro) | Mesafe hatası (±) | Mesafe hatası | D |
| ballistics_screen.dart (Pro) | BC hatası (±) | BC hatası | D |
| ballistics_screen.dart (Pro) | Yukarı (+) / aşağı (−) | Yukarı + / aşağı − | D |
| ballistics_screen.dart (Pro) | Sağ (+) / sol (−) | Sağ + / sol − | D |
| calculators_screen.dart | Dürbündeki okuma (hedefin kapladığı) | Dürbündeki okuma | D |
| calculators_screen.dart | Ölçülecek boy (isteğe bağlı) | Ölçülecek boy | D |
| calculators_screen.dart | Namlu yakını hız (V1) / Uzaktaki hız (V2) | Namlu yakını hız V1 / Uzaktaki hız V2 | D |
| calculators_screen.dart | Hedef enerji (isteğe bağlı) | Hedef enerji | D |
| reticle_screen.dart | Hedef boyu (görünen çap veya boy) | Hedef boyu | D |
| sight_height_screen.dart | Namlu iç çapı (kalibre) / Dürbün–namlu boşluğu (ön uç) / Dürbün ön dış çapı (objektif) | Namlu iç çapı / Dürbün–namlu boşluğu / Dürbün ön dış çapı | D |

Liste seçenekleri ("Normal (0 MOA)", "GA (saçma)", "FFP (ilk odak
düzlemi)") ve tablo sütun başlıkları ("Mesafe (m)") etiket değil; olduğu
gibi bırakıldı.

## 6. Kutu altında yardım yazısı / kutuda örnek değer

| Dosya | Eski | Yapılan | Durum |
|---|---|---|---|
| ballistics_screen.dart (Pro) | Hedef çapı ipucu "10"/"4", Mesafe hatası "1", BC hatası "0", Gerçek / yazan "1.00" | ipuçları kaldırıldı; boşken kullanılan değer zaten ⓘ'de yazıyor | D |
| hit_probability_screen.dart | kutu altı "Ör. 1,0 MOA", "Ör. vurulacak bölge" | kaldırıldı (ⓘ'de örnek var) | D |
| calculators_screen.dart (Mesafedeki MOA) | kutu altı "Ör. vuruş noktası ile hedef arası" | ⓘ'ye taşındı | D |
| reticle_screen.dart | kutu altı "Çoğu SFP dürbünde en yüksek büyütme…" | kaldırıldı (ⓘ'de aynı bilgi var) | D |
| sight_height_screen.dart (4 ölçü satırı) | her kutunun altında açıklama | açıklama ⓘ düğmesine taşındı | D |
| ballistics_screen.dart "En yüksek rüzgâr" | Otomatik: rüzgâr hızı × 1,5 / Boş: … | sahibinin istisnası, değişmedi | — |
| Hesaplayıcılar, Retikül, İsabet Olasılığı | kutular açılışta örnek değerlerle dolu geliyor (ör. 50 cm / 5 MIL, 100 m, 25,39 gr, 1013,25 hPa) | Kural gereği boş açılmalı; ancak bu, ekranların açılışta sonuç göstermesini ve 20+ testi değiştirir | Ö |

## 7. Kalın yazı

| Dosya | Eski | Yapılan | Durum |
|---|---|---|---|
| sight_height_screen.dart | parça açıklamalarında kalın başlık ("Namlu iç yarıçapı:") ve kalın ölçü etiketleri | normal ağırlık | D |
| Değer/sonuç sayıları (Hedef ekranı vuruş metni, harita mesafesi, DOPE PDF) | kalın | Sonuç rakamı vurgusu; metin değil. Sahibi isterse ayrıca kaldırılabilir | Ö |

## 8. Eksik ⓘ açıklamaları (CLAUDE.md kuralı)

| Dosya / alan | Durum | Eklenen açıklama |
|---|---|---|
| ballistics_screen.dart — Namlu çıkış hızı | D | Profil'deki metin (`ProfileFieldInfo.velocity` / `velocityFirearm`) |
| ballistics_screen.dart — Mühimmat ağırlığı | D | `ProfileFieldInfo.grain` / `grainFirearm` |
| ballistics_screen.dart — Sıfırlama mesafesi | D | `ProfileFieldInfo.zero` / `zeroFirearm` |
| ballistics_screen.dart — Sight height | D | `ProfileFieldInfo.sightHeight` / `sightHeightFirearm` |
| profiles_screen.dart — Tür | D | Yeni `ProfileFieldInfo.platform`: "Tüfeğinizin türü. PCP Tüfek: basınçlı havayla saçma veya slug atan havalı tüfek. Ateşli Tüfek: barutlu fişek atan tüfek. Marka, kalibre ve mühimmat listeleri ile açıklamalar bu seçime göre değişir; tüfeğinizin ruhsatında veya kutusunda yazar. Örnek: Hatsan Factor için PCP Tüfek." |
| profiles_screen.dart — Profil adı, Dürbün markası, Marka/Model seçimleri, el ile Model | — | kimlik alanı, kural gereği muaf |
| sight_height_screen.dart — 4 ölçü kutusu | D | Kutu altındaki açıklamalar ⓘ'ye taşındı |

Diğer tüm `MenzilInput` / `MenzilSelect` alanlarında ⓘ zaten vardı.

## 9. "Seçiniz"

`MenzilSelect` boşken her zaman "Seçiniz" gösteriyor (menzil_widgets.dart).
Marka/Model/Kalibre/Mermi çapı/Retikül listeleri ayrıca "Seçiniz" ile
başlıyor. Eksik bulunmadı.

## Doğrulama

- `python3 tools/offline_dart_lint.py`
- `test-diag.yml` (files=test), `analyze-diag.yml`, format iş akışı — sonuçlar
  PR açıklamasında.
