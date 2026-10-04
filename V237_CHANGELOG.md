# V237

- Sight Height doğrulanmış ölçümü artık yalnız ölçüm deposuna değil, aynı kimliği koruyarak aktif RifleProfile kaydına da uygulanır.
- Profil güncellemesi yalnız ölçüm kaydı başarıyla tamamlandıktan sonra yapılır; ölçüm kanıtı yazılamazsa profil değiştirilmez.
- Hesaplanan Sight Height için production sınırı fail-closed uygulanır: sonlu, >0 ve ProductionLimits.maxSightHeightMm altında olmalıdır.
- v237 source-contract regresyon testleri eklendi.
- Flutter/iOS build doğrulanmış değildir; bu sürüm bu konuda başarı iddiasında bulunmaz.
