# V372 — eksik araç yaşam döngüsü testleri (release checklist B3)

Kaynak: `main` @ `4cd5faf` (PR #5). Üretim kodu değişmedi; solver,
`validation/acceptance.json`, katalog ve üretim kapısı dokunulmadı.

## Testler
- Yeni: `test/tools_lifecycle_test.dart`
  - Hava & Rüzgâr: "Güncel" rozeti 30 dk sonra yeniden çekme olmadan "Bayat
    veri"ye döner; uygulama ön plana dönünce yaş hemen yeniden hesaplanır;
    ekran kapanınca zamanlayıcı/gözlemci bırakılır.
  - Kamera: beklenmeyen eklenti hatası mesaj gösterir (çökmez); sayfa
    kapanınca oturum kapatılır; açılış bitmeden kapanırsa da kapatılır.
  - Ekran yönü: Su Terazisi ve Pusula dikey kilitler, kapanınca serbest
    bırakır; yan fotoğraf yatay kilitler, geri dönünce serbest bırakır.
  - Su Terazisi: referans ayarla/temizle, duruş değişince referansın
    silinmesi (kalibrasyon korunur), okuma yokken referans alınmaması,
    kilit.
- Değişen: `test/support/tool_fakes.dart` — `TestCamera` açılış/kapanış
  sayaçları, `hold` ve genel `error` desteği (mevcut kullanım uyumlu).

## Belgeler
- `release/RELEASE_CHECKLIST.md`: B3 güncellendi; G1/G7 satırına PR #5 notu.

## ÇALIŞTIRILMADI / DOĞRULANMADI
- Bu sandbox'ta Flutter SDK yok. `dart format`/`analyze`/`flutter test`
  sonucu yalnızca PR'ın kendi iOS CI koşusundan okunmalıdır.
- Offline: `tools/offline_dart_lint.py` geçti; Python paketi 591/591 geçti.
