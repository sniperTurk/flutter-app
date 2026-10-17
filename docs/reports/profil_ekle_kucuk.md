# Profiller başlığı: daha küçük başlık ve "+ Profil ekle"

Sahip onayı: 17.10.2026 18:42 (İstanbul), "önerini yap".
Dal: `fix/profil-ekle-kucuk`. Taslak PR; birleştirme sahibin ana oturumunda.

## Ne yapıldı
- Profil sayfasındaki listenin başlığı "Profiller" **20 pt** oldu. Kalınlık ve
  renk aynı. Yalnız bu başlık değişti; `MenzilSectionHeader` varsayılanı
  (22 pt) ve diğer bütün bölüm başlıkları aynı kaldı.
- "Profil ekle" düğmesi küçüldü ve yazının önüne "+" geldi: **"+ Profil ekle"**.
  - Görünen yükseklik **34 pt** (önce 46 pt).
  - Yazı **14 pt kalın**, "+" yaklaşık **17 pt**, aralarında 4 pt.
  - Yanlarda **12 pt** iç boşluk, köşe yarıçapı **9 pt**, renk yine amber.
  - Genişlik yine yalnız içerik kadar ve en fazla satırın yarısı.
  - Dokunma alanı **en az 44 pt** kaldı (görünmeyen dolgu; ölçülen 48 pt).
  - VoiceOver yine yalnız **"Profil ekle"** okur; "+" okunmaz.
- Başlık ve düğme aynı satırda, dikeyde ortalı.

## Nasıl
- `lib/features/profiles/profiles_screen.dart` (`profiles-list-header`):
  başlığa `size: 20`, düğmeye `compact: true` ve `leadingGlyph: '+'` verildi.
- `lib/ui/menzil_widgets.dart` → `MenzilPrimaryButton`'a iki isteğe bağlı
  parametre eklendi: `compact` (34 pt, 14 pt kalın, 12 pt yan boşluk, 9 pt köşe,
  `MaterialTapTargetSize.padded`) ve `leadingGlyph` (`ExcludeSemantics` içinde
  17 pt işaret). Varsayılanlar kapalı; başka hiçbir düğme değişmedi.
- Büyük yazı boyutunda "+" ve yazı birlikte küçülür (mevcut `oneLine`
  davranışı), düğme 34 pt'yi aşmaz, satırdan taşmaz.

## Neden
Sahip, listenin başlık satırının daha sade ve küçük görünmesini istedi
(onaylı çizim). Dokunma alanı Apple'ın 44 pt kuralı için küçültülmedi.

## Kenar durumları
- 320 pt genişlik ve yazı ölçeği 1.0 / 1.25 / 1.3 / 2.0 / 3.0: taşma yok, yazı
  tek satır, düğme satırın yarısını geçmiyor (testte ölçülüyor).
- Görünen düğmenin üstüne/altına (dokunma dolgusuna) basınca da profil
  oluşturma açılıyor.
- Önceki ilk başlık boyutu 24 değil 22 pt idi; görevde istenen hedef 20 pt
  olduğu için 22 → 20 yapıldı (yani 4 değil 2 pt küçüldü).

## Yapılmayanlar
- `MenzilSectionHeader` ve `MenzilPrimaryButton` genel görünümü değişmedi.
- Kartlar, alttaki boşluklar, diğer sayfalar, üst çubuk değişmedi; üst çubuk
  logo işi (`feat/ust-cubuk-logo`) bu dala dokunmadı.

## Testler
- Yeni: `test/profil_ekle_kucuk_test.dart` — başlık 20 pt (varsayılan 22 kaldı),
  görünen yükseklik 34, dokunma ≥ 44, amber, 14 pt kalın, 12 pt yan, 9 pt köşe,
  "+" yazıdan önce ve 17 pt, Semantics "Profil ekle" ("+" yok), aynı satırda
  ortalı, dolguya basınca açılıyor, 320/390 pt × 1.0–3.0 taşma yok.
- Bilerek güncellenen beklenti: `test/duzeltmeler_16_10_test.dart` grup 1
  (önce 16 pt yan boşluk ve 46 pt yükseklik bekliyordu; artık 12 pt ve 34 pt,
  dokunma alanı 44–48 pt). "İçerik kadar geniş, yazı tam boyda, sağda aynı
  yerde" kontrolleri aynen duruyor.
- Yerel: `python3 tools/offline_dart_lint.py` PASS (434 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` OK (915 test,
  1 atlanan).
- Yerel Flutter doğrulaması **BLOCKED**: bu bulut ortamında
  `storage.googleapis.com` vekil sunucuda 403 ile engelli, Flutter 3.47.2
  (Dart SDK) indirilemedi. `flutter analyze/test` sonuçları yalnız CI'dan.

## CI ve ekran görüntüleri
PR açıklamasında güncel bağlantılar var.
