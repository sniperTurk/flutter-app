# Diğer kalibre silindi (Profil > Tüfek > Kalibre)

Sahip, 17.10.2026 17:48–17:52 (İstanbul), TestFlight 113, Profil Oluştur > Tüfek: Marka Heym, Model Express seçilince Kalibre listesinde modelin 5 üretici kalibresinin (.375 H&H Mag, .404 Jeffery, .416 Rigby, .450 Rigby, .458 Lott) altında "Diğer kalibre" vardı ve tüm kalibre listesini (.308 Win, .223 Rem …) açıyordu. Sahip bunu yanlış buldu; listede olmayan kalibre "Aradığın tüfek listede yok mu?" yoluyla girilebildiği için "A" dedi: "Diğer kalibre" kalksın.

## Ne değişti

- Listeden bir tüfek modeli seçilince Kalibre listesinde **yalnız o modelin kalibreleri** var. "Diğer kalibre" satırı ve onun açtığı "tüm kalibreler" yolu koddan **silindi** (bayrakla gizlenmedi): `_otherCaliberKey`, `_caliberAll` alanı ve bunlara bağlı bütün dallar kalktı.
- Başka hiçbir şey değişmedi: "Seçiniz" başlangıcı, 8 satırlık açılır liste, etiketler, ⓘ metinleri, yerleşim aynı.

## Nasıl

- `lib/features/profiles/profile_editor_rifle.dart`: `_caliberFromModel` artık "yazılı tüfek değil ve modelin kalibresi var" demek; listeye "Diğer kalibre" eklenmiyor; `_onCaliberKey` içindeki "tüm liste" dalı silindi.
- `lib/features/profiles/profile_editor.dart`: `_caliberAll` alanı ve sabit `_otherCaliberKey` silindi.
- Eski kayıtlar için küçük bir durum eklendi: `_offModelSaved` (aşağıda).

## Neden

Model seçildiyse kalibre üreticinin o model için verdiği kalibrelerden biridir. Başka kalibre isteyen kullanıcı tüfeği "Aradığın tüfek listede yok mu?" ile yazılı girer; orada tam liste aynen duruyor.

## Uç durumlar

