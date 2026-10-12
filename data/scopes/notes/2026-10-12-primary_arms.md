# Primary Arms — dürbün veri toplama raporu, 2. tur (2026-10-12)

**Yeni kayıt: 16** (mevcut kayıt yoktu). Kaynak: yalnız primaryarms.com (Primary Arms markalı ürün sayfaları).
WebFetch: 38 çağrı, her biri arasında ≥5 sn. 429 / PROVENANCE / izin hatası alınmadı.

## Eklenen modeller (model × taret birimi)
PLx (Compact PLxC): 1-8x24 FFP RDB; 1-8x24 SFP; 1.5-12x36 FFP RDB Gen II; 2.5-20x48 FFP; 4.5-36x56 FFP
SLx: 1-6x24 SFP Gen IV; 1-10x28 SFP (MOA taret); 2-12x40 SFP; 3-18x50 FFP Gen II; Compact 4-16x44 FFP; 4.5-27x56 FFP
GLx: 4.5-27x56 FFP; 3-18x44 FFP
CLx/Classic (görevde istenen PLx/GLx/SLx dışında ama PA markalı tüfek dürbünü; istenmezse silinebilir): CLx 1-6x24 SFP; Classic Series 3-9x44 SFP; Classic Series 6x32
Tüm PLx/GLx/SLx kayıtları MRAD (0.1 Mil). İstisna SLx 1-10x28: MRAD retikül ama sayfada 0.5 MOA tık / 40 MOA ayar → MOA kaydı. Hiçbir model iki birimde satılmıyor.

## Önemli veri notları
- primaryarms.com, MRAD taretli dürbünlerin çoğunda toplam ayarı MOA cinsinden veriyor (ör. "0.1 Mil" tık + "100 MOA"). Bu değerler 1 MOA = 0.290888 mrad ile çevrilip `elevation/windage_travel_mrad` alanına yazıldı; her kayıtta not var.
- SLx Compact 4-16x44: taret aralığı varyant sayfaları arasında çelişkili (80 MOA/60 MOA vs 60 MIL/80 MOA) → ikisi de null.
- SLx 4.5-27x56: yan ayar, uzunluk ve ağırlık sayfada yok → null (yükseliş 32 MIL).
- PLxC 1-8x24 SFP: uzunluk (9.2 / 9.28 in) ve ağırlık (16.8 / 16.95 oz) çelişkili → null.
- SLx 3-18x50 ağırlık: bir tabloda 32.04 oz, diğer iki sayfada ve aynı sayfanın özelliklerinde 32.4 oz → 32.4 alındı (not var).
- Classic 6x32 odak düzlemi çelişkili → null. Classic 3-9x44 özellik listesinde "Objective: 31" hatası; 44 alındı.
- Tüp çapı birçok sayfada yalnız "Mount Compatibility" olarak veriliyor; o değer alındı ve notlandı.
- Paralaks yalnız "10 yards to infinity" yazan modellerde 9.1 m; diğerlerinde null. Zero stop yalnız "Easy Stop® return to zero" yazanlarda true (SLx 3-18x50, SLx 4.5-27x56, GLx 4.5-27x56, GLx 3-18x44); diğerleri null.
- Bazı retikül varyantları (PLxC 1-8 Raptor Meter G2; SLx 1-6 Nova 5.56/.308, Aurora Meter, Aurora 7.62x39) yalnız liste sayfalarından eklendi, ürün sayfaları okunmadı.

## Hariç tutulanlar
Prizma/MicroPrism (GLx 1x/2x, SLx 1x/3x/5x, SLx 3x32/5x36 Gen III, CLx 1x/3x); kit/bundle ürünler; REFURB/OPEN BOX/BLEM ürünler; yalnız open-box olarak görünen SLx HUNTER 3-9x50 ve 4-12x50 ile PLx 1-8x24 FFP (non-compact) — güncel ürün olarak listelenmiyor; "Special Purchase 1-6x24 SFP" (seri belirsiz, özel parti). Renk (FDE/yeşil) varyantları ayrı kayıt açılmadı.

