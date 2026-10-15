# Tür zorunlu — Profil Oluştur

Sahip kararı (2026-10-15 14:25, İstanbul): "sorunu çöz, bu çok basit bir şey".

## Ne

Profil Oluştur'da (yeni profil) **Tür** kutusu "Seçiniz" iken profil artık
kaydedilemez. Kaydet kapalı kalır ve "Kaydetmek için eksik" listesi
**"Tüfek: Tür, Marka, …"** diye başlar. Tür seçilince "Tür" listeden düşer.

Önceden (#318'den beri) Tür "Seçiniz" iken de kaydetmek mümkündü; profil
sessizce Ateşli Tüfek profili olarak kaydediliyordu.

## Nasıl

- `lib/features/profiles/profile_editor.dart`, eksik alan listesi: Tüfek
  grubunun ilk sırasına `(_platformSet, 'Tür')` eklendi. Diğer zorunlu
  seçim kutuları (Mesafe birimi, Dürbün birimi, Dürbün ayağı, Mühimmat
  türü) ile aynı yol: liste boş değilse Kaydet kapalı.
- Aynı dosyada `_platformSet` açıklaması güncellendi: Tür seçilmeden form
  yine Ateşli Tüfek kutularını gösterebilir, yalnızca kaydetme engellenir.

## Neden

Tür hesaplamayı ve mühimmat listesini belirler. Kullanıcının seçmediği bir
tür sessizce kaydedilmemeli; öteki zorunlu kutular da böyle çalışıyor.

## Uç durumlar

- **Profili Düzenle:** `_platformSet` burada baştan doğru (true); kayıtlı
  tür (PCP veya Ateşli) kutuda dolu gelir, "Tür" eksik listesinde çıkmaz,
  Güncelle çalışır. Testle doğrulandı (PCP ve Ateşli, kaydet → yeniden aç).
- **Ateşli Tüfek seçmek:** Form zaten Ateşli göründüğü için seçim değişiklik
  sayılmaz; girilmiş tüfek/mühimmat bilgisi silinmez. Testte her şey
  doldurulup en son Tür seçildi, profil sorunsuz kaydedildi.
- **PCP Tüfek seçmek:** Eskisi gibi; "Tür" listeden düşer.
- **Kayıtlı veri:** Hiçbir kayıt anahtarı değişmedi; eski profiller aynı
  şekilde yüklenir.

## Bilerek yapılmayan

Başka alan, sayfa, etiket, ⓘ metni veya hesaplama değişmedi. Form, Tür
seçilmeden önce de Ateşli Tüfek kutularını göstermeye devam ediyor (istenen
yalnızca kaydetmeyi engellemekti). TestFlight yok, birleştirme yok.

## Hangi test

- Yeni: `test/tur_zorunlu_test.dart`
  - Yeni profil: Tür "Seçiniz", eksik listesinde ilk "Tür", Kaydet kapalı.
  - Yeni profil: Tür dışında her şey dolu → eksik yalnızca
    "Tüfek: Tür", Kaydet'e basmak hiçbir şey kaydetmez; Ateşli Tüfek
    seçilince "Tür" düşer, Kaydet açılır, kayıtlı tüfek Ateşli.
  - Yeni profil: PCP Tüfek seçince de "Tür" düşer.
  - Mevcut PCP ve mevcut Ateşli profil: Tür dolu, Güncelle çalışır, kaydet →
    yeniden aç sonrası tür aynı.
- Güncellenen: `test/profil_duzen_koruma_test.dart` — Tüfek eksik
  sırası artık "Tür, Marka, Model, (Kalibre)" ile başlıyor; "Tür" adı
  ekrandaki Tür kutusuna bağlandı. Sahibin istediği sıra; test
  zayıflatılmadı, bir ad daha kontrol ediliyor.
- Güncellenen yardımcı: `test/support/rifle_form.dart` — `fillRifleForm`,
  Tür hâlâ "Seçiniz" ise Ateşli Tüfek seçer (Mesafe birimi için
  `fillShotValues` nasıl seçiyorsa öyle). `test/audit_*/` testlerinin hiçbiri
  değiştirilmedi.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (366 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test OK.
  Bu ortamda Flutter SDK kurulamadı (indirme sunucusu engelli), Flutter
  testleri yalnızca CI'da koştu.

## CI bağlantıları

- Format (dart format, commit a5bcb44 alındı):
  https://github.com/sniperTurk/flutter-app/actions/runs/38727961842 — başarılı
- Analyze (diag): https://github.com/sniperTurk/flutter-app/actions/runs/38728050656 — başarılı
- Testler, tüm `test/` (diag): https://github.com/sniperTurk/flutter-app/actions/runs/38728047032 —
  başarılı (flutter test çıkış kodu 0). Kayıtta görünen "KESIK" ve
  truing/scope_mount_cant yığın satırları testlerin tanı çıktısı; aynı
  satırlar main'de de var: https://github.com/sniperTurk/flutter-app/actions/runs/38728839709
- `verify`, `dart-checks`, `wind-acceptance`: PR açıklamasında, son commit
  üzerindeki sonuçlarla.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_011m26KmUjpHdScGyq2godjM
