# V382 — tüfek eğimi ve dürbün eğimi

Kaynak: `main` @ `9a88ed2`.

- Çözücü (G1/G7 RK4 ve vakum): atış eğimi (θ) ve dürbün eğimi (φ).
  Yerçekimi ve yatay rüzgâr dürbün eksenlerine döndürülür:
  g = (−g·sinθ, −g·cosθ·cosφ, +g·cosθ·sinφ). Mesafe bakış çizgisi
  boyuncadır (telemetre). Sıfır düz ve eğimsiz çözülür. θ = φ = 0 eskisinin
  aynısı. Test: dünya koordinatlarında bağımsız RK4 ile birebir karşılaştırma.
- Atış: "Tüfek eğimi" (elle veya kamerayla ölç: arka kamera + artı, Set 0°,
  İptal/OK) ve "Dürbün eğimi" (saat kadranı, telefonla ölç, 0'a ayarla,
  sil) kutuları. Dürbün görünümünde "Hedef: X m ∠ θ°", retikül eğim açısıyla
  döner, hesap dökümünde açıklama.
- Yan kart dürbün eğimi varken "Yan (rüzgâr + dürbün eğimi)".
- DOPE tablosu düz atış için kalır.