- **Yazılı tüfek ("Aradığın tüfek listede yok mu?")**: Kalibre listesi bugünkü gibi tam (ateşli: EN ÇOK KULLANILAN, DİĞERLERİ (A-Z), "Fişeğim listede yok"; PCP: PCP kalibre listesi). Testle değer değer karşılaştırıldı.
- **Listeden Marka seçildi, Model hâlâ "Seçiniz"**: modelin kalibresi henüz yok; Kalibre bugünkü gibi tam listeyi gösterir (değişmedi). Listeden seçilen her modelin en az bir kalibresi vardır; tek kalibreli modelde kalibre bugünkü gibi kendiliğinden seçilir.
- **Eski profil, modelin listesinde olmayan kalibre** (önceden "Diğer kalibre" ile seçilmiş, ör. Heym Express + .308 Win): Profili Düzenle açılınca Marka Heym, Model Express kalır; Kalibre kutusunda kayıtlı kalibre **önceki gibi aynı yazıyla** görünür (ateşlide fişek adı, ör. ".308 Win"; adı bilinmeyen çapta "7 mm (kayıtlı)" gibi; PCP'de PCP kalibre adı). Açılan listede modelin kalibrelerinin altında **son satır** olarak bu kayıtlı değer durur; "Diğer kalibre" yoktur. Bu satır seçilirse hiçbir şey değişmez. Kullanıcı modelin bir kalibresini seçerse ya da Marka/Model/Tür değiştirirse bu satır kalkar. Güncelle'ye dokunmadan basılınca kayıt aynı kalır; hesap girdileri (kalibre, yiv, hız, sıfırlama, BC, dürbün klik …) birebir aynıdır.
- **Önceki davranışla aynı kalan bir durum (bilerek dokunulmadı)**: Yeni profilde model seçilip Kalibre "Seçiniz" iken listeden fabrika fişeği seçilirse, fişek kalibreyi bugünkü gibi doldurur ve kutu bugünkü gibi "Seçiniz" görünür. Kayıtlı-kalibre satırı yalnız eski profil açılırken çıkar; bu yol değişmedi. (Bu mevcut bir tutarsızlık; ayrı görev konusu olabilir.)
- **Eski kayıtta bilinen bir isim kaybı (önceden de böyleydi)**: kayıtta yalnız çap (mm) tutulur; aynı çaplı fişeklerden ilki gösterilir (7,82 mm → ".308 Win"). Bu değişiklikten önce de aynıydı.

## Bilerek yapılmayan

- Mühimmat bölümü, diğer sayfalar, ⓘ metinleri, etiketler, yerleşim: dokunulmadı.
- TestFlight yok; birleştirme yok (taslak PR).

## Testler

Yeni: `test/diger_kalibre_sil_test.dart`
- Heym Express: Kalibre listesinde tam 5 öğe (.375 H&H Mag, .404 Jeffery, .416 Rigby, .450 Rigby, .458 Lott), açık listede 5 satır, "Diğer kalibre" yok; başlangıç "Seçiniz".
- Yazılı tüfek (ateşli): liste değerleri `Cartridges.firearm` ile birebir (başlıklar ve "Fişeğim listede yok" dahil). Yazılı PCP: PCP listesi birebir.
- Marka seçili, Model "Seçiniz": tam liste (değişmedi).
- Eski profil Heym Express + .308 Win: açılınca kutu ".308 Win", liste = 5 kalibre + ".308 Win"; kayıtlı satır tekrar seçilince değişmez; Güncelle sonrası bütün hesap girdileri aynı.
- 320 pt × yazı 1,3 ve 390 pt × 1,0: yeni profil ve eski profil, liste açıkken taşma yok.

"Diğer kalibre"yi doğrulayan eski test yoktu; güncellenen ya da silinen test yok. Hiçbir test gevşetilmedi.

Hesap: çözücü koduna dokunulmadı; eski profilin Güncelle öncesi/sonrası hesap girdileri testte birebir eşit.

Yerel (bu ortamda Flutter SDK indirilemedi, 403; Flutter testleri CI'da koştu):
- `python3 tools/offline_dart_lint.py` → PASS (435 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 skip)

## Ekran görüntüsü

**BLOCKED — simülatör ekran görüntüsü alınamadı.** Ekran turu hazır (`integration_test/diger_kalibre_sil_screens_test.dart`: Heym Express Kalibre listesi açık, 5 öğe, "Diğer kalibre" yok; eski Heym + .308 profili kutu ve liste). Ancak `sim-screens.yml` tek bir eşzamanlılık grubu kullanıyor (`group: sim-screens`) ve aynı anda çalışan diğer oturumlar sürekli yeni çalıştırma başlattığı için bekleyen çalıştırmalarım iş başlamadan iptal edildi (17.10 15:02–17:35 UTC arasında 4 deneme; ör. https://github.com/sniperTurk/flutter-app/actions/runs/39046149702, https://github.com/sniperTurk/flutter-app/actions/runs/39050352886). Başkalarının bekleyen çalıştırmasını iptal ettirmemek için daha fazla zorlamadım. Görüntü olmadan "ekran kapısı" geçmiş sayılmaz; sim-screens boşaldığında şu komutla alınabilir:

`gh workflow run sim-screens.yml --ref main -f ref=fix/diger-kalibre-sil -f test=integration_test/diger_kalibre_sil_screens_test.dart -f device="iPhone 16e"`

Ekranın kendisi widget testleriyle doğrulandı (yukarıdaki testler: 5 öğe, "Diğer kalibre" yok, 320 pt × 1,3 taşma yok); bu bir ekran görüntüsünün yerini tutmaz.

## CI bağlantıları

PR head `711115ca` (PR #389):
- `verify`: success — https://github.com/sniperTurk/flutter-app/actions/runs/39044760348/job/117434850516
- `dart-checks`: success — https://github.com/sniperTurk/flutter-app/actions/runs/39044760348/job/117431223271
- `wind-acceptance`: success — https://github.com/sniperTurk/flutter-app/actions/runs/39044760348/job/117431223490
- `ios-simulator`: skipped (workflow kuralı; bu PR'da çalışmadı, geçti denmez)
- Tam `flutter test` (test-diag, files=test): success — https://github.com/sniperTurk/flutter-app/actions/runs/39044760970
- dart format (format-fix): ilk commit'te test dosyasında 2 satır biçimlendirdi (commit `5002a953`); sonraki commit'lerde değişiklik yok.
- İlk test koşusu (`874c23ac`/`5002a953`) yeni testte bir hata yakaladı: eski profil kayıtları, hesap girdileri alınmadan önce yüklenmiyordu (test hatası, uygulama değil); `711115ca`'da düzeltildi: https://github.com/sniperTurk/flutter-app/actions/runs/39043289859
- Bu rapor commit'i yalnız doküman ekler; PR'daki CI yeniden koşar.

TestFlight, Simulator turu, cihaz: çalışmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01FBsp2E9y3nSKgGsNPaasCb
