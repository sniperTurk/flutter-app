"""Garmin atış terazisi: garmin/source/Level.mc açı hesabının Python eşi.

Connect IQ SDK burada yok (Garmin lisansı), Monkey C derlenemez. Bu test
Level.angles formülünü birebir Python'da kurar, bilinen yerçekimi
vektörleriyle sınar ve Monkey C satırlarının aynı kaldığını kontrol eder.

Girdi Sensor ivmesidir (milli-g; saat dururken yukarıyı gösterir; x saat 3,
y saat 12, z ekrandan dışarı). Görevdeki "gravity (0,-1,0)" yerçekiminin
yönüdür; ivmeölçer bunun tersini okur: (0, +1000, 0).
"""
from __future__ import annotations

import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVEL = ROOT / "garmin" / "source" / "Level.mc"
LEVEL_VIEW = ROOT / "garmin" / "source" / "LevelView.mc"

UPRIGHT, FACE_UP = 0, 1


def angles(ax, ay, az, mount):
    """Level.angles (Level.mc) ile aynı: [yatıklık, eğim] derece."""
    right = -float(ax)
    if mount == FACE_UP:
        up = -float(az)
        back = float(ay)
    else:
        up = -float(ay)
        back = -float(az)
    cant = math.degrees(math.atan2(right, -up))
    angle = math.degrees(math.atan2(back, math.sqrt(right * right + up * up)))
    return cant, angle


def gravity_upright(cant_deg, angle_deg):
    """Dik takılı saatte yerçekimi yönü (birim): önce eğim, sonra namlu
    çevresinde yatıklık (+ = üst sağa)."""
    c, a = math.radians(cant_deg), math.radians(angle_deg)
    return (math.cos(a) * math.sin(c), -math.cos(a) * math.cos(c), math.sin(a))


def gravity_face_up(cant_deg, angle_deg):
    """Ekranı yukarı, saat 12'si namluya bakan saatte yerçekimi yönü."""
    c, a = math.radians(cant_deg), math.radians(angle_deg)
    return (math.cos(a) * math.sin(c), -math.sin(a), -math.cos(a) * math.cos(c))


def accel(gravity, scale=1000.0):
    """İvmeölçer okuması: yerçekiminin tersi, milli-g."""
    return tuple(-g * scale for g in gravity)


class LevelMath(unittest.TestCase):
    def check(self, mount, g, cant, angle, tol=0.1):
        got_cant, got_angle = angles(*accel(g), mount)
        self.assertAlmostEqual(got_cant, cant, delta=tol)
        self.assertAlmostEqual(got_angle, angle, delta=tol)

    def test_upright_known_vectors(self):
        # Görevdeki vektörler: yerçekimi (0,-1,0) -> 0 / 0.
        self.check(UPRIGHT, (0.0, -1.0, 0.0), 0.0, 0.0, tol=1e-9)
        # 10° yatık -> yatıklık 10, açı ~0.
        self.check(UPRIGHT, gravity_upright(10, 0), 10.0, 0.0)
        # Namlu 15° yukarı -> açı 15, yatıklık ~0.
        self.check(UPRIGHT, gravity_upright(0, 15), 0.0, 15.0)
        # Birlikte 10° / 15° -> ikisi de 0,1° içinde.
        self.check(UPRIGHT, gravity_upright(10, 15), 10.0, 15.0)

    def test_signs(self):
        # Üst sağa yatınca +, sola -; namlu aşağı -.
        self.assertGreater(angles(*accel(gravity_upright(3, 0)), UPRIGHT)[0], 0)
        self.assertLess(angles(*accel(gravity_upright(-3, 0)), UPRIGHT)[0], 0)
        self.assertLess(angles(*accel(gravity_upright(0, -8)), UPRIGHT)[1], 0)

    def test_cant_and_angle_independent_up_to_60(self):
        for cant in range(-60, 61, 5):
            for angle in range(-60, 61, 5):
                for mount, grav in ((UPRIGHT, gravity_upright), (FACE_UP, gravity_face_up)):
                    with self.subTest(mount=mount, cant=cant, angle=angle):
                        self.check(mount, grav(cant, angle), cant, angle, tol=1e-6)

    def test_scale_and_noise_free_magnitude_does_not_matter(self):
        # Milli-g ölçeği (ör. 980 ya da 1020) sonucu değiştirmez.
        g = gravity_upright(7.3, -12.4)
        for scale in (980.0, 1000.0, 1020.0):
            c, a = angles(*accel(g, scale), UPRIGHT)
            self.assertAlmostEqual(c, 7.3, delta=1e-9)
            self.assertAlmostEqual(a, -12.4, delta=1e-9)

    def test_face_up_known_vectors(self):
        self.check(FACE_UP, (0.0, 0.0, -1.0), 0.0, 0.0, tol=1e-9)
        self.check(FACE_UP, gravity_face_up(10, 15), 10.0, 15.0)

    def test_low_pass_factor_matches_phone_formula(self):
        # lib/core/low_pass.dart: k = 1 - e^(-dt/tau), dt 0,1 s, tau 0,25 s.
        src = LEVEL.read_text(encoding="utf-8")
        k = float(re.search(r"const LP_K = ([0-9.]+);", src).group(1))
        ms = int(re.search(r"const SAMPLE_MS = (\d+);", src).group(1))
        self.assertEqual(ms, 100)
        self.assertAlmostEqual(k, 1 - math.exp(-0.1 / 0.25), delta=0.005)


class LevelSourceMirror(unittest.TestCase):
    """Monkey C formülü bu dosyadaki Python eşiyle aynı kalmalı."""

    def test_monkey_c_formula_lines(self):
        src = LEVEL.read_text(encoding="utf-8")
        for line in (
            "var right = -ax.toFloat();",
            "up = -az.toFloat();",
            "back = ay.toFloat();",
            "up = -ay.toFloat();",
            "back = -az.toFloat();",
            "var cant = Math.toDegrees(Math.atan2(right, -up));",
            "var angle = Math.toDegrees(Math.atan2(back, Math.sqrt(right * right + up * up)));",
            "const LEVEL_DEG = 0.5;",
            "const MAX_SEND_DEG = 60.0;",
        ):
            self.assertIn(line, src)

    def test_level_view_feedback_and_message(self):
        src = LEVEL_VIEW.read_text(encoding="utf-8")
        self.assertIn('Communications.transmit({"type" => "setAngle", "value" => v}', src)
        self.assertIn("Math.round(angle * 10.0) / 10.0", src)
        # Tek titreşim, saatin ayarına uyarak; ton yalnızca ses açıksa.
        self.assertIn("(Attention has :vibrate) && ds.vibrateOn", src)
        self.assertIn("(Attention has :playTone) && ds.tonesOn", src)
        self.assertEqual(src.count("Attention.vibrate("), 1)
        self.assertIn("if (!level && armed)", src)
        # Sıfırlanmadan açı gönderilmez; sıfır taze ölçümden alınır.
        self.assertIn("if (!Level.isCalibrated() || pendingReset)", src)
        self.assertIn("if (pendingReset && ticksShown >= Level.SETTLE_TICKS)", src)
        # Sürekli akış yok: transmit yalnızca sendAngle içinde.
        self.assertEqual(src.count("Communications.transmit("), 1)


if __name__ == "__main__":
    unittest.main()
