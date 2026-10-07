# V376 — Atış açılınca profil otomatik hesaplanır (dürbün hemen çalışır)

Kaynak: `main` @ `d63559c`. Solver, katalog, `validation/*` ve üretim kapısı
değişmedi.

## Sorun
Atış görünümü açıldığında çözüm yoktu ("Vuruş noktası: hesaplama
bekleniyor"); kuleler dönse de retikülde vuruş noktası ve kırmızı mesafe
sayıları çıkmıyordu. Kullanıcı önce "Hesapla"ya basması gerektiğini bilmiyordu.

## Üretim kodu (`lib/features/ballistics/ballistics_screen.dart`)
- Çalışma alanı açılınca (ilk kare çizildikten sonra) aktif profil otomatik
  çözülür. Bu ilk çözümün hataları sessizdir; Atış
  görünümündeki not nedenini söyler.
- Atış görünümünde "Hesapla" her zaman görünür (Hava Durumu değişince yeniden
  hesaplamak için); çözüm yoksa vurgulu.
- BC notu son çözüme değil girilen grain'e bakar (açılışta çözüm hazır
  olduğundan, grain değişince not hemen güncellenir).

## Testler
- `test/scope_dial_view_test.dart`: Atış açılınca, Hesapla'ya basmadan vuruş
  noktası hesaplanmış olarak görünür.
- `test/menzil_shell_test.dart`: çözülmüş Atış'ta "hesaplayın" notu yok
  (Hesapla düğmesi artık hep görünür).
