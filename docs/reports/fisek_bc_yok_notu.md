# BC'siz fabrika fişeği: BC ⓘ notu

Sahip kararı (14.10.2026, İstanbul): 15:16 "Boş bırakmak: kullanıcı bu fişeği
seçerse BC'yi kendisi girer." 15:18 "Ekle, iyi olur."

## Ne değişti
Profil > Mühimmat'ta listeden seçilen bir fabrika fişeğinin üreticisi BC
yayımlamıyorsa (kütüphanede `bc == null`), BC kutusunun ⓘ açıklamasının sonuna
şu metin eklenir:

> Bu fişek: Üretici BC yayımlamıyor. Kendi atışlarınızdan bulduğunuz BC'yi
> girin; BC modelini de seçin.

Tek dosyada küçük bir değişiklik: `lib/features/profiles/profiles_screen.dart`,
`_factoryBcNote` (BC ⓘ ek metni). Yeni arayüz öğesi yok, alan altında yardım
metni yok. BC kutusu eskisi gibi boş gelir ve zorunludur; BC girilmeden profil
kaydedilmez.

## Nasıl
`_factoryBcNote` zaten seçili fabrika fişeğini (Marka + Model) kütüphanede
bulup NATO metnini ve üretici notunu ekliyordu. Aynı döngüye bir koşul eklendi:
platform Ateşli Tüfek, mühimmat türü Fabrika fişeği ve fişeğin BC'si yoksa yeni
cümle eklenir. Sıra: NATO metni, sonra üretici notu, en sonda bu cümle.

## Sınır durumları
- Hem notu hem BC'si olmayan fişek: önce not, sonra yeni cümle. (Şu an
  kütüphanede böyle bir fişek yok; kod yine de bu sırayı uygular.)
- BC'si olan fişek: ⓘ eskisi gibi; yeni cümle çıkmaz.
- Kullanıcı BC'yi elle girince de cümle ⓘ'de kalır (fişek hâlâ BC'siz listeli
  fişektir).
- El dolumu / PCP: değişmedi. BC'siz listeli mermi/saçma için eski "Bu mermi:
  Üretici BC yayımlamıyor…" cümlesi aynen duruyor.
- Elle girilen ("listede yok mu?") fişek: kütüphane eşleşmesi olmadığı için
  cümle çıkmaz.
- Main'deki #296 ile 30 fişeğe BC geldi; bugün kütüphanede BC'siz fabrika
  fişeği sayısı 53 (52 değil, hepsine bu cümle uygulanır).

## Yapılmayanlar
- BC modeli ⓘ'sine dokunulmadı (fix/bc-modeli-secim görevi o metni düzenliyor).
- BC kutusunun zorunluluğu, varsayılanlar, kütüphane verisi değişmedi.

## Testler
Yeni dosya `test/fisek_bc_yok_notu_test.dart`:
- Black Hills 52 gr Match HP (.223 Rem, BC yok) seçilince BC boş, ⓘ =
  Ateşli BC metni + yeni cümle; alan altında metin yok.
- Black Hills 50 gr Hornady V-MAX (BC var) seçilince ⓘ = eski metin + üretici
  notu; yeni cümle yok.
- BC'siz fişekte "Kaydetmek için eksik" listesinde BC var, Kaydet kapalı; BC
  girilince BC listeden çıkıyor, ⓘ cümlesi kalıyor.
- Kayıtlı PCP profili, BC'siz listeli saçma (Spoton Match): ⓘ'de eski "Bu
  mermi" cümlesi aynen, "Bu fişek:" yok.

Yerel: `python3 tools/offline_dart_lint.py` GEÇTİ (334 dosya, 0 sorun);
`python3 -m unittest discover -s tools -p 'test_*.py'` GEÇTİ (740 test).
Bu ortamda Flutter SDK yok; widget testleri yalnızca CI'da çalıştı.

## CI
- Format (format-fix, 0 dosya değişti, commit yok): BAŞARILI —
  https://github.com/sniperTurk/flutter-app/actions/runs/38563293378
- Testler (test-diag, files=test): BAŞARILI (commit de0ea5c, `flutter test test` çıkış kodu 0; günlükteki "error" satırları tanı betiğinin grep çıktısı, test hatası değil) —
  https://github.com/sniperTurk/flutter-app/actions/runs/38563658361
- Analyze (analyze-diag): BAŞARILI —
  https://github.com/sniperTurk/flutter-app/actions/runs/38563661618
- iOS CI / Simulator / TestFlight: çalıştırılmadı.

Birleştirme ve TestFlight yapılmadı; PR taslak.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01NQG18pm8QnBrT63ErdsV3k
