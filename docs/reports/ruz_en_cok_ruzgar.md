# RUZ-1 / RUZ-2: En çok rüzgâr, rüzgâr değişince boşalıyor

Dal: `fix/ruz-en-cok-ruzgar`. Sahip kararı 2026-10-15 20:47 İstanbul ("düzeltmek için görev aç").
Bulgular: `docs/reports/denetim_testflight_2026_10_14b.md` içindeki RUZ-1 ve RUZ-2 (orta).

## Ne değişti

- "Düzeltme al" düğmesiyle dolan En çok rüzgâr değeri, alındığı rüzgâra bağlı.
- Rüzgâr hızı değişince bu değer boşalıyor ve "Düzeltme alındı" kalkıyor. Düğme yeniden "Düzeltme al" oluyor; kullanıcı tekrar basıyor.
- Rüzgâr hızının değiştiği üç yol:
  - hava verisi alımı yeni bir rüzgâr getirdiğinde (0 m/s dahil, RUZ-1),
  - Rüzgâr hızı kutusuna elle yazıldığında (RUZ-2),
  - Hava Durumu "Sıfırla" ile rüzgâr boşaltıldığında (RUZ-2).
- En çok rüzgâr kutusuna elle yazılan değere hiç dokunulmuyor.

## Nasıl

- `lib/features/ballistics/ballistics_screen.dart`, `_windMaxFollowsWind`:
  - Önce: düğme değeri varsa yeni rüzgâr × 1,5 yazılıyordu; rüzgâr ≤ 0 ise hiçbir şey olmuyordu (RUZ-1'in nedeni).
  - Şimdi: düğme değeri varsa kutu boşaltılıyor, "alındı" durumu ve tarihi siliniyor, ayarlar kaydediliyor. Elle yazılmış değerde hiçbir şey yapmıyor.
- Aynı dosya, `_resetWeather`: rüzgâr dolu iken Sıfırla basılırsa `_windMaxFollowsWind` çağrılıyor.
- `lib/features/ballistics/hava_durumu_view.dart`: Rüzgâr hızı kutusunun `onChanged`'i `_windMaxFollowsWind` çağırıyor.
- Hava alımında çağrı zaten vardı (yalnız rüzgâr metni değiştiyse); yeri değişmedi.
- `_putWindMaxFromWind` (düğmenin kendisi) değişmedi: rüzgâr yoksa ya da ≤ 0 ise düğme yine "Önce Hava Durumu'nda rüzgâr hızını girin." der.

## Neden

- Sahibin kuralı: düğmeyle alınan değer, alındığı rüzgâra bağlı. Rüzgâr değişince eski değer yanlış bir aralık (Hedef "Rüzgâr 0,0–7,5 m/s") ve yanlış bir WEZ belirsizliği veriyordu.

## Uç durumlar

- Hava alımı aynı rüzgârı getirirse (metin değişmezse) düğme değeri kalıyor.
- Kutu boşsa ya da elle yazılmışsa hiçbir yol ona dokunmuyor.
- Uygulama yeniden açılınca kayıtlı "Düzeltme alındı" durumu eskisi gibi geri geliyor; yükleme rüzgârı değiştirmiş sayılmıyor.
- Boşaltma yalnız En çok rüzgâr'ı etkiliyor; Yol ortası ve Hedefte kutuları değişmiyor (bunları yalnız Pro'daki Sıfırla boşaltır).
- Yan klik (dürbün) zaten En çok rüzgâr'dan etkilenmiyordu; değişmedi.

## Bilerek yapılmayan

- Gizli `WIND_OBSERVATION` bayrağındaki "Rüzgâr gözlemi" seçimi de Rüzgâr hızını yazar. Görevde sayılan yerler arasında olmadığı için o yola dokunulmadı; bayrak kapalı (varsayılan) olduğu için kullanıcı bu yolu görmüyor. Açılırsa aynı kural oraya da eklenmeli.
- Başka hiçbir değişiklik yok.

## Testler

- `test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart`:
  - RUZ-1 testi ve iki RUZ-2 testi `skip`'ten çıkarıldı; artık kutunun boş ve düğmenin "Düzeltme al" olmasını da bekliyor.
  - Yeni test: elle yazılan En çok rüzgâr (9), elle yazılan rüzgâr, yeni hava alımı, 0 m/s hava alımı ve Sıfırla'dan sonra 9 olarak kalıyor.
  - "restart" zincir testi yeni kurala göre güncellendi: sonraki hava alımı 8 m/s getirince kutu boşalıyor (eskiden 12,0 bekliyordu).
- `test/hava_sayfasi_test.dart` B testi aynı nedenle güncellendi: yeni rüzgâr kutuyu boşaltıyor; "Düzeltme al"a yeniden basınca 12,0 ve yeni tarih geliyor.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test OK.
- Bu ortamda Flutter SDK yok; Flutter testleri yalnız CI'da çalıştı (aşağıda).

## CI

Hepsi dalın son hâli `baa568e` (main ile birleştirilmiş) üzerinde çalıştı:

- iOS CI `verify`: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38790166223/job/116619087139
- iOS CI `dart-checks`: başarılı (aynı çalıştırma: https://github.com/sniperTurk/flutter-app/actions/runs/38790166223)
- iOS CI `wind-acceptance`: başarılı (aynı çalıştırma)
- iOS CI `ios-simulator`: atlandı (iş akışı bu olayda çalıştırmıyor); Simulator derlemesi yapılmadı.
- Test tanılama (tüm `test/`, `flutter test` çıkış kodu 0): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38791424325
- Analiz tanılama: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38791428707
- Biçim (dart format) iş akışı ilk commit'te test dosyasını biçimledi; bu değişiklik commit'e katıldı: https://github.com/sniperTurk/flutter-app/actions/runs/38781183508

TestFlight çalıştırılmadı. PR taslak; birleştirilmedi.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
