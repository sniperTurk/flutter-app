# Temiz tasarım — Profil, Profil Oluştur, Araçlar (görev raporu)

Görev: sahibin 15 Ekim 2026 10:07 (İstanbul) "görev aç" kararı. Kaynak tasarım:
`design/clean-2026-10-15` dalındaki `docs/design/clean-2026-10-15/` (README.md karar
listesi, ProfilOlustur / Profil / Araclar görüntüleri). O dal birleştirilmedi,
yalnız örnek alındı. Dal: `design/clean-profil`, PR #318.

## Ne yapıldı

1. **Büyük ekran modüllere bölündü (davranış aynı).** `profiles_screen.dart`
   (5242 satır) aynı Dart kütüphanesinin parçalarına (part dosyası) ayrıldı:
   - `profiles_screen.dart` (862): Profil listesi sayfası.
   - `profile_summary.dart`: Profil sayfasındaki aktif profil özeti.
   - `profile_editor.dart`: Profil Oluştur/Düzenle'nin durumu, kontrolleri,
     kaydı ve sayfa çerçevesi (Kimlik kartı).
   - `profile_editor_rifle.dart`: Tüfek bölümü.
   - `profile_editor_scope.dart`: Dürbün bölümü.
   - `profile_editor_ammo.dart`: Mühimmat bölümü.
   - `profile_editor_ammo_extra.dart`: Ek mühimmat bilgileri bölümü.
2. **Profil Oluştur tasarımı:**
   - Yeni profilde **Tür** kutusu artık "Seçiniz" ile açılıyor (önceden
     "Ateşli Tüfek" yazıyordu). Diğer bütün seçim kutuları zaten "Seçiniz",
     yazı kutuları zaten boştu; bunlar artık testle korunuyor.
   - **Dürbün:** "Üst kule klik sayısı | Dürbün ayağı" aynı satırda, Dürbün
     ayağı sağda (önceden tersiydi).
   - **Ek mühimmat bilgileri** kendi başlığı ve kendi kartı olan ayrı bölüm
     oldu (Mühimmat kartının altında ayrı kart). Başlık satırında solda
     "Ek mühimmat bilgileri", sağ uçta "isteğe bağlı" ve ⓘ. Hiç kapanmaz.
   - **Kalibre** tek satır, tam genişlik (zaten öyleydi; testle korunuyor).
   - **Eşik altı BC** birimsiz (zaten öyleydi; testle korunuyor).
   - **Dürbün Marka** değişince Birim, Odak, Tüp, Büyütme, Model ve Retikül
     "Seçiniz"e dönüyor (kod zaten yapıyordu; artık testle korunuyor).
3. **Ortak kutu (MenzilSelect):** açılan liste her zaman **kutunun altından,
   4 pt boşlukla ve tam kutu genişliğinde** açılıyor. Kutu ekranın altına
   yakınsa sayfa önce yukarı kayıyor, liste yine aşağı açılıyor.
4. **Ortak düğmeler (MenzilSecondaryButton):**
   - "Alındı / yapıldı" hâli: dolgu #1F5F7A, çerçeve #2E7FA0, yazı beyaz.
     Turuncu artık hiçbir düğmede yok (turuncu yalnız rüzgâr saati kadranında
     kaldı, ona dokunulmadı).
   - Düğmelerde simge çizilmiyor. Tek istisna: alındı hâlindeki ✓ (yalnız
     "Hava verisi alındı" için; onu Hava sayfası görevi kullanıyor).