## Kullanılan kaynak URL'leri
Liste: https://www.primaryarms.com/rifle-scopes/brand/primary-arms (sayfa 1–4), https://www.primaryarms.com/rifle-scopes/optic-series/glx, https://www.primaryarms.com/rifle-scopes/optic-series/plx, https://www.primaryarms.com/rifle-scopes/optic-series/slx (sayfa 1–3)
Ürün sayfaları (https://www.primaryarms.com/ + ):
- primary-arms-compact-plxc-1-8x24-ffp-rdb-riflescope-acss-raptor-yard-556-308-reticle
- primary-arms-compact-plxc-1-8x24-ffp-rdb-riflescope-acss-griffin-mil-g2-reticle
- primary-arms-compact-plxc-1-8x24-sfp-rifle-scope-illuminated-acss-nova-fiber-wire-reticle
- primary-arms-plxc-1-5-12x36mm-ffp-rdb-rifle-scope-illum-acss-griffin-mil-gen2
- primary-arms-plxc-1-5-12x36mm-ffp-rdb-rifle-scope-illum-acss-raptor-yard-556-gen2
- primary-arms-compact-plxc-2-5-20x48-ffp-rifle-scope-acss-athena-bpr-mil-g2-reticle
- primary-arms-compact-plxc-2-5-20x48-ffp-rifle-scope-illuminated-acss-deka-g2-reticle
- primary-arms-compact-plxc-4-5-36x56-ffp-rifle-scope-acss-deka-g2-reticle
- primary-arms-compact-plxc-4-5-36x56-ffp-rifle-scope-acss-neptune-reticle
- primary-arms-slx-1-6x24mm-sfp-rifle-scope-gen-4-illuminated-acss-nova-fiber-wire-reticle
- primary-arms-slx-1-6x24mm-sfp-rifle-scope-gen-4-illuminated-acss-aurora-556-yard-reticle
- primary-arms-slx-1-10x28mm-sfp-rifle-scope-illuminated-acss-nova-fiber-wire-reticle
- primary-arms-slx-1-10x-28mm-sfp-rifle-scope-illuminated-acss-griffin-m10s-reticle
- primary-arms-slx-2-12x40mm-sfp-rifle-scope-illuminated-acss-nova-fiber-wire-reticle
- primary-arms-slx-3-18x50-ffp-gen-2-rifle-scope-acss-apollo-308-6-5-grendel
- primary-arms-slx-3-18x50-ffp-gen-2-rifle-scope-acss-athena-bpr-mil-reticle
- primary-arms-slx-3-18x50-ffp-gen-2-rifle-scope-illuminated-hud-dmr-308-reticle
- pa-slx-compact-4-16x44mm-ffp-rifle-scope-illuminated-acss-athena-bpr-mil-reticle
- pa-slx-compact-4-16x44mm-ffp-rifle-scope-illuminated-acss-hud-dmr-308-223-reticle
- pa-slx-compact-4-16x44mm-ffp-rifle-scope-illuminated-acss-deka-g2-reticle
- pa-slx-4-5-27x56mm-ffp-rifle-scope-illum-acss-athena-bpr-mil-reticle
- pa-slx-4-5-27x56mm-ffp-rifle-scope-illum-acss-deka-g2-reticle
- primary-arms-glx-4-5x27-ffp-rifle-scope-acss-athena-bpr-mil-reticle
- primary-arms-glx-3-18x44-ffp-rifle-scope-acss-apollo-308-reticle
- primary-arms-clx-1-6x24mm-sfp-rifle-scope-acss-22lr-g2-reticle
- primary-arms-classic-series-1-6x24mm-sfp-rifle-scope-illuminated-duplex-reticle
- primary-arms-3-9x44-sfp-classic-rifle-scope-duplex-reticle
- primary-arms-6x-scope-with-the-patented-acss-22lr-reticle


## Ana oturum düzeltmeleri
Kural (çelişki/belirsiz → boş) gereği bazı alanlar null yapıldı; ilgili kayıtların notes alanında "Ana oturum düzeltmesi" olarak yazıyor.
