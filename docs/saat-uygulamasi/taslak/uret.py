#!/usr/bin/env python3
"""Saat ekran taslaklarını (SVG) üretir.

Yalnızca görsel taslak: uygulama koduna girmez. PNG'ler aynı SVG'lerden
tarayıcıyla (Chromium) çizilir; bkz. README.md.

Örnek değerler uydurmadır ve hiçbir hesaptan gelmez; yalnızca yerleşimi
göstermek içindir.
"""
from __future__ import annotations

from pathlib import Path

OUT = Path(__file__).resolve().parent

BG = "#000000"
INK = "#F2F5F7"
DIM = "#8DA0AE"
AMBER = "#E9A00C"
CYAN = "#5CC3E6"
WARN = "#E8590C"
FONT = "Inter, -apple-system, 'SF Pro', sans-serif"

# Örnek (uydurma) değerler.
PROFILE = "Tikka T3x .308"
RANGE = "600 m"
UP = "↑ 47"
UP_SUB = "4.7 MRAD"
RIGHT = "→ 6"
RIGHT_SUB = "0.6 MRAD"
UNIT = "MRAD · 0.1/klik"
WIND = "Rüzgâr 3.0 m/s · saat 3"
TIME = "Güncellendi 14:32"


def text(x, y, s, size, fill=INK, anchor="middle", weight=400, extra=""):
    return (
        f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
        f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" {extra}>{s}</text>'
    )


def apple(body: str, title: str) -> str:
    # Apple Watch 45 mm: 396 x 484 nokta; kasa çerçevesi yalnızca bağlam için.
    w, h = 396, 484
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{w + 40}" height="{h + 70}" viewBox="0 0 {w + 40} {h + 70}">
<title>{title}</title>
<rect x="0" y="0" width="{w + 40}" height="{h + 70}" fill="#1B1F23"/>
<rect x="20" y="20" width="{w}" height="{h}" rx="72" fill="{BG}" stroke="#3A4148" stroke-width="3"/>
<g transform="translate(20,20)">{body}</g>
{text((w + 40) / 2, h + 55, title, 15, DIM)}
</svg>
"""


def garmin(body: str, title: str) -> str:
    # Yuvarlak ekran (ör. 454 x 454 AMOLED); 260 px modeller için ölçek iner.
    d = 454
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{d + 60}" height="{d + 90}" viewBox="0 0 {d + 60} {d + 90}">
<title>{title}</title>
<rect x="0" y="0" width="{d + 60}" height="{d + 90}" fill="#1B1F23"/>
<circle cx="{30 + d / 2}" cy="{30 + d / 2}" r="{d / 2 + 14}" fill="#2A2F35"/>
<circle cx="{30 + d / 2}" cy="{30 + d / 2}" r="{d / 2}" fill="{BG}"/>
<g transform="translate(30,30)">{body}</g>
{text((d + 60) / 2, d + 75, title, 15, DIM)}
</svg>
"""


def apple_main() -> str:
    b = [
        text(198, 58, "14:32", 20, DIM),
        text(198, 100, PROFILE, 24),
        text(198, 140, RANGE, 30, CYAN),
        text(40, 210, "Yukarı", 18, DIM, "start"),
        text(356, 228, UP, 64, AMBER, "end"),
        text(356, 258, UP_SUB, 18, DIM, "end"),
        text(40, 312, "Sağ", 18, DIM, "start"),
        text(356, 330, RIGHT, 52, INK, "end"),
        text(356, 358, RIGHT_SUB, 18, DIM, "end"),
        text(198, 400, WIND, 18, DIM),
        text(198, 428, UNIT, 16, DIM),
        text(198, 456, TIME, 16, DIM),
    ]
    return apple("".join(b), "Apple Watch — ana ekran")


def apple_range() -> str:
    b = [
        text(198, 58, "14:33", 20, DIM),
        text(198, 110, "Hedef mesafesi", 22, DIM),
        text(198, 230, "650", 96, CYAN),
        text(198, 270, "m", 26, DIM),
        text(198, 320, "Digital Crown ile değiştirin", 17, DIM),
        '<rect x="48" y="350" width="140" height="64" rx="32" fill="#2A2F35"/>',
        text(118, 391, "Vazgeç", 20),
        '<rect x="208" y="350" width="140" height="64" rx="32" fill="#3D2C05"/>',
        text(278, 391, "Gönder", 20, AMBER),
        text(198, 452, "Hesap telefonda yapılır", 15, DIM),
    ]
    return apple("".join(b), "Apple Watch — saatten mesafe değiştirme")


