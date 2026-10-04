# v250 — Field tools production guard

- v249 Pusula ve Su Terazisi kaynak uygulaması doğrulandı.
- Su Terazisi iki ondalık (0,01° gösterim çözünürlüğü) ve ±0,01° merkez göstergesi sözleşmesi regresyon testiyle kilitlendi.
- Pusula/Su Terazisi ana ekran erişimi, sensör bağımlılıkları ve subscription dispose davranışı için production guard eklendi.
- Offline Python suite: 327/327 PASS.
- Gerçek Flutter/iOS build, Simulator ve fiziksel iPhone sensör testi bu ortamda doğrulanmadı; başarılı olarak raporlanmamalı.
