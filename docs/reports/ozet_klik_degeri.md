# Profil özeti: Dürbün kartına Klik değeri

Sahip kararı (17.10.2026 18:17–18:18, İstanbul): Dürbün özet kartında Klik değeri eksik; "ekle". Tüp istenmedi.

## Ne
Profil sayfasındaki Dürbün kartına (`profile-summary-scope`) **Klik değeri** eklendi. Kartın son metriği; Dürbün üst kule'nin ardından, aynı iki sütunlu düzende. Örnek: "0,1 MRAD", "1/4 MOA", "0,05 MRAD".

## Nasıl
- `lib/features/profiles/profile_summary.dart`:
  - `_profileClick`: hesabın kullandığı klik. Dürbünün birimi profilin birimiyle aynıysa katalogdaki klik, değilse 0,1 MRAD / 1/4 MOA / 1/4 SMOA. Hedef'teki `_scopeClickValue` ile aynı kural.
  - `_topTurretClicks` artık aynı yardımcıyı kullanıyor. Gerçek verilerde sonucu değişmedi.
  - `_clickSummary`: Profil editöründeki Klik değeri listesinin etiketleri aynen kullanılıyor (`_ProfileDialogState._clickOptions`): "0,1 MRAD", "0,05 MRAD", "1/4 MOA", "1/8 MOA", "1/2 MOA" ve aynıları SMOA ile.
  - Listede olmayan katalog klikleri virgüllü sayı + birim olarak yazılıyor: 0,2 MRAD, 0,1 MOA, 1 MOA, 0,3333 MOA.
- Başka kart, etiket, sıra ya da değer değişmedi. Hesap değişmedi; özet yalnız gösteriyor.

## Neden
Kartta kule klik sayısı vardı ama klik büyüklüğü yoktu. Sahip ekletti.

## Uç durumlar
- Profilin birimi dürbününkinden farklıysa (ör. MOA profil, MRAD dürbün), Hedef'in kullandığı standart klik gösteriliyor: "1/4 MOA".
- Dürbün bulunamazsa ya da klik değeri yoksa kutu gösterilmiyor. Kartın mevcut kuralı bu: Retikül ve Dürbün üst kule de değeri yokken gösterilmiyor; "—" kullanılmadı. Elle girilen dürbün klik değeri olmadan kaydedilemediği için bu durum pratikte yalnız dürbün bulunamadığında olur.
- Önceden olan durum: özet dürbünü doğrudan katalogdan okur. Tutarsız bir profilde Hedef sayfası kilitlenir ama özet yine dürbünü (artık Klik değeri ile birlikte) gösterir. Bu iş bunu değiştirmedi.
- Ateşli silah ve PCP, katalog ve elle girilen dürbün aynı yoldan geçiyor.

## Testler
- Yeni `test/ozet_klik_degeri_test.dart`. Gerçek Profil sayfası (HomeScreen) ve Hedef (BallisticsScreen) kullanılıyor:
  - PCP, katalog MRAD 0,1 dürbün → "0,1 MRAD"
  - Ateşli silah, katalog MOA 1/4 dürbün (Arken EP-5) → "1/4 MOA"
  - PCP, elle girilen 0,05 MRAD dürbün → "0,05 MRAD"
  - MOA profil, MRAD katalog dürbün → "1/4 MOA"
  - Her durumda Klik değeri kartın son metriği: Dürbün üst kule'den sonra geliyor, kartta ondan sonra metin yok.
  - Gösterilen değer, Hedef'teki `ScopeDialView.clickValue` ile aynı.
  - 320 pt ve yazı ölçeği 1.3'te taşma yok.
- `test/profile_summary_order_test.dart` dar kapsamlı güncellendi:
  - Sıra listesine Dürbün üst kule'den sonra 'Klik değeri' eklendi.
  - "Klik değeri yok" beklentisi kaldırıldı, çünkü sahip 17.10'da istedi.
  - Yerine "0,1 MRAD" görünür kontrolü eklendi.
  - Zayıflatılan test yok.
- Yerel:
  - `python3 tools/offline_dart_lint.py` geçti (0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (915 test, 1 atlandı).
  - Bu ortamda Flutter SDK indirilemedi (indirme ağ kuralıyla engellendi), bu yüzden Flutter testleri yalnız CI'da çalıştı.

## Ekran görüntüsü
iPhone 16e (390 pt), iOS 26.2 Simülatör; `fix/ozet-klik-degeri` dalının `9c5d050` kodu. Sim-screens çalışması: https://github.com/sniperTurk/flutter-app/actions/runs/39047392556 (flutter test çıkış kodu 0).

Profil sayfası, ateşli silah profili, katalog dürbün Gazi Sniper 6-36 (0,1 MRAD). Dürbün kartının satırları: Dürbün ayağı | Dürbün üst kule, sonra Klik değeri "0,1 MRAD" sol sütunda, son metrik olarak. Kart dışına taşma yok.

![Profil Dürbün kartı, Klik değeri](https://raw.githubusercontent.com/sniperTurk/flutter-app/fix/ozet-klik-degeri/docs/reports/ozet_klik_degeri/profil_390_durbun_klik.png)

Görüntü dalda da duruyor: `docs/reports/ozet_klik_degeri/profil_390_durbun_klik.png`.

## CI
Kod commit'i `9c5d050` üzerinde:
- iOS CI, hepsi başarılı: `verify`, `dart-checks`, `wind-acceptance` (https://github.com/sniperTurk/flutter-app/actions/runs/39046073616). `ios-simulator` işi bu akışta atlanıyor (skipped).
- Tüm testler (`files=test`) başarılı: https://github.com/sniperTurk/flutter-app/actions/runs/39046231136
- Analiz (`--fatal-infos --fatal-warnings`) başarılı: https://github.com/sniperTurk/flutter-app/actions/runs/39046232805
- Dart format düzeltme akışı başarılı, değişiklik gerekmedi: https://github.com/sniperTurk/flutter-app/actions/runs/39046234217
- İlk commit `16f038a` üzerindeki tam test çalışması kırmızıydı: https://github.com/sniperTurk/flutter-app/actions/runs/39044953586
  - Neden: yeni testte kişisel kayıtlar ManualCatalogStore'a yazılmamıştı. Profil sayfası kayıtları bu depodan yeniden yüklediği için elle girilen dürbün ve ateşli tüfek düşüyordu.
  - Düzeltme yalnız testteydi (`9c5d050`). Uygulama kodu değişmedi.
- Bu rapor commit'i yalnız docs/ dosyası içeriyor. iOS CI docs/ değişikliklerini atladığı için bu commit için iOS CI elle yeniden çalıştırıldı; sonucu PR'ın Checks sekmesinde.
- Code Review ve Security review PR yorumunda: https://github.com/sniperTurk/flutter-app/pull/391#issuecomment-6235821679

Taslak PR'dır; birleştirme ve TestFlight yapılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01TK5MHDCzrqJzAD6cey1riy
