# V375 — dürbün: profil birimi, FFP/SFP ve büyütme, hesap dökümü

Kaynak: `main` @ `2e41a37`. Solver, katalog, `validation/*` ve üretim kapısı
değişmedi.

## Üretim kodu
- `lib/core/scope_dial.dart`: `standardClick` (0.1 mrad / ¼ MOA), `convert`
  (1 mrad = 3.43775 MOA), `reticleSubtension` (FFP = 1; SFP = kalibrasyon /
  büyütme) ve `visibleHalfField` (görüş alanı büyütmeyle ters orantılı).
- `lib/features/ballistics/ballistics_screen.dart`: dürbün görünümünün birimi
  artık profildeki "Dürbün birimi". MRAD profil → MRAD retikül + MRAD kule;
  MOA profil → MOA retikül + MOA kule. Katalog kulesi farklı birimdeyse o
  birimin standart kliği kullanılır ve uyarı gösterilir. Klik sayısı kartları
  ve kule sınırları aynı birimi kullanır. Büyütme durumu çalışma alanında
  tutulur (varsayılan: en yüksek büyütme).
- `lib/features/ballistics/scope_dial_view.dart`:
  - Büyütme kaydırıcısı (katalogda min/maks büyütme varsa).
  - FFP: retikül görüntüyle birlikte büyür/küçülür, çizgiler her büyütmede
    gerçek değerdedir.
  - SFP: retikül ekranda sabit; en yüksek büyütmede kalibre kabul edilir.
    Başka büyütmede 1 çizgi = kalibrasyon / büyütme; kırmızı mesafe ve
    turuncu rüzgâr etiketleri bu gerçek açıyla hesaplanır, "1 çizgi = X"
    uyarısı retikülde gösterilir.
  - Vuruş noktası her zaman gerçek açı ölçeğinde çizilir.
  - "Hesap dökümü": 1 birimin mesafedeki karşılığı, gereken düzeltme (cm →
    birim → diğer birim), klik = düzeltme / klik değeri, diğer birimdeki
    klik karşılaştırması, kuledeki ayar, kalan, FFP/SFP tutuşu.
- `lib/features/profiles/profiles_screen.dart`: dürbün seçilince "Dürbün
  birimi" o dürbünün kule birimine ayarlanır (kullanıcı değiştirebilir).

## Testler
- `test/scope_dial_test.dart`: birim dönüşümü, 1 mrad = 10 × 0.1 mrad klik =
  14 × ¼ MOA klik, FFP/SFP çizgi değeri, görüş alanı.
- `test/scope_dial_view_test.dart`: MOA profil + MRAD katalog dürbünü uyarı ve
  ¼ MOA klik hesabı; SFP 12x/24x çizgi değeri ve tutuş.

## ÇALIŞTIRILMADI / DOĞRULANMADI
- Bu sandbox'ta Flutter yok (SDK indirme adresi engelli); analyze/test/format
  sonucu PR'ın iOS CI koşusundadır.
