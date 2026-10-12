import Toybox.Lang;

// Telefonun çözüm mesajı (şema v1). Yalnızca taşır; hesap yapmaz.
class Solution {
    var ok = false;
    var profile = "";
    var atSec = 0;          // saniye (telefon milisaniye gönderir)
    var range = 0;
    var rangeUnit = "m";
    var rangeStep = 10;
    var up = 0;             // + yukarı, - aşağı (klik)
    var right = 0;          // + sağ, - sol (klik)
    var upAngle = 0.0;
    var rightAngle = 0.0;
    var unit = "MRAD";
    var click = 0.0;
    var windSpeed = null;
    var windUnit = null;
    var windClock = null;

    function initialize() {
    }

    // Bilinmeyen sürüm veya eksik alan: null.
    static function fromMessage(m as Dictionary) {
        if (Solution.toNum(m.get("v")) != 1) {
            return null;
        }
        // iPhone (Connect IQ Mobile SDK) bool'u Boolean veya 0/1 sayı olarak
        // gelebilir; ikisi de kabul edilir.
        var ok = Solution.toBool(m.get("ok"));
        var profile = m.get("profile");
        var atMs = m.get("at");
        if (ok == null || !(profile instanceof String)) {
            return null;
        }
        if (!(atMs instanceof Number) && !(atMs instanceof Long)) {
            return null;
        }
        var s = new Solution();
        s.ok = ok;
        s.profile = profile;
        s.atSec = (atMs.toLong() / 1000).toNumber();
        if (!ok) {
            return s;
        }
        var range = Solution.toNum(m.get("range"));
        var step = Solution.toNum(m.get("rangeStep"));
        var up = Solution.toNum(m.get("up"));
        var right = Solution.toNum(m.get("right"));
        var upAngle = Solution.toFlt(m.get("upAngle"));
        var rightAngle = Solution.toFlt(m.get("rightAngle"));
        var click = Solution.toFlt(m.get("click"));
        var rangeUnit = m.get("rangeUnit");
        var unit = m.get("unit");
        if (range == null || step == null || step <= 0 || up == null || right == null
                || upAngle == null || rightAngle == null || click == null
                || !(rangeUnit instanceof String) || !(unit instanceof String)) {
            return null;
        }
        s.range = range;
        s.rangeStep = step;
        s.up = up;
        s.right = right;
        s.upAngle = upAngle;
        s.rightAngle = rightAngle;
        s.click = click;
        s.rangeUnit = rangeUnit;
        s.unit = unit;
        s.windSpeed = Solution.toFlt(m.get("windSpeed"));
        var wu = m.get("windUnit");
        s.windUnit = (wu instanceof String) ? wu : null;
        s.windClock = Solution.toNum(m.get("windClock"));
        return s;
    }

    static function toBool(v) {
        if (v instanceof Boolean) {
            return v;
        }
        if (v instanceof Number || v instanceof Long) {
            return v != 0;
        }
        return null;
    }

    static function toNum(v) {
        if (v instanceof Number) {
            return v;
        }
        if (v instanceof Long) {
            return v.toNumber();
        }
        return null;
    }

    static function toFlt(v) {
        if (v instanceof Float || v instanceof Double) {
            return v.toFloat();
        }
        if (v instanceof Number || v instanceof Long) {
            return v.toFloat();
        }
        return null;
    }
}
