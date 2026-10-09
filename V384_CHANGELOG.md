# V384 — Hız Doğrulama (sahada truing)

Kaynak: `main` @ `b09c23f` (PR #44).

- Yeni araç: Araçlar → **Hız Doğrulama**. Sıfırdan uzak, bilinen bir
  mesafede grubu ortaya getiren gerçek yükseliş düzeltmesi ve atış anındaki
  hava (sıcaklık, basınç, nem) girilir; uygulama aktif profilin hesabının bu
  gözleme uyması için gereken namlu çıkış hızını bulur.
- Çekirdek: `lib/core/velocity_truing.dart` → `MuzzleVelocityTruing.solve`.
  Mevcut çözücüyle (G1/G7) ikiye bölme araması yapar; her aday hızda sıfır
  yeniden çözülür. Yalnız hız ayarlanır, BC değiştirilmez.
- Reddetme kuralları (tahmin üretilmez): mesafe sıfırdan uzak değilse;
  %1 hız farkı düzeltmeyi 0,02 mrad'dan az değiştiriyorsa (daha uzağa atın);
  gözleme uymak için hızda %15'ten fazla değişim gerekiyorsa (BC, sıfır,
  dürbün yüksekliği veya ölçüm hatası); mermi mesafeye ulaşamıyorsa.
- BC'siz mühimmatta araç hesap yapmaz, nedenini söyler.
- Sonuç profile yalnız eski → yeni hız onaylanınca, Kronograf ile aynı
  `ToolProfileUpdate.apply` doğrulamasıyla yazılır; Araçlar kapanınca kabuk
  profili yeniden yükler. %5'ten büyük değişimde kronograf önerisi gösterilir.
- Her giriş alanında ⓘ açıklaması var.
- `BallisticInput.withMuzzleVelocity` eklendi.
- Testler: `test/velocity_truing_test.dart` (G1 PCP ve G7 ateşli gidiş-dönüş,
  yuvarlama, tüm ret nedenleri), `test/truing_screen_test.dart` (profil yok,
  BC yok, onaydan önce kayıt yok, ret mesajı).

İnceleme ve birleştirme (2026-10-09): ayrı oturumda yazılan yama ana koda
uygulandı; hızlar Profil kuralı gereği fps gösteriliyor; Araçlar sıra testi
güncellendi. Doğrulama `iOS CI / verify` ve tam test koşusuyla yapıldı.
