import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Ana ekran (taslak: docs/saat-uygulamasi/taslak/garmin-ana.png).
// Koyu zemin, kalın yazı yok; turuncu = yukarı/aşağı, açık mavi = mesafe.
const COLOR_AMBER = 0xE9A00C;
const COLOR_CYAN = 0x5CC3E6;
const COLOR_DIM = 0x8DA0AE;
const COLOR_WARN = 0xE8590C;

class MainView extends WatchUi.View {
    // Ekran görünürken 30 sn'de bir yeniden çiz: saat ve 2 dakikalık
    // eskime uyarısı tuşa basılmadan da güncel kalsın.
    var refreshTimer = null;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        refreshTimer = new Timer.Timer();
        refreshTimer.start(method(:onRefresh), 30000, true);
    }

    function onHide() as Void {
        if (refreshTimer != null) {
            refreshTimer.stop();
            refreshTimer = null;
        }
    }

    function onRefresh() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var s = getSniperTurkApp().solution;
        if (s == null) {
            message(dc, cx, h, "Telefon bekleniyor", "Telefonda Atış sekmesini açın");
            return;
        }
        if (!s.ok) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 22 / 100, Graphics.FONT_SMALL, s.profile, Graphics.TEXT_JUSTIFY_CENTER);
            message(dc, cx, h, "Çözüm yok", "Telefonda hesaplayın");
            return;
        }
        var stale = Format.staleNotice(s.atSec);
        var fresh = stale == null;

        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 10 / 100, Graphics.FONT_XTINY, Format.clock(Time.now().value()), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 18 / 100, Graphics.FONT_SMALL, s.profile, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(fresh ? COLOR_CYAN : COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 27 / 100, Graphics.FONT_MEDIUM, s.range.toString() + " " + s.rangeUnit, Graphics.TEXT_JUSTIFY_CENTER);

        // Dikey yerleşim yazı tipi yüksekliklerinden hesaplanır: sabit yüzdeler
        // fenix 7'de klik rakamlarıyla açı yazısını üst üste bindiriyordu.
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var lx = cx - w * 21 / 100;
        var rx = cx + w * 21 / 100;
        var top = h * 39 / 100;
        var bottom = column(dc, lx, top, Format.elevationLabel(s.up), s.up, true,
               Format.angle(s.upAngle, s.unit), fresh ? COLOR_AMBER : COLOR_DIM);
        column(dc, rx, top, Format.windageLabel(s.right), s.right, false,
               Format.angle(s.rightAngle, s.unit), fresh ? Graphics.COLOR_WHITE : COLOR_DIM);
        dc.setColor(0x2A2F35, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, top, cx, bottom);

        var rowY = bottom + 2;
        var minRow = h * 68 / 100;
        if (rowY < minRow) {
            rowY = minRow;
        }
        var lastRow = h * 92 / 100 - xh;

        if (!fresh) {
            dc.setColor(COLOR_WARN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, rowY, Graphics.FONT_XTINY, stale, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, rowY + xh, Graphics.FONT_XTINY, "Telefonda çözümü açın", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        var windText = Format.wind(s.windSpeed, s.windUnit, s.windClock);
        if (windText != null) {
            dc.drawText(cx, rowY, Graphics.FONT_XTINY, windText, Graphics.TEXT_JUSTIFY_CENTER);
            rowY += xh;
        }
        dc.drawText(cx, rowY, Graphics.FONT_XTINY, Format.unitLine(s.unit, s.click), Graphics.TEXT_JUSTIFY_CENTER);
        rowY += xh;
        // Yuvarlak ekranın altına sığmazsa güncelleme satırı atlanır.
        if (rowY <= lastRow) {
            dc.drawText(cx, rowY, Graphics.FONT_XTINY, Format.updated(s.atSec), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Bir kule sütunu: etiket, yön üçgeni + klik, açı. Alt kenarı döner.
    private function column(dc, x, top, label, clicks, vertical, detail, color) {
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var nh = dc.getFontHeight(Graphics.FONT_NUMBER_MILD);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, top, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var y = top + xh;
        dc.drawText(x + 8, y, Graphics.FONT_NUMBER_MILD, Format.clicks(clicks), Graphics.TEXT_JUSTIFY_LEFT);
        arrow(dc, x - 4, y + nh / 2, clicks, vertical);
        var detailY = y + nh;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, detailY, Graphics.FONT_XTINY, detail, Graphics.TEXT_JUSTIFY_CENTER);
        return detailY + xh;
    }

    // Yön üçgeni (yazı tipine bağlı ok karakteri kullanılmaz).
    private function arrow(dc, x, y, clicks, vertical) {
        var a = 9;
        if (vertical) {
            if (clicks < 0) {
                dc.fillPolygon([[x - a, y - a], [x + a, y - a], [x, y + a]]);
            } else {
                dc.fillPolygon([[x - a, y + a], [x + a, y + a], [x, y - a]]);
            }
        } else {
            if (clicks < 0) {
                dc.fillPolygon([[x + a, y - a], [x + a, y + a], [x - a, y]]);
            } else {
                dc.fillPolygon([[x - a, y - a], [x - a, y + a], [x + a, y]]);
            }
        }
    }

    private function message(dc, cx, h, title, detail) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 40 / 100, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 52 / 100, Graphics.FONT_XTINY, detail, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class MainDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Başlat/Seç: mesafe değiştirme ekranı.
    function onSelect() as Boolean {
        var s = getSniperTurkApp().solution;
        if (s == null || !s.ok) {
            return false;
        }
        var view = new RangeView(s.range, s.rangeStep, s.rangeUnit);
        WatchUi.pushView(view, new RangeDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}
