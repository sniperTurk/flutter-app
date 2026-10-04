# v222 — Manuel katalog ilk-kayıt kurtarma güvenliği

- `ManualCatalogStore` ilk kullanıcı kaydında artık yedek snapshot da oluşturuyor.
- Önceki davranışta ilk yazımdan sonra primary veri bozulursa backup hiç bulunmayabiliyordu.
- Sonraki güncellemelerde backup, son bilinen sağlam primary snapshot olarak korunuyor.
- Yeni regresyon testi backup yazımının primary yazımdan önce olduğunu kilitliyor.
- Gerçek Flutter/iOS build, Simulator ve fiziksel cihaz testi bu ortamda yapılmadı.
