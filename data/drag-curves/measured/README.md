# Ölçülmüş sürüklenme eğrileri (Cd–Mach) — veri biçimi

Her dosya bir merminin ölçülmüş eğrisidir. `tools/data_gen/generate_measured_drag_curves.py`
yalnızca `"use_in_app": true` olan ve tüm denetimlerden geçen kayıtları
`lib/data/measured_drag_curves.dart` dosyasına yazar.

| Alan | Anlamı |
|---|---|
| `id` | Benzersiz kısa ad (dosya adıyla aynı). |
| `brand`, `bullet` | Ölçümü yayımlayan kurum/üretici ve mermi adı. |
| `diameter_mm`, `weight_gr` | Ölçülen merminin çapı ve ağırlığı. |
| `method` | `doppler-radar` veya `spark-range` ve kısa açıklama. |
| `coefficient` | `CD0` veya `CX0` (sıfır yalpa). |
| `points` | `[[Mach, Cd], ...]`, Mach artan; uygulamadaki özel eğri biçimiyle aynı (`DragCurve.fromJson`). |
| `source_url`, `source_title` | Birincil kaynak (üreticinin/kurumun kendi sayfası ya da raporu). |
| `license` | `us-government-public-release`, `cc-by-4.0`, `cc0-1.0` veya `written-permission`. Başka değer reddedilir. |
| `license_note` | Lisans/kullanım koşulunun aynen alıntısı ve yeri. |
| `use_in_app` | `true` ise uygulamaya girer. |
| `use_in_app_reason` | `false` ise nedeni. |
| `library` | `{"brand", "name", "grain"}`: `lib/data/bullet_library.dart` içindeki birebir aynı mermi. `use_in_app: true` için zorunlu. |

Uygulamaya alınma koşulları (generator denetler):

- en az 5 nokta, Mach kesin artan, 0 < Cd ≤ 2;
- ses altından ses üstüne kapsama: ilk nokta Mach ≤ 0,8, son nokta Mach ≥ 2,0
  (çözücü eğri dışını sabit tutar; eksik bölge sonucu bozar);
- `library` alanı mermi kütüphanesinde birebir (marka, ad, grain) bulunmalı;
- izinli lisans değeri ve `https://` kaynak bağlantısı.

Yasak kaynaklar: Applied Ballistics (CDM dahil), ChairGun, Strelok, QuickLOAD/QuickTARGET,
GRT, JBM, Hornady 4DOF uygulama verisi, forum, blog, bayi, arşiv kopyaları.
