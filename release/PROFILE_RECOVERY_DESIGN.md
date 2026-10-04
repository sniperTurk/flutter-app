# Birincil + yedek profil kaydı bozulduğunda güvenli kurtarma (tasarım, V368)

## Mevcut durum (kodla doğrulandı: lib/services/profile_store.dart)
- Birincil bozuk + yedek sağlam → yedek okunur, birincil yedekle onarılır. **V368:** onarımdan önce bozuk bayt `…v1.corrupt` anahtarına kopyalanır (ilk kanıt korunur, hiçbir kod silmez).
- Birincil + yedek bozuk → `StateError` (fail-closed); `save/remove/all` hepsi hata verir; veri değişmez. Ana ekran "Profil verileri okunamadı. Kayıtlar değiştirilmedi." gösterir. **Kullanıcı için çıkış yolu yok.**

## Tasarım ilkeleri
1. Bozuk bayta ASLA otomatik yazılmaz/silinmez; kurtarma yalnız kullanıcı eylemiyle.
2. Her kurtarma adımından önce bozuk baytlar quarantine anahtarına kopyalanır (zaten var).
3. "Boş başla" seçeneği bozuk veriyi silmez: yeni koleksiyon yazılmadan önce iki bozuk kayıt `…corrupt` / `…corrupt.backup` olarak taşınır, kullanıcı onay ister ("N baytlık kayıt saklanacak, yeni boş liste açılacak").
4. Kısmi kurtarma: bozuk JSON'dan geçerli kayıtları ayrıştırmak otomatik yapılmaz; yalnız "Kurtarılabilir profilleri göster" ile salt-okunur önizleme, kullanıcı tek tek seçip içe aktarır (her kayıt `ProfileCodec`+`ProfileInput` doğrulamasından geçer).
5. Dışa aktarma: bozuk ham metin "Paylaş" ile kullanıcıya verilebilir (destek için).

## Önerilen UI akışı (uygulanmadı; sahip onayı gerekir)
Ana ekran hata kartı → "Kayıtları kurtar" → üç seçenek: (a) Kurtarılabilir kayıtları incele (salt-okunur), (b) Ham veriyi paylaş, (c) Boş başla (kayıtlar saklanarak, ayrı onay). Seçenek (c) dışında hiçbir yazma yok.

## Gerekli testler (Flutter ile çalıştırılmalı; şu an yok/NOT RUN)
- İki bozuk kayıt + (c): quarantine anahtarları baytı birebir içerir, yeni liste boş, eski bayt kaybolmaz.
- Quarantine yazımı başarısızsa hiçbir şey değişmez.
- (a) önizlemede geçersiz kayıt listelenmez, geçerli kayıt içe aktarılırken `ProfileInput.validate` çalışır.
Kapsam kararı: V1 için BLOCKER değil (veri korunuyor); "RELEASE ÖNCESİ" öneri: en azından Ham veriyi paylaş + Boş başla.
