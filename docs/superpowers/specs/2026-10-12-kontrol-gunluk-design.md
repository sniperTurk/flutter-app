# Ö11 Kontrol listesi, Ö10 Sıfır grubu, Ö9 Atış günlüğü — tasarım

Kaynak: `docs/yeni-hesaplar-2026-10-11.md` (PR #153, dal `docs/yeni-hesaplar`),
Ö9, Ö10, Ö11. Sahibi raporun tamamının geliştirilmesini istedi. Görev
"sahibine soru sorma, makul cevapla, varsayımları yaz" dediği için
brainstorming onay noktaları yerine kararlar burada.

## Sınıflandırma

Mimari: üç yeni sayfa, bir yeni kalıcı depo, mevcut Sıfır ofseti deposuna
yazma. Spec + plan yazıldı; onay yerine bu belgedeki varsayımlar geçerli.

## Kullanıcının söyledikleri (görev metni)

- Üçü de Araçlar altında ayrı sayfa.
- Ö11: işaret kutuları; Su Terazisi ekranına dokunulmaz, yalnız listede madde.
- Ö10: hedef görseline dokunarak vuruş; merkez, σ, σ/√n; "X klikten büyük,
  N atış daha"; sonuç kullanıcı onayıyla mevcut Sıfır ofsetine.
- Ö9: oturum kaydı; soğuk namlu ortalaması yalnız yeterli kayıtta (≥ 5 ilk
  atış) ve kullanıcı onaylarsa ilk atışa öneri; uydurma varsayılan yok; veri
  telefonda, ağa gitmez.
- UI kuralları: CLAUDE.md + görevdeki liste.

## Varsayımlar (A)

| # | Varsayım | Gerekçe |
|---|---|---|
| A1 | Üç sayfa da aktif profili kullanır (Hız Doğrulama gibi); sayfada profil seçme kutusu yok. Profil adı sayfanın başında yazı olarak görünür. | "Doğru profil" kontrolü aktif profili göstermeli; seçme kutusu ikinci bir "aktif profil" kavramı yaratırdı. |
| A2 | Kontrol listesi kalıcı değildir; sayfa her açılışta boş başlar. | Her atış öncesi yeniden kontrol edilmeli; dünkü işaret bugünü kandırmamalı. |
| A3 | SFP maddesi yalnız dürbün FFP olarak bilinmiyorsa (`firstFocalPlane != true`) görünür. | FFP'de büyütme tutuşu bozmaz. |
| A4 | Sıfır grubu hedefi: aim noktası merkezde 10×10 kareli kâğıt; "Kare boyu" listeden (1 cm, 2,5 cm, 5 cm). Kareli hedef kâğıtları bu ölçülerde satılır. | Ölçek olmadan dokunuş cm'ye çevrilemez; yazma yerine seçim (owner kuralı). |
| A5 | σ: iki eksenin havuzlanmış örnek standart sapması, `σ = √((Σdx²+Σdy²)/(2(n−1)))`; merkez belirsizliği eksen başına `σ/√n` (Grubbs 1964; NIST e-Handbook 1.3.5.2, ortalamanın standart hatası). | Dairesel normal dağılım varsayımı; raporla aynı. |
| A6 | Hedef: merkez belirsizliği ≤ 1 klik. Gereken toplam atış `N = ⌈(σ/klik)²⌉`, en az 3. Klik = profil dürbününün tık değeri, atış mesafesinde cm'ye çevrilir. | Rapor "X klikten büyük, N atış daha" diyor; 1 klikten ince düzeltme kuleyle yapılamaz. |
| A7 | Sıfır ofseti cm olarak profilin sıfır mesafesinde saklanıyor. Grup başka mesafede atıldıysa açı korunarak çevrilir: `cm_sıfır = cm · sıfır / mesafe`. Mesafe kutusu profilin sıfır mesafesiyle dolu gelir. | Mevcut `_zeroOffsetMrad` hesabı cm'yi sıfır mesafesine böler. |
| A8 | Aktarım, onay penceresinde eski → yeni değerleri gösterir; "Uygula" olmadan hiçbir şey yazılmaz. Açık olan Hedef çalışma alanı yeni değeri hemen okur (depo değişiklik bildirimi). | Hız Doğrulama ile aynı onay deseni; açık ekran eski değeri geri yazmasın. |
| A9 | Günlük kaydı alanları: Mesafe; İlk atış (Seçiniz/Evet/Hayır); Susturucu (Seçiniz/Takılı/Takılı değil); Verilen yükseliş, Verilen yan (profil birimi, boş bırakılabilir); Kaçıklık yukarı, Kaçıklık sağa (cm, zorunlu; aşağı/sol eksi). Tarih ve profil otomatik. | Rapordaki alan listesi; tarih/profil elle girilirse yanlış yazılır. |
| A10 | Soğuk namlu ortalaması profil + susturucu durumuna göre ayrı hesaplanır, yalnız "İlk atış = Evet" kayıtlarından, açı olarak (mrad = cm·10/mesafe). | Susturucu vuruş noktasını kaydırır; farklı mesafeler açıyla birleşir. |
| A11 | Öneri ancak (a) ≥ 5 ilk atış ve (b) en az bir eksende |ortalama| ≥ 2·standart hata ise sunulur. Aksi halde "öneri yok" ve nedeni yazılır. | Uydurma/gürültü düzeltme vermemek; ~%95 güven. |
| A12 | Onaylanan öneri Hedef ekranında bir bilgi satırıdır ("Soğuk namlu, ilk atış: …"); tıklara eklenmez. Onay profil + susturucu başına saklanır, değer her açılışta kayıtlardan yeniden hesaplanır; eşik düşerse satır kaybolur. | "Öneri olarak sunulur" — çözücü ve tık hesabı değişmez. |
| A13 | Günlük `lib/services/shot_journal_store.dart`, SharedPreferences JSON; en fazla 1000 kayıt (eskiler düşer). Ağ yok. | Mevcut store deseni; `lib/features/tools` ve `lib/tools` SharedPreferences içeremez (sözleşme testi). |
| A14 | Görevdeki "font Oswald" maddesi: sahibi 2026-10-12'de Oswald'ı Inter ile değiştirdi (`MenzilType.family`). Yeni sayfalar tema stillerini kullanır; yazı tipine dokunulmadı. | Daha yeni sahip kararı koddadır; çelişki PR'da belirtildi. |
| A15 | Hub'a üç kart en sona eklenir (açık #185/#186 ile çakışmayı azaltmak için). | Görev: "çakışmayı azaltır". |

## Birimler

- `lib/tools/domain/group_center.dart` — saf: merkez, σ, belirsizlik, gereken atış, klik cm.
- `lib/tools/domain/cold_bore.dart` — saf: susturucu başına ilk atış istatistiği ve öneri kararı.
- `lib/tools/domain/preshot_checklist.dart` — saf: dürbüne göre madde listesi.
- `lib/services/shot_journal_store.dart` — kayıtlar + soğuk namlu onayları.
- `lib/services/shot_settings_store.dart` — `updateZeroOffset` + `changes` bildirimi.
- `lib/features/tools/preshot_checklist_screen.dart`, `zero_group_screen.dart`, `shot_journal_screen.dart`, `cold_bore_hint.dart`.
- `lib/features/ballistics/ballistics_screen.dart` — iki küçük ekleme: depo bildirimini dinle; Hedef'te `ColdBoreHint`.

## Hata durumları

- Profil yok → sayfa "Önce bir profil oluşturun" der, giriş göstermez (kontrol listesi profil maddesi olmadan çalışır).
- Depo okunamaz/bozuk JSON → boş günlük; bozuk kayıt atlanır.
- Mesafe ≤ 0, NaN, sonsuz → sonuç/kayıt yok, alan hata yazısı.

## Test

Saf hesaplar birim testli (bilinen sayılarla); depo için gidiş-dönüş ve
bozuk veri testleri; sayfalar için widget testleri (onaysız yazmama, eşik
altında öneri yok, SFP maddesi FFP'de yok).
