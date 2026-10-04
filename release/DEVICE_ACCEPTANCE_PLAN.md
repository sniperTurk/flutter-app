# Fiziksel iPhone kabul planı (V368)

Her satır cihazda yapılır; sonuç PASS/FAIL + cihaz modeli + iOS sürümü + tarih yazılır. Cihazda yapılmamış satır "doğrulandı" sayılmaz.
Hazırlık: TestFlight/Xcode ile Release derlemesi (`METNO_CONTACT` verilmiş), temiz kurulum, Türkçe sistem dili, 390 pt genişlikli cihaz (iPhone 13/14/15/16 standart).

## A. Temiz kurulum ve profil (veri bütünlüğü)
| # | Adım | PASS | FAIL |
|---|---|---|---|
| A1 | Uygulamayı sil, kur, aç | Ana ekran açılır, çökme yok, profil yok mesajı | Çökme/boş ekran |
| A2 | Profil oluştur (PCP, katalog tüfek/mühimmat/dürbün, 60 mm), kaydet, uygulamayı kapat-aç | Aynı profil, aynı değerler | Değer/donanım değişmiş |
| A3 | Profili düzenle, yalnız adı değiştir, Güncelle | Tüfek/mühimmat/dürbün aynı kalır | Herhangi biri değişir |
| A4 | Aktif profil seç, uygulamayı öldür, aç | Aynı profil aktif | Başka profil aktif |
| A5 | Profil silme (kaydır + butonla) onay ister, iptalde silmez | Onay çıkar | Onaysız silinir |

## B. Pusula (kuzey referansı)
| B1 | Konum izni VERİLMİŞ, açık alanda, bilinen kuzey (harita uygulaması/jeodezik nokta) ile karşılaştır | Değer ±5° içinde VE ekran gerçek/manyetik kuzey iddia etmez (V368 nötr metin) | Sapma >5° veya sürekli geçersiz mesajı → bulguyu kaydet (flutter_compass iOS trueHeading konum güncellemesi ister) |
| B2 | Konum izni REDDEDİLMİŞ | Fail-closed "geçersiz/referans yok" metni; sayı gösterilmez | Yanlış yön sayısı gösterilir |
| B3 | Demir/mıknatıs yaklaştır | Değer bozulur; kalibrasyon uyarısı varsa görünür | Sabit "kesin" değer |
| B4 | Uygulama arka plan→ön plan | Pusula yeniden akar | Donar |

KARAR NOTU: B1 geçersiz çıkarsa pusula release'e alınmaz veya "Konum ayarlarını kontrol edin" yönlendirmesiyle sınırlanır (sahip kararı).

## C. Su Terazisi (X/Y işaret ve referanslama)
| C1 | Düz zemin, yüzü yukarı | X≈0, Y≈0 (±0,3°); baloncuk merkezde | Sabit sapma >0,5° (kalibrasyon sorunu) |
| C2 | Sağ kenarı kaldır | X pozitif, baloncuk yüksek (sağ) tarafa gider | İşaret ters |
| C3 | Üst kenarı kaldır | Y pozitif, baloncuk yukarı gider | İşaret ters |
| C4 | Referansla (sıfırla) düz zeminde, sonra aynı kenarı 2° kaldır | ~2,0° (dijital eğimölçerle ±0,3°) | >0,5° fark |
| C5 | Sıfırla/Referans temizle | Ham değerlere döner | Referans kalır |
| C6 | Cihazı yatay çevir | Ekran dikey kilitli kalır, değer sıçramaz | Dönüp bozulur |
| C7 | Başka ekrana geç / geri dön | Sensör akışı yeniden başlar, sızıntı yok | Donma |
"0,01°" doğruluk iddiası YOKTUR; yalnız gösterim çözünürlüğü.

