import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Saatte görünen Türkçe metinler (Apple Watch: watch/WatchCore ile aynı).
// Garmin yazı tiplerinde ok işaretleri olmayabileceği için yön, metin
// etiketi ve çizilen üçgenle gösterilir.
module Format {
    const STALE_AFTER_SEC = 120;

    function elevationLabel(clicks) {
        return clicks < 0 ? "Aşağı" : "Yukarı";
    }

    function windageLabel(clicks) {
        return clicks < 0 ? "Sol" : "Sağ";
    }

    function clicks(c) {
        return c.abs().toString();
    }

    // 4.70 -> "4.7", 0.25 -> "0.25", 0 -> "0.0"
    function decimal(v) {
        var s = v.abs().format("%.2f");
        while (s.length() > 3
                && s.substring(s.length() - 1, s.length()).equals("0")
                && !s.substring(s.length() - 2, s.length()).equals(".0")) {
            s = s.substring(0, s.length() - 1);
        }
        return s;
    }

    function angle(v, unit) {
        return decimal(v) + " " + unit;
    }

    // 1.2° (işaretsiz, 0,1° adım).
    function deg(v) {
        return v.abs().format("%.1f") + "°";
    }

    // +12.5° yukarı, -3.0° aşağı, 0.0° düz.
    function signedDeg(v) {
        var s = deg(v);
        if (s.equals("0.0°")) {
            return s;
        }
        return (v > 0 ? "+" : "-") + s;
    }

    function unitLine(unit, click) {
        return unit + ", " + decimal(click) + "/klik";
    }

    function wind(speed, unit, clock) {
        if (speed == null || unit == null || speed <= 0) {
            return null;
        }
        var s = "Rüzgâr " + speed.format("%.1f") + " " + unit;
        if (clock != null) {
            s = s + ", saat " + clock.toString();
        }
        return s;
    }

    // "14:32" (saatin yerel saati).
    function clock(atSec) {
        var info = Gregorian.info(new Time.Moment(atSec), Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function updated(atSec) {
        return "Güncellendi " + clock(atSec);
    }

    // null: veri taze.
    function staleNotice(atSec) {
        var age = Time.now().value() - atSec;
        if (age <= STALE_AFTER_SEC) {
            return null;
        }
        return "Veri eski (" + (age / 60).toString() + " dk)";
    }

    // En az bir adım, en çok 9999.
    function stepped(value, delta, step) {
        var s = step < 1 ? 1 : step;
        var v = value + delta * s;
        if (v < s) {
            v = s;
        }
        if (v > 9999) {
            v = 9999;
        }
        return v;
    }
}
