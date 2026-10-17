# Pro Ayarlar: "Yönü" → "Hedefin yönü"

PR: https://github.com/sniperTurk/flutter-app/pull/381 (sahip tarafından 17.10.2026 12:57'de birleştirildi)

## Ne
Pro Ayarlar → Hareketli hedef bölümündeki yön kutusunun adı "Yönü" idi, artık "Hedefin yönü".
Başlıktaki ⓘ sayfasında, Kutular listesinde de bu kutunun adı "Hedefin yönü" oldu.

## Nasıl
- `lib/features/ballistics/pro_ayarlar_view.dart`: iki metin değişti.
  - Kutunun etiketi (`pro-target-direction-…`).
  - Başlık ⓘ listesindeki `ProInfoField` adı.
- `test/pro_info_popup_test.dart`: bu kutunun beklenen adı "Hedefin yönü" yapıldı. Başka satırı değişmedi.
- Seçenekler aynı kaldı: Seçiniz / Soldan sağa / Sağdan sola.
- Açıklama metni, anahtar, kayıtlı değer ve hesap aynı kaldı.

## Neden
Sahip (17.10.2026 11:47–11:48, TestFlight 112) "Yönü" kutusunu tüfeğin yiv yönü sandı ve şöyle dedi: "onun adını hedefin yönü yap".

## Testler
- Yeni test `test/hedefin_yonu_test.dart`, gerçek Pro sayfasını Hareketli hedef açıkken ölçer:
  - Yalnız "Hedefin yönü" görünür, tek başına "Yönü" hiçbir yerde görünmez.
  - Etiket tek satırdır ve "…" ile kesilmez.
  - Seçenekler değişmedi.
- 390 pt'de kutu Hedef hızı ile aynı satırdadır. Kutuların ve etiketlerin üst kenarları ±0,5 pt içinde aynıdır.
- 320 pt'de (yazı ×1,0 ve ×1,3) taşma yoktur.
  - Not: 320 pt'de bütün Pro kutuları zaten tek sütuna geçiyor (`MenzilFieldGrid`, 300 pt kuralı; bu iş değiştirmedi).
  - Bu yüzden orada "Hedefin yönü" kutusu Hedef hızı'nın hemen altında, aynı sol kenarda durur. Test bunu doğrular.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS. `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı).
- Flutter SDK bu ortamda yok. `flutter test` ve `flutter analyze` GitHub Actions'ta çalıştı.

## Ekran görüntüsü (Simülatör, iPhone 16e, 390 pt, iOS 26.2)
Bu görüntüler `integration_test/sim_screens_pro_kutu_test.dart` testinden alındı. Test çıkış kodu 0.

- Hareketli hedef açık: ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/3b6c73c0dd211959299db14364ae19d556978592/latest/01_pro_target_acik.png)
- Başlık ⓘ, Kutular: ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/3b6c73c0dd211959299db14364ae19d556978592/latest/03_pro_target_baslik_bilgi_kutular.png)

Görüntüdeki satır: "Hedef hızı | Hedefin yönü". Etiket tek satırda ve tam görünüyor. ⓘ sayfasında "Hedefin yönü:" yazıyor.

## CI linkleri
Dal `fix/hedefin-yonu` üzerinde çalıştı:

- iOS CI, `b552686`: verify ✅, dart-checks ✅, wind-acceptance ✅. ios-simulator atlandı (varsayılan).
  - https://github.com/sniperTurk/flutter-app/actions/runs/39019928284
- Testler (`test-diag`, tüm `test/`): yeşil, `0638970` üzerinde.
  - https://github.com/sniperTurk/flutter-app/actions/runs/39019893074
  - `b552686` yalnız `dart format` ile yapılan biçim değişikliğiydi.
- Analiz (`analyze-diag`, `--fatal-infos --fatal-warnings`): yeşil.
  - https://github.com/sniperTurk/flutter-app/actions/runs/39019894448
- Format düzeltme (`375209577`): yeşil. Biçim commit'i `b552686`'yı ekledi.
  - https://github.com/sniperTurk/flutter-app/actions/runs/39019895927
- Simülatör ekranları: yeşil.
  - https://github.com/sniperTurk/flutter-app/actions/runs/39025265568
- İlk koşularda yakalanıp düzeltilenler (yalnız yeni testte):
  - Kullanılmayan yardımcı fonksiyon (analiz).
  - 320 pt'de "aynı satır" beklentisi. Orada ızgara tek sütun olduğu için beklenti "hemen altında" diye düzeltildi.
- Code Review ve Security review: sorun bulunmadı (PR yorumu).
- TestFlight ve cihaz bu işte çalıştırılmadı.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Pu11vMxWyQZ8AnujHAdE8g