5. **Araçlar:** araç ikonları beyaz (#E7EFF3), zemin gri-mavi (#1B3245);
   amber kalktı.
6. **Profil sayfa başlığı "Sniper Türk":** zaten öyleydi (Profil sekmesinde
   üst çubukta "Sniper Türk" yazıyor); değişiklik gerekmedi.

## Nasıl

- Bölme işi elle değil, bir betikle yapıldı: her metot/alan olduğu gibi
  taşındı. Taşınan bölümler `_ProfileDialogState` üzerine `extension` oldu.
  Dart kuralı gereği yalnız iki mekanik değişiklik var: sınıfın statik
  üyeleri `_ProfileDialogState.` ön ekiyle yazıldı ve `setState` yerine
  `_update` çağrılıyor (extension'ın `setState` çağırması analizde uyarı
  veriyor; `_update` sınıfın içinde `setState`'i çağırıyor). Betik, eski ve
  yeni dosyaların satırlarını karşılaştırdı: kaybolan satır yok.
- Kayıt anahtarları, kayıt biçimi, test anahtarları (Key/ValueKey) ve gizli
  bayraklar (`bool.fromEnvironment`: SCOPE_/RIFLE_/AMMO_LISTEDE_YOK,
  AMMO_BC_BANDS_TYPED, PCP_AMMO_BRAND, PROFILE_AMMO_LENGTH) aynen duruyor.
  Hiçbir şey silinmedi.
- Açılan liste için Flutter'ın kendi listesi kullanılamıyordu (listeyi
  kutunun üstüne bindiriyor, aşağıda yer yoksa yukarı açıyordu). Kutunun
  görünümü aynı kaldı; dokununca kendi listemiz kutunun altına açılıyor.
- Tür kutusu için yeni bir "seçildi mi" işareti eklendi (`_platformSet`),
  diğer kutulardaki aynı düzen gibi.
- Yeni renkler tek yerde, tema dosyasında (`menzil_theme.dart`) tanımlandı;
  depo kuralı renklerin yalnız orada yazılmasını istiyor.

## Neden

- Sahibin 15 Ekim kararı: onaylı temiz tasarım uygulanacak ve büyük ekran
  modüllere bölünecek.
- Bölme ayrı commit'te ve davranış değiştirmeden yapıldı ki tasarım
  değişiklikleri ayrı görülebilsin.

## Uç durumlar

- **Tür "Seçiniz" iken** form eskisi gibi Ateşli Tüfek kurallarıyla çalışır
  (Ateşli listeleri, "Mühimmat türü"). Tür seçilmeden kaydedilirse profil
  Ateşli kaydedilir; bu, önceki varsayılanla aynı. Tür seçimi kaydetmek için
  zorunlu yapılmadı (yeni kural eklememek için).
- **Ekranın en altındaki kutu:** sayfa kaydırılabiliyorsa yukarı kayar ve
  liste aşağı açılır. Sayfa artık kayamıyorsa liste yine aşağı açılır ama
  kısalır (en az bir satır), içinde kaydırılır.
- Liste açıkken telefon döndürülürse liste kapanır (Flutter'ın listesi de
  böyle yapıyordu).
- Ek mühimmat bilgileri kartı, eskisiyle aynı koşulda görünür: PCP'de yok;
  elle yazılan Ateşli fişekte yalnız Barut katsayısı | Hız ölçüm sıcaklığı.
- Kayıtlı profiller ve kişisel kayıtlar aynen açılır; kayıt biçimi değişmedi.

## Yapılmayanlar (bilerek)

- **PCP'de BC modeli** yeni profilde "G1" ile başlamaya devam ediyor. Sahibin
  14 Ekim kararı ("G1 seçili kalsın") ve kayıt bu değere dayanıyor. "Her kutu
  Seçiniz" kuralıyla çelişiyor; karar sahibin. İsterse ayrı görevle değişir.
- **Profil adı** yeni profilde "Yeni Profil" ile dolu gelmeye devam ediyor
  (12 Ekim kararı: dokununca silinir, boş bırakılırsa geri gelir). Tasarım
  görüntüsünde boş görünüyor; karar sahibin.
- "… alındı" yazısı ve sayfaya dönünce o hâlde kalması düğmeyi kullanan
  sayfanın işi. Bu görevin sayfalarında (Profil, Profil Oluştur, Araçlar)
  böyle bir düğme yok. Ortak düğme rengi hazır; Hava Durumu / Pro / Hedef
  düğmeleri `lib/features/ballistics/**` görevinde.
- Ana eylem düğmeleri (MenzilPrimaryButton: "+ Profil ekle", "Hava
  Durumu'na geç →") simgeli kaldı; tasarım görüntüsünde de simgeli.
- Tasarım görüntüsündeki "1. eşik hızı" kutusunun "fps" birimi istenmediği
  için eklenmedi.
- Hesap, kayıt biçimi, form alanları değişmedi. TestFlight başlatılmadı.
- Önce/sonra ekran görüntüsü yok: bu ortamda Flutter çalıştırılamıyor
  (Flutter SDK indirilemiyor), görüntü üretilemedi.

## Testler

- Yeni: `test/temiz_tasarim_profil_test.dart`
  - Yeni profilde her seçim kutusu "Seçiniz", her yazı kutusu boş (Profil adı
    hariç); Tür seçilince gösteriliyor, form o zamana dek Ateşli.
  - Açılan liste: tam/yarım genişlik kutuda 4 pt altta, kutu genişliğinde;
    alttaki kutuda sayfa kayıyor, liste yine altta.
  - Kalibre tam genişlik tek satır; Dürbün "Üst kule klik sayısı | Dürbün
    ayağı" (ayak sağda).
  - Ek mühimmat bilgileri ayrı kart, başlık kartın dışında, "isteğe bağlı" ve
    ⓘ sağ uçta, kapama oku yok; Eşik altı BC birimsiz.
  - Dürbün Marka değişince dört filtre, Model ve Retikül "Seçiniz".
  - Alındı düğmesi #1F5F7A / #2E7FA0 / beyaz (etkin ve pasif), turuncu değil;
    düğmelerde simge yok, yalnız alındı ✓.
  - Araçlar ikonları #E7EFF3, zemin #1B3245.
- Yeni tasarıma göre güncellenen eski beklentiler (karar değiştiği için):
  - `test/profil_duzen_koruma_test.dart`: Dürbün satırı artık "Üst kule klik
    sayısı | Dürbün ayağı"; Ek mühimmat başlığı kutularla değil kendi kartıyla
    hizalı.
- Bölme için: Python kaynak denetimleri (`tools/test_v223…`, `test_v299…`,
  `test_v368…`, `test_v371…`) artık kütüphanenin tamamını (ana dosya + part
  dosyaları) okuyor (`tools/dart_library_source.py`); denetimler aynı, metin
  başka dosyaya taşındı diye geçmiş sayılmıyor. `test_offline_dart_lint` aynı
  satırı `profile_editor.dart` içinde arıyor.
- Yerelde: `python3 tools/offline_dart_lint.py` geçti (357 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (748 test).

## CI bağlantıları

Yalnız gerçekten koşan ve sonucunu gördüğüm işler:

- Biçim (dart format, tek seferlik düzeltme): run 38699344445 → biçim
  commit'i `d7993f2` dala eklendi.
  https://github.com/sniperTurk/flutter-app/actions/runs/38699344445
- Bölme commit'i (`b3a054b`, biçimsiz) üzerinde: analyze run 38698275528
  başarılı, tüm testler run 38698278287 başarılı.
- Tasarım + biçim (`d7993f2`) üzerinde: analyze run 38699526386 **başarısız**
  (biçimden sonra 4 tek satırlık `if` çok satıra bölündü, süslü parantez
  istendi) → `d553207` ile düzeltildi; tüm testler (`flutter test test`) run
  38699531742 **başarılı**.
  https://github.com/sniperTurk/flutter-app/actions/runs/38699531742
- `d553207` üzerinde: analyze run 38699763555 **başarılı**.
  https://github.com/sniperTurk/flutter-app/actions/runs/38699763555
- PR iOS CI (`d553207`): run 38699768186 — wind-acceptance başarılı,
  ios-simulator atlandı (varsayılan), dart-checks ve verify bu rapor
  yazılırken sürüyordu.
  https://github.com/sniperTurk/flutter-app/actions/runs/38699768186
- Bu rapor commit'i yalnız belge değiştirdiği için PR iş akışı kendiliğinden
  koşmaz; iOS CI bu son commit için elle başlatıldı. Son sonuç PR
  açıklamasında.

## Birleştirme sonucu

Koşul: PR'ın son commit'inde `verify`, `dart-checks`, `wind-acceptance`
başarılı ve çakışma yok → hazır işaretlenip squash-merge. Sonuç PR
açıklamasının sonunda yazılı (birleştirme sonrası bu dosya
değiştirilemiyor).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
