# v219 — PCP mühimmat markaları + manuel katalog

- Kullanıcının sağladığı 23 PCP pellet/slug marka referansı `data/global_pcp_ammunition_brands.csv` içinde, doğrulanmamış kaynak statüsüyle saklandı. Mevcut resmî mühimmat model kayıtları değiştirilmedi.
- Katalog ekranına tüfek, PCP/ateşli mühimmat ve dürbün için manuel ekleme, düzenleme, silme ve arama eklendi. Kullanıcı kayıtları `shared_preferences` içinde ayrı saklanır; platform filtrelemesi korunur.
- Marka/model, tüfek kalibresi, mühimmat tipi/grain/isteğe bağlı BC, dürbün büyütme/objektif/FFP-SFP/klik ve serbest not alanları eklendi. Zorunlu sayısal değerler doğrulanır.
- Manuel kayıtlar üretici verisi olarak sunulmaz. Offline statik kontroller gerçek Flutter/iOS testi yerine geçmez.