def apple_stale() -> str:
    b = [
        text(198, 58, "14:41", 20, DIM),
        text(198, 100, PROFILE, 24),
        text(198, 140, RANGE, 30, DIM),
        text(40, 210, "Yukarı", 18, DIM, "start"),
        text(356, 228, UP, 64, DIM, "end"),
        text(40, 312, "Sağ", 18, DIM, "start"),
        text(356, 330, RIGHT, 52, DIM, "end"),
        '<rect x="28" y="378" width="340" height="62" rx="16" fill="#3A1A08"/>',
        text(198, 404, "Veri eski (9 dk)", 18, WARN),
        text(198, 428, "Telefonda çözümü açın", 16, WARN),
        text(198, 462, TIME, 16, DIM),
    ]
    return apple("".join(b), "Apple Watch — eski veri / telefon yok")


def garmin_main() -> str:
    c = 227
    b = [
        text(c, 70, "14:32", 22, DIM),
        text(c, 112, PROFILE, 26),
        text(c, 152, RANGE, 32, CYAN),
        text(130, 210, "Yukarı", 20, DIM),
        text(130, 270, UP, 60, AMBER),
        text(130, 302, UP_SUB, 18, DIM),
        f'<line x1="{c}" y1="190" x2="{c}" y2="310" stroke="#2A2F35" stroke-width="2"/>',
        text(324, 210, "Sağ", 20, DIM),
        text(324, 270, RIGHT, 60, INK),
        text(324, 302, RIGHT_SUB, 18, DIM),
        text(c, 350, WIND, 19, DIM),
        text(c, 378, UNIT, 17, DIM),
        text(c, 406, TIME, 17, DIM),
    ]
    return garmin("".join(b), "Garmin (yuvarlak) — ana ekran")


def garmin_range() -> str:
    c = 227
    b = [
        text(c, 100, "Hedef mesafesi", 24, DIM),
        f'<path d="M{c - 18} 150 L{c} 128 L{c + 18} 150" fill="none" stroke="{DIM}" stroke-width="4"/>',
        text(c, 255, "650", 100, CYAN),
        text(c, 295, "m", 26, DIM),
        f'<path d="M{c - 18} 318 L{c} 340 L{c + 18} 318" fill="none" stroke="{DIM}" stroke-width="4"/>',
        text(c, 378, "Yukarı/aşağı tuşları · Başlat: gönder", 17, DIM),
        text(c, 404, "Hesap telefonda yapılır", 16, DIM),
    ]
    return garmin("".join(b), "Garmin — saatten mesafe değiştirme")


def garmin_stale() -> str:
    c = 227
    b = [
        text(c, 70, "14:41", 22, DIM),
        text(c, 112, PROFILE, 26),
        text(c, 152, RANGE, 32, DIM),
        text(130, 270, UP, 60, DIM),
        text(324, 270, RIGHT, 60, DIM),
        f'<rect x="72" y="320" width="310" height="66" rx="18" fill="#3A1A08"/>',
        text(c, 348, "Veri eski (9 dk)", 20, WARN),
        text(c, 374, "Telefonda çözümü açın", 17, WARN),
        text(c, 412, TIME, 17, DIM),
    ]
    return garmin("".join(b), "Garmin — eski veri / telefon yok")


SCREENS = {
    "apple-watch-ana.svg": apple_main,
    "apple-watch-mesafe.svg": apple_range,
    "apple-watch-eski-veri.svg": apple_stale,
    "garmin-ana.svg": garmin_main,
    "garmin-mesafe.svg": garmin_range,
    "garmin-eski-veri.svg": garmin_stale,
}


def main() -> None:
    for name, fn in SCREENS.items():
        (OUT / name).write_text(fn(), encoding="utf-8")
        print(name)


if __name__ == "__main__":
    main()
