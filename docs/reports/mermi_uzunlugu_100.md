# Profil Mermi uzunluğu üst sınırı 60 → 100 mm (D17D-1)

Sahip, 2026-10-17 17:42 (İstanbul): "çıkart". Denetim PR #386, bulgu D17D-1 (ORTA).

## Ne
Profil → Mühimmat → Mermi uzunluğu artık 1–100 mm kabul ediyor (önce 1–60 mm). Hesap (`_bulletLengthMm`) zaten 0–100 mm kabul ediyordu; eski Pro kutusu da 100 mm'ye kadar alıyordu. Artık .50 BMG gibi uzun mermiler profile kaydedilebilir.

## Nasıl
`lib/features/profiles/profile_editor.dart` `_lengthError`: `_rangeError(ammoLength, 1, 60)` → `_rangeError(ammoLength, 1, 100)`. Tek satır. Alt sınır (1 mm) aynı.

## Neden
Profil kutusu hesaptan dar olduğu için 60 mm üstü mermi kaydedilemiyordu.

## Uç durumlar
- 100,1 ve 999: Kaydet/Güncelle kapalı, kutunun altında bugünkü biçimde hata: "1–100 arasında bir değer girin." (eskiden "1–60 …").
- 0 ve 0,5: yine reddedilir (alt sınır değişmedi).
- Boş: yine isteğe bağlı, uzunluksuz kaydedilir.
- 31,2 gibi eski değerler aynen kaydedilir ve aynı sayıyı verir; kayıtlı veri değişmez.

## Bilerek yapılmayan
ⓘ metni, etiket, düzen, hesap ve başka hiçbir sınır değişmedi. Görsel değişiklik yok, bu yüzden ekran görüntüsü konmadı (yalnız hata metnindeki sayı 60 → 100).

## Testler
- `test/audit_2026_10_17d/mermi_uzunlugu_denetim_test.dart` "D17D-1": `skip` kaldırıldı. Not: denetimdeki gövde yalnız `fail('D17D-1 açık')` idi (kendi yorumu: "düzeltildiğinde editör üzerinden 62 mm kaydı doğrulamalı"); bu yüzden gövde "değişmeden" geçemezdi. Yorumun dediği gibi gövde yazıldı: editörde 62 mm girilir, Güncelle açık, kayıtta `lengthMm` 62; hesapta 62 mm eski Pro 62 ile aynı sayıyı verir, 31,5'ten farklıdır. Dosyanın geri kalanı PR #386'daki ile aynı (D17D-2 hâlâ `skip`). PR #386 henüz main'de olmadığı için dosya bu dala da eklendi; hangisi sonra birleşirse bu dosyada küçük bir çakışma çıkabilir, bu dalın sürümü esas alınmalı.
- `test/mermi_uzunlugu_profil_test.dart`:
  - Eski "1–60 dışı kaydı engeller" testi (70 → kapalı, 60 → açık) yeni sınıra göre güncellendi ve sıkılaştırıldı: 100,1 / 999 / 0,5 / 0 → kapalı ve hata metni görünür; 1 / 31,2 / 60 / 62 / 70 / 100 → açık, hata yok. 70'in artık kabul edilmesi istenen davranış değişikliğidir.
  - Yeni: 62, 100 ve 31,2 mm editörde kaydedilir (`lengthMm` 62 / 100 / 31,2).
  - Yeni: Profil 62 ve 100 mm stabilite/spin drift hesabında kullanılır (31'den ve birbirinden farklı sonuç; eski Pro'daki aynı değerle aynı sayı).
- Hiçbir test zayıflatılmadı veya silinmedi.
- Yerel: `python3 tools/offline_dart_lint.py` PASS (434 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` 915 test OK (1 skip, önceden de vardı). Flutter SDK bu ortamda kurulamadı (Dart SDK indirmesi proxy'de 403), Flutter testleri yalnız CI'da çalıştı.

## CI linkleri
PR yorumlarında güncellenir.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
