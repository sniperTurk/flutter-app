# Claude ile ürün bulma ve "Claude'a sor" — tasarım (sahip kararı 15.10.2026)

Durum: tasarım. İlk sürümden (v1 TestFlight) sonra yapılacak. Kod, bu belge ve
ardından yazılacak uygulama planı sahip tarafından onaylanınca başlar.

## Sahibin istekleri (sözleri)
- 17:15 "uygulamaya Claude'a soru soran bir özellik eklensin tabii ki"
- 17:15 "tüfek yoksa, mühimmat yoksa, dürbün yoksa kullanıcı Claude'a sorsun; Claude'dan gelen veri uygulamaya otomatik eklensin"
- 17:19 maliyet ve sunucu "sorun değil"; 10–30 saniye "harika bir zaman"
- 17:20 "eğer arada Claude varsa kaydedilebilir" (onay adımı olmadan)
- 17:21 "bu özellik olacak; bu olmasa da en azından Claude'a sor olacak"

## Kapsam
1. **Claude ile bul** (asıl özellik): Profil Oluştur'da Tüfek, Dürbün veya
   Mühimmat listede yoksa kullanıcı ürün adını yazar, Claude üreticinin
   sayfasından değerleri bulur, değerler korumalarla doğrudan profile kaydedilir.
2. **Claude'a sor** (en az bu olacak): uygulamanın kullanımı ve kullanıcının
   kendi hesabı hakkında soru-cevap. Hesabı değiştirmez, kule değeri önermez;
   sayılar her zaman uygulamanın kendi hesabından gelir.

Kapsam dışı: ortak ürün listesine (rifle_library, scope_library,
factory_ammo_library, bullet_library) Claude verisi eklemek; çevrimdışı çalışma
(internet yoksa iki özellik de "bağlantı yok" der, uygulamanın geri kalanı
çevrimdışı çalışmaya devam eder).

## Akış — Claude ile bul
1. "Listede yok" bağlantısının yanında "Claude ile bul" düğmesi.
2. Kullanıcı ürün adını yazar (ör. "Sako 85 Hunter .308").
3. Uygulama yalnız ürün adını ve türünü (tüfek/dürbün/mühimmat) sunucuya yollar.
4. Sunucu Claude'u web arama + sayfa okuma araçlarıyla çağırır; Claude
   yalnız üretici sitelerini ve kataloglarını kullanır.
5. Claude yapılandırılmış yanıt döner: her alan için `değer`, `kaynak_url`,
   `kısa_alıntı`, `okuma_tarihi`.
6. Uygulama korumaları uygular (aşağıda), geçen değerleri profile yazar.
7. Hedef süre 10–30 sn; 60 sn'de zaman aşımı → "bulunamadı".

Alanlar (yalnız hesabın kullandığı alanlar; yeni form alanı eklenmez):
- Tüfek: kalibre, yiv oranı, yiv yönü, (varsa) namlu uzunluğu bilgi amaçlı.
- Dürbün: birim (MOA/MRAD), odak düzlemi, tüp çapı, büyütme, klik değeri,
  üst kule klik sayısı, retikül adı.
- Mühimmat: mermi ağırlığı, BC ve BC modeli (G1/G7), üreticinin verdiği
  namlu çıkış hızı ve ölçüm namlu uzunluğu.

## Korumalar (doğrudan kayıt için zorunlu)
1. **Kaynaksız değer yazılmaz.** Her değerin üretici alan adından bir
   `kaynak_url`'si olmalı; yoksa alan boş kalır, tahmin yazılmaz.
2. **Kaynak türü:** forum, blog, bayi değerleri ve başka balistik
   uygulamalar (ChairGun, Strelok, Applied Ballistics, QuickLOAD, GRT, JBM)
   reddedilir (alan adı engel listesi + Claude yönergesi). robots.txt'ye uyulur.
3. **Aralık kontrolü:** her alan için makul sınırlar (ör. BC 0,05–1,2;
   hız kalibreye göre; yiv oranı 1:5–1:20). Dışındaki değer yazılmaz.
4. **İz:** kaydedilen her değerin yanında "Claude ile eklendi" işareti ve
   kaynak bağlantısı; kullanıcı istediğinde düzeltebilir. Kayıt verisine
   `source: claude`, `source_url`, `fetched_at` alanları eklenir (eski
   kayıtlar aynen açılır).
5. **Yalnız kullanıcının profili:** ortak listeye yazılmaz.

## Mimari
- **Uygulama (Flutter):** `lib/features/claude/` altında iki modül:
  `claude_lookup` (istek, yanıt doğrulama, profile yazma) ve `claude_ask`
  (soru-cevap ekranı). Doğrulama ve aralık kontrolü saf Dart, `lib/core/`
  altında, birim testli.
- **Sunucu (sahibin hesabı):** küçük bir ara katman (ör. bulut fonksiyonu).
  Anthropic API anahtarı yalnız burada durur, uygulamaya konmaz. Görevleri:
  istek sınırı (cihaz başına), Claude çağrısı, yanıt şemasını zorlamak,
  engel listesi. Hesabı, ödemeyi ve anahtarı sahip açar; anahtar hiçbir
  dosyaya yazılmaz, depoya girmez.
- **Model:** Claude (güncel Opus/Sonnet; maliyet/hız dengesine göre plan
  aşamasında seçilir).

## Gizlilik ve mağaza
- Claude ile bul yalnız ürün adını yollar. Claude'a sor, soruyu ve kullanıcı
  izin verirse aktif profilin özetini yollar (konum yollanmaz).
- Gizlilik politikası ve App Store "veri toplama" bildirimleri güncellenir
  (#294 ile birlikte).

## Hata durumları
- İnternet yok → "Bağlantı yok; ürün bilgisini elle girebilirsin."
- Bulunamadı / zaman aşımı → alanlar boş, "Üretici kaynağında bulunamadı."
- Kısmi sonuç → yalnız geçen alanlar yazılır, kalanlar boş ve işaretli.
- Sunucu sınırı doldu → sade bir uyarı.

## Testler
- Saf Dart: kaynak zorunluluğu, engel listesi, aralık kontrolü, kayıt
  biçimi (eski kayıt açılır, yeni alanlar geri okunur).
- Widget: "Claude ile bul" akışı sahte sunucu yanıtlarıyla (tam, kısmi,
  bulunamadı, çevrimdışı); "Claude ile eklendi" işareti ve bağlantı.
- Sunucu: şema zorlaması ve engel listesi birim testleri.
- Hiçbir testte gerçek API anahtarı veya gerçek ağ çağrısı yok.

## Kural değişikliği
CLAUDE.md'deki "AI output is a hint list only" kuralına bu özellik için
istisna: "Claude'un üretici kaynağıyla bulduğu değerler, bu belgedeki
korumalarla kullanıcının profiline doğrudan kaydedilebilir (sahip,
15.10.2026). Ortak ürün listelerine yine yalnız üretici verisi girer."

## Sıra
1. v1 TestFlight (önce).
2. Sahip: Anthropic hesabı + sunucu hesabı.
3. Uygulama planı (writing-plans) → onay → görevler (önce Claude'a sor,
   sonra Claude ile bul).