## D. Sight Height
| D1 | Kamera izni ilk istek: Reddet | Açık hata + Ayarlar yönlendirmesi, çökme yok | Çökme/sonsuz dönen |
| D2 | İzin ver, kameradan çek (dikey) | Önizleme doğru oran (uzamış/ezik değil) | Bozuk oran |
| D3 | Yatay (landscape) ve kısa yatay çekim sayfası, 3 işaret | Tüm kontroller erişilebilir, taşma yok | Kırpılan/ulaşılamayan buton |
| D4 | Fiziksel formülle hesap: bore 3,18 + üst duvar 5,80 + ön boşluk 21,40 + 32,00 mm objektif | ≈62,4 mm | Fark >0,05 |
| D5 | Fotoğraf yöntemi: bilinen (cetvelle ölçülmüş) yükseklik | Sonuç ölçüme ±1,5 mm | Fark >1,5 mm → raporla |
| D6 | Galeriden seç: normal, EXIF dönük (iPhone dikey), HEIC, çok büyük foto | Doğru yönde açılır, ölçek korunur, kitaplık izni istemez (PHPicker) | Yan yatık/yanlış ölçek |
| D7 | Geometri imkânsız (3 nokta aynı yerde, objektif yarıçapından küçük yükseklik) | Sonuç reddedilir, açıklama | Sayı üretir |
| D8 | Çekim sırasında ana ekrana çık / telefon çağrısı | Kamera oturumu kapanır, geri dönüşte kurtarır | Yeşil kamera göstergesi kalır |
| D9 | Nudge/Reset/Hesapla; sonucu profile aktar | Değer 0–300 mm, profilde doğru | Aktarım yanlış |
| D10 | Eski/yavaş cihaz (varsa) | Önizleme akıcı, bellek uyarısı yok | Çökme/donma → `ResolutionPreset` değerlendir |

## E. Hava & Rüzgâr
| E1 | Konum izni ver, internet açık | Veri gelir, "güncel" etiketi, kaynak MET Norway | Boş/Çökme |
| E2 | Uçak modu | Hata + son veri "eski" uyarısı, sayı güncelmiş gibi görünmez | Eski veri güncel gösterilir |
| E3 | 10+ dk bekle / arka plana at, 15 dk sonra dön | Yeniden güncelleme veya "eski" uyarısı | Eski veri sessizce |
| E4 | Konum reddedilmiş | Açık metin, manuel yol varsa çalışır | Çökme |
| E5 | Ağ proxy (Charles) ile User-Agent kontrol | `SniperTurk/1.0 <gerçek iletişim>`; `CONTACT_REQUIRED` YOK | Placeholder'lı |
| E6 | Rüzgâr yönü VoiceOver | "Kuzeybatı" gibi okunur, ok sembolü okunmaz | Sembol okunur |

## F. Ekran/erişilebilirlik
| F1 | 390 pt: tüm sekmeler (Atış, Tablo, Ortam, Profil, Araçlar) | Taşma/kırpılma yok | Taşma |
| F2 | VoiceOver açık: her sekme, profil satırı, dropdownlar, düğmeler | Anlamlı etiketler, mantıklı sıra | Etiketsiz/çift okuma |
| F3 | En büyük Dinamik Tür | Okunur, kayma yok | Kırpılma |
| F4 | Karanlık/açık mod | Kontrast okunur | Okunmaz |

## G. İzin akışları ve gizlilik
| G1 | Konum/Kamera/Hareket metinleri Ayarlar'da doğru ve Türkçe | Metin Info.plist ile aynı | Farklı |
| G2 | Tüm izinleri reddet | Her araç açıklayıcı fail-closed, ana hesaplama çalışır | Çökme |
| G3 | Ayarlar'dan izni sonradan ver, geri dön | Araç devam eder | Takılı kalır |

## H. Güvenlik kapısı
| H1 | Atış/Tablo | KİLİTLİ (G1/G7 kapısı kapalı); MRAD/MOA/klik/rüzgâr düzeltmesi yok | Düzeltme değeri görünür |
