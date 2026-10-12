import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Saatten mesafe isteği (taslak: garmin-mesafe.png). Saat yalnızca ister;
// hesabı telefon yapar ve yeni çözümü geri gönderir.
class RangeView extends WatchUi.View {
    var value;
    var step;
    var unit;
    var status = null;

    function initialize(start, rangeStep, rangeUnit) {
        View.initialize();
        value = start;
        step = rangeStep;
        unit = rangeUnit;
    }

    function change(delta) {
        value = Format.stepped(value, delta, step);
        status = null;
        WatchUi.requestUpdate();
    }

    function setStatus(text) {
        status = text;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 18 / 100, Graphics.FONT_SMALL, "Hedef mesafesi", Graphics.TEXT_JUSTIFY_CENTER);
        dc.fillPolygon([[cx - 10, h * 33 / 100], [cx + 10, h * 33 / 100], [cx, h * 28 / 100]]);
        dc.setColor(COLOR_CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 50 / 100, Graphics.FONT_NUMBER_HOT, value.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 62 / 100, Graphics.FONT_SMALL, unit, Graphics.TEXT_JUSTIFY_CENTER);
        dc.fillPolygon([[cx - 10, h * 72 / 100], [cx + 10, h * 72 / 100], [cx, h * 77 / 100]]);
        if (status != null) {
            dc.setColor(COLOR_WARN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 80 / 100, Graphics.FONT_XTINY, status, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(cx, h * 80 / 100, Graphics.FONT_XTINY, "Başlat: gönder", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class RangeDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(rangeView) {
        BehaviorDelegate.initialize();
        view = rangeView;
    }

    // Yukarı tuşu.
    function onPreviousPage() as Boolean {
        view.change(1);
        return true;
    }

    // Aşağı tuşu.
    function onNextPage() as Boolean {
        view.change(-1);
        return true;
    }

    function onSelect() as Boolean {
        view.setStatus("Gönderiliyor");
        Communications.transmit({"type" => "setRange", "value" => view.value}, null, new RangeSendListener(view));
        return true;
    }
}

class RangeSendListener extends Communications.ConnectionListener {
    var view;

    function initialize(rangeView) {
        ConnectionListener.initialize();
        view = rangeView;
    }

    function onComplete() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onError() as Void {
        view.setStatus("Telefona ulaşılamadı");
    }
}
