#!/usr/bin/env python3
"""Ö4/Ö6 taslak görselleri (yalnız tasarım önizlemesi; uygulama kodu değil).

Çalıştırma: python3 docs/barometre-dogrulama/taslak/uret.py
Renkler lib/ui/menzil_theme.dart açık temasından; yazı Oswald.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONTS = HERE.parents[2] / "assets" / "fonts"
S = 2  # ölçek
W = 390 * S

BG, SURFACE, SURFACE2 = "#E6ECEF", "#F7FAFB", "#DBE4E9"
INK, INK2, LINE = "#0F2230", "#465D6F", "#BCCAD3"
AMBER, CYAN, CYAN_SOFT, AMBER_SOFT = "#E9A00C", "#1C8FB5", "#CBE7F1", "#F7E6BD"


def font(size: int, weight: str = "Regular") -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"Oswald-{weight}.ttf"), size * S)


class Page:
    def __init__(self, title: str, height: int):
        self.img = Image.new("RGB", (W, height * S), BG)
        self.d = ImageDraw.Draw(self.img)
        self.y = 0
        self.d.rectangle([0, 0, W, 56 * S], fill=SURFACE)
        self.d.text((16 * S, 16 * S), "‹  " + title, font=font(20, "Medium"), fill=INK)
        self.y = 68

    def header(self, text: str):
        self.d.text((16 * S, self.y * S), text.upper(), font=font(13, "Medium"), fill=INK2)
        self.y += 24

    def _box(self, x0, w, label, value, unit=None, select=False):
        y = self.y
        self.d.text((x0 * S, y * S), label, font=font(13), fill=INK2)
        lw = self.d.textlength(label, font=font(13)) / S
        cx, cy = x0 + lw + 10, y + 9
        self.d.ellipse([(cx - 7) * S, (cy - 7) * S, (cx + 7) * S, (cy + 7) * S], outline=CYAN, width=S)
        self.d.text(((cx - 2) * S, (cy - 9) * S), "i", font=font(12), fill=CYAN)
        self.d.rounded_rectangle([x0 * S, (y + 22) * S, (x0 + w) * S, (y + 66) * S], 8 * S,
                                 fill=SURFACE, outline=LINE, width=S)
        self.d.text(((x0 + 12) * S, (y + 31) * S), value, font=font(17), fill=INK)
        if unit:
            uw = self.d.textlength(unit, font=font(14)) / S
            self.d.text(((x0 + w - 12 - uw) * S, (y + 34) * S), unit, font=font(14), fill=INK2)
        if select:
            tx, ty = x0 + w - 26, y + 40
            self.d.polygon([(tx * S, ty * S), ((tx + 12) * S, ty * S), ((tx + 6) * S, (ty + 7) * S)], fill=INK2)

    def row(self, *boxes):
        gap, n = 12, len(boxes)
        w = (390 - 32 - gap * (n - 1)) / n
        for i, b in enumerate(boxes):
            self._box(16 + i * (w + gap), w, *b)
        self.y += 78

    def select(self, label, value):
        self._box(16, 358, label, value, select=True)
        self.y += 78

    def button(self, text, primary=False):
        fill, ink = (AMBER, "#1B1200") if primary else (SURFACE, INK)
        self.d.rounded_rectangle([16 * S, self.y * S, 374 * S, (self.y + 46) * S], 10 * S,
                                 fill=fill, outline=None if primary else LINE, width=S)
        tw = self.d.textlength(text, font=font(16, "Medium")) / S
        self.d.text(((195 - tw / 2) * S, (self.y + 11) * S), text, font=font(16, "Medium"), fill=ink)
        self.y += 58

    def notice(self, text, warn=False, lines=2):
        h = 18 + 20 * lines
        self.d.rounded_rectangle([16 * S, self.y * S, 374 * S, (self.y + h) * S], 8 * S,
                                 fill=AMBER_SOFT if warn else CYAN_SOFT)
        self.d.multiline_text((28 * S, (self.y + 9) * S), text, font=font(14), fill=INK, spacing=4 * S)
        self.y += h + 12

    def metrics(self, pairs, cols=2):
        w = (358 - 8 * (cols - 1)) / cols
        for i, (k, v) in enumerate(pairs):
            r, c = divmod(i, cols)
            x, y = 16 + c * (w + 8), self.y + r * 62
            self.d.rounded_rectangle([x * S, y * S, (x + w) * S, (y + 54) * S], 8 * S, fill=SURFACE)
            self.d.text(((x + 10) * S, (y + 6) * S), k, font=font(12), fill=INK2)
            self.d.text(((x + 10) * S, (y + 24) * S), v, font=font(18, "Medium"), fill=INK)
        self.y += 62 * ((len(pairs) + cols - 1) // cols) + 6

    def save(self, name):
        self.img = self.img.crop((0, 0, W, (self.y + 16) * S))
        self.img.save(HERE / name)


def hava_durumu():
    p = Page("Hava Durumu", 900)
    p.header("Atmosfer")
    p.row(("Sıcaklık", "18,5", "°C"), ("Basınç", "912,4", "hPa"))
    p.row(("Nem", "55", "%"), ("İrtifa", "900", "m"))
    p.notice("Basınç telefondan alındı: 912,4 hPa.", lines=1)
    p.button("Konumdan canlı hava verisi al")
    p.button("Basıncı telefondan al")
    p.notice("Okunamazsa: Basınç okunamadı; elle girin.", warn=True, lines=1)
    p.save("01_hava_durumu_basinc.png")


def dogrulama_giris():
    p = Page("Hız Doğrulama", 1200)
    p.notice("Sıfırdan uzak en az 3 mesafede grup atın. Uygulama\n"
             "Mach bantlarına göre sürüklenme ölçeğini bulur.", lines=2)
    p.select("Doğrulanacak değer", "Sürüklenme eğrisi")
    p.header("1 · Gözlem")
    p.row(("Mesafe 1", "500", "m"), ("Düzeltme 1", "3,10", "MRAD"))
    p.row(("Mesafe 2", "700", "m"), ("Düzeltme 2", "5,20", "MRAD"))
    p.row(("Mesafe 3", "900", "m"), ("Düzeltme 3", "7,90", "MRAD"))
    p.button("Mesafe ekle")
    p.header("2 · Atış anındaki hava")
    p.row(("Sıcaklık", "15", "°C"), ("Basınç", "1013,25", "hPa"))
    p.row(("Nem", "50", "%"))
    p.button("Eğriyi hesapla", primary=True)
    p.save("02_dogrulama_cok_mesafe.png")


def dogrulama_sonuc():
    p = Page("Hız Doğrulama", 1200)
    p.header("3 · Sonuç")
    p.metrics([("Mach 2 üstü", "değişmedi"), ("Mach 1,5–2", "+2,8 %"),
               ("Mach 1,2–1,5", "+1,3 %"), ("Mach 1,2 altı", "değişmedi")])
    p.header("Kalan fark · önce / sonra, MRAD")
    p.metrics([("500 m", "0,02 / 0,00"), ("700 m", "0,05 / 0,01"),
               ("900 m", "0,16 / 0,01")], cols=3)
    p.button("Sürüklenme eğrisini mühimmata kaydet")
    p.save("03_dogrulama_sonuc.png")


if __name__ == "__main__":
    hava_durumu()
    dogrulama_giris()
    dogrulama_sonuc()
