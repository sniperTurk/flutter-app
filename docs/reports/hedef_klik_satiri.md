# Hedef klik satırı: Üst kule sağa yaslandı, sol çizgi kaldırıldı

Sahibin isteği (2026-10-17 11:51–11:52 İstanbul, TestFlight 112 ekran görüntüsü): "Üst kule klik sayısını sağ çizgiye yasla. Solda bulunan çizgiyi kaldır." Çizim gösterildi, "yap" dedi.

## Ne
- Hedef sayfasında mesafe çubuğunun altındaki klik satırında "Üst kule … klik" yazısının solundaki **turuncu/sarı çizgi silindi**.
- "Üst kule … klik" yazısı kendi yarısında **sağa yaslandı**; mavi çizgiden **5 pt** önce bitiyor. Bu, mavi çizgi ile "Yan kule" yazısı arasındaki görünen boşlukla aynı (5 pt). Mavi çizgi artık iki yazının arasında ayraç.
- Yan kule yarısı hiç değişmedi: yeri, eni, mavi çizgi (3 pt), yazılar, sayılar, yönler, renkler, satır yüksekliği (22 pt) aynı. Sayılar main ile aynı (hesap değişmedi).

## Nasıl
- Yalnız `lib/features/ballistics/scope_results.dart` içindeki `TurretSolutionRow` değişti.
- Üst kule yarısında çizgi kutusu yok; yazı yarının sağına hizalı. İki yarı arasındaki 12 pt boşluk aynen kaldı (Yan kule kaymasın diye); Üst kule yazısı bu boşluğun içine 7 pt kaydırılarak çizildi, böylece mavi çizgiye 5 pt kalıyor (`TurretSolutionRow.dividerGap = 5`).

## Neden
Sahip, üst kule sayısının mavi çizgiye yaslanmasını ve soldaki çizginin kalkmasını istedi.

## Uç durumlar
- Uzun değerler ("Üst kule 1234 klik yukarı", "Yan kule 987 klik sol"), 320 pt ekran, yazı ölçeği 1.3: satır taşmıyor, tek satır kalıyor, yazı bugünkü gibi küçülerek sığıyor; hiçbir rakam kesilmiyor. Küçüldüğünde de sağa yaslı ve mavi çizgiye 5 pt.
- VoiceOver cümleleri aynı ("Üst kule N klik, … MOA yukarı"). VoiceOver'ın çerçevesi Üst kule yarısının yerinde (yazı 7 pt sağda çizildiği için çerçeve yazıdan biraz solda); okunan metin değişmedi.
- Başka sayfaya, Pro'ya, Profil'e dokunulmadı.

## Testler
- `test/hedef_klik_satiri_test.dart` (yeni, gerçek Hedef sayfası): satırda turuncu çizgi yok, yalnız mavi çizgi var; Üst kule yazısının sağ kenarı mavi çizgiden 5 pt (±0,5) önce; mavi çizgi → "Yan kule" boşluğu 5 pt (main ile aynı); Yan kule yarısının yeri ve eni main ile aynı; Yan kule yazı stilleri aynı; sayılar dürbün görünümünün gereken çözümüyle aynı; 390 pt, 320 pt ×1.0 ve ×1.3'te taşma yok; 320 pt ×1.3'te "1234 klik yukarı" uzun değeri tam ve taşmasız.
- `test/hedef_sonuc_ustte_test.dart`: eski "Üst kule turuncu çizgi" beklentisi dar şekilde "Üst kule'de çizgi yok" yapıldı; Yan kule cyan çizgi beklentisi aynen kaldı. Başka test zayıflatılmadı.
- İlk CI turunda yeni testler mavi çizgi → "Yan kule" boşluğunu 5 pt ölçtü (8 pt dolgu, 3 pt çizginin altından başlıyor); Üst kule boşluğu buna göre 8 pt'den 5 pt'ye alındı.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (419 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (915 test, 1 atlandı). Bu ortamda Flutter SDK indirilemedi (ağ engeli, 403), `flutter test` yerelde çalışmadı; testler CI'da çalıştı.

## Ekran görüntüsü (önce / sonra, 390 pt)
PR açıklamasında.

## CI
PR açıklamasında.
