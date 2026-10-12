# Mühimmat envanteri (2026-10-12, main 02d5af0 durumu)
Sayım: uygulamadaki üretilmiş listeler (`lib/data/factory_ammo_library.dart`, `lib/data/bullet_library.dart`) ve kaynak veri dalları (`data/ammo`, `data/mke`, `data/bullets-pcp`). Sütunlar, o alanı BOŞ olan kayıt sayısıdır.

## Fabrika fişeği (FactoryAmmoLibrary, 1737 kayıt)
| Marka | Kayıt | Kalibre sayısı | BC boş | Test namlu boş | Kaynakta mermi çapı boş |
|---|---|---|---|---|---|
| Barnes | 47 | 28 | 0 | 0 | – |
| Barrett | 2 | 2 | 0 | 0 | 1 |
| Berger | 34 | 11 | 0 | 2 | – |
| Black Hills | 88 | 19 | 56 | 0 | – |
| Blaser | 3 | 3 | 0 | 3 | – |
| CCI | 30 | 3 | 0 | 30 | 10 |
| CheyTac | 2 | 2 | 0 | 2 | – |
| ELEY | 1 | 1 | 0 | 1 | – |
| Federal | 235 | 36 | 1 | 235 | 39 |
| Fiocchi | 53 | 13 | 0 | 53 | – |
| Geco | 71 | 20 | 3 | 0 | – |
| Hornady | 124 | 48 | 9 | 0 | 66 |
| Lapua | 66 | 13 | 3 | 18 | – |
| MKE | 7 | 3 | 2 | 7 | – |
| Norma | 144 | 37 | 1 | 16 | – |
| Nosler | 37 | 14 | 1 | 1 | 36 |
| Prvi Partizan | 75 | 35 | 0 | 73 | – |
| RWS | 149 | 31 | 1 | 0 | – |
| Remington | 113 | 24 | 0 | 113 | 24 |
| SIG Sauer | 4 | 1 | 0 | 0 | – |
| SWISS P | 18 | 5 | 2 | 1 | – |
| Sako | 30 | 12 | 0 | 30 | – |
| Sellier & Bellot | 152 | 44 | 0 | 151 | – |
| Sierra | 8 | 8 | 0 | 8 | – |
| Weatherby | 94 | 17 | 1 | 83 | 94 |
| Winchester | 150 | 29 | 15 | 150 | 33 |
| **Toplam** | **1737** | | **95** | **977** | |

Ağırlık (grain) ve namlu çıkış hızı her kayıtta dolu (hızı olmayan kayıt listeye alınmıyor). Fişeklerde mermi/fişek uzunluğu alanı yok.

## Mermi çekirdeği ve PCP saçma/slug (BulletLibrary, 1723 kayıt)
| Marka | Platform | Tür | Kayıt | G1 boş | G7 boş | Uzunluk boş |
|---|---|---|---|---|---|---|
| Barnes | firearm | bullet | 176 | 0 | 176 | 1 |
| Berger | firearm | bullet | 113 | 0 | 14 | 0 |
| Federal | firearm | bullet | 8 | 0 | 3 | 0 |
| Hornady | firearm | bullet | 241 | 0 | 186 | 241 |
| Lapua | firearm | bullet | 55 | 0 | 23 | 52 |
| Norma | firearm | bullet | 1 | 0 | 1 | 1 |
| Nosler | firearm | bullet | 160 | 0 | 139 | 2 |
| Peregrine | firearm | bullet | 206 | 4 | 73 | 206 |
| RWS | firearm | bullet | 20 | 0 | 20 | 20 |
| Sierra | firearm | bullet | 194 | 0 | 62 | 194 |
| Speer | firearm | bullet | 96 | 0 | 96 | 96 |
| Swift | firearm | bullet | 70 | 0 | 70 | 70 |
| Warner | firearm | bullet | 14 | 3 | 0 | 0 |
| Woodleigh | firearm | bullet | 125 | 0 | 125 | 1 |
| H&N | pcp | pellet | 34 | 0 | 34 | 34 |
| H&N | pcp | slug | 35 | 0 | 35 | 2 |
| NSA | pcp | slug | 113 | 0 | 113 | 0 |
| Zan Projectiles | pcp | slug | 61 | 0 | 61 | 58 |
| Zan Projectiles | pcp | pellet | 1 | 0 | 1 | 0 |
| **Toplam** | | | **1723** | | | |

Kütüphanede her kayıtta en az bir BC (G1 ya da G7) var: kütüphane şimdiye kadar BC'si olmayan kaydı almıyordu.

## Veride olup uygulamada OLMAYAN PCP kayıtları (data/bullets-pcp, BC yayımlanmadığı için)
| Marka | Veride | Uygulamada | BC boş | Kafa çapı boş | Uzunluk boş |
|---|---|---|---|---|---|
| Air Arms | 11 | 0 | 11 | 0 | 11 |
| Crosman | 17 | 0 | 17 | 17 | 17 |
| FX | 1 | 0 | 1 | 1 | 1 |
| Hatsan | 15 | 0 | 15 | 15 | 15 |
| H&N | 46 | 69 | 0 | 22 | 33 |
| My Bullet | 7 | 0 | 7 | 7 | 7 |
| NSA | 117 | 113 | 4 | 0 | 1 |
| RWS | 44 | 0 | 44 | 22 | 0 |
| Zan Projectiles | 89 | 62 | 27 | 27 | 81 |
