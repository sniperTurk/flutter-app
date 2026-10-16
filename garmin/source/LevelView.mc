import Toybox.Attention;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Atış terazisi: saat raya aparatla takılı, yatıklığı ve atış açısını
// ivmeölçerden gösterir. Düz olunca bir kez titreşir. "Açıyı gönder"
// açıyı telefona yollar (setRange gibi tek mesaj, sürekli akış yok).
class LevelView extends WatchUi.View {
    var timer = null;
    var mount;
    var cantOffset;
    var angleOffset;
    // Süzülmüş ivme (null: henüz veri yok).
    var fx = null;
    var fy = null;
    var fz = null;
    // Ölçüm dinleyicisinin son örneği (getInfo ivme vermezse).
    var lastSample = null;
    var rawCant = 0.0;
    var rawAngle = 0.0;
    var cant = 0.0;
    var angle = 0.0;
    var level = false;
    var armed = true;
    var status = null;
    // Durum yazısı bu kadar ölçüm sonra silinir (yaklaşık 3 sn).
    var statusTicks = 0;
    // Sıfırla onaylandı: ekran yeniden açılıp ölçüm oturunca uygulanır.
    var pendingReset = false;
    // Ekran açıldığından beri ölçüm sayısı (süzgeç oturması için).
    var ticksShown = 0;

    function initialize() {
        View.initialize();
        mount = Level.loadMount();
        var o = Level.loadOffsets();
        cantOffset = o[0];
        angleOffset = o[1];
    }

    function onShow() as Void {
        // Bazı saatler ivmeölçeri ancak bir dinleyici kaydedilince açar.
        if (Sensor has :registerSensorDataListener) {
            try {
                Sensor.registerSensorDataListener(method(:onSensorData),
                    {:period => 1, :accelerometer => {:enabled => true, :sampleRate => 10}});
            } catch (e) {
                // Ölçüm yine getInfo ile denenir.
            }
        }
        ticksShown = 0;
        if (timer != null) {
            timer.stop();
        }
        timer = new Timer.Timer();
        timer.start(method(:onTick), Level.SAMPLE_MS, true);
    }

    function onHide() as Void {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
        if (Sensor has :unregisterSensorDataListener) {
            Sensor.unregisterSensorDataListener();
        }
    }

    function onSensorData(data) as Void {
        var a = data.accelerometerData;
        if (a != null && a.x != null && a.x.size() > 0) {
            var n = a.x.size() - 1;
            lastSample = [a.x[n], a.y[n], a.z[n]];
        }
    }

    function onTick() as Void {
        var a = Sensor.getInfo().accel;
        if (a == null) {
            a = lastSample;
        }
        if (a == null || a.size() < 3) {
            WatchUi.requestUpdate();
            return;
        }
        if (fx == null) {
            fx = a[0].toFloat();
            fy = a[1].toFloat();
            fz = a[2].toFloat();
        } else {
            fx = fx + (a[0] - fx) * Level.LP_K;
            fy = fy + (a[1] - fy) * Level.LP_K;
            fz = fz + (a[2] - fz) * Level.LP_K;
        }
        var r = Level.angles(fx, fy, fz, mount);
        rawCant = r[0];
        rawAngle = r[1];
        ticksShown += 1;
        // Menüdeyken ölçüm durur: sıfır, menü kapandıktan ve süzgeç
        // oturduktan sonraki taze ölçümden alınır (yaklaşık 1 sn).
        if (pendingReset && ticksShown >= Level.SETTLE_TICKS) {
            pendingReset = false;
            cantOffset = rawCant;
            angleOffset = rawAngle;
            Level.saveOffsets(cantOffset, angleOffset);
            armed = true;
            setStatus("Sıfırlandı");
        }
        if (statusTicks > 0) {
            statusTicks -= 1;
            if (statusTicks == 0 && !pendingReset) {
                status = null;
            }
        }
        cant = rawCant - cantOffset;
        angle = rawAngle - angleOffset;
        updateLevel();
        WatchUi.requestUpdate();
    }

    // Düz olunca bir kez titreşim; çıkıp yeniden düzelince yine bir kez.
    private function updateLevel() {
        var c = cant.abs();
        if (c <= Level.LEVEL_DEG) {
            if (!level && armed) {
                feedback();
                armed = false;
            }
            level = true;
        } else {
            level = false;
            if (c > Level.REARM_DEG) {
                armed = true;
            }
        }
    }

    // Saatin kendi titreşim ve ses ayarlarına uyar.
    private function feedback() {
        var ds = System.getDeviceSettings();
        if ((Attention has :vibrate) && ds.vibrateOn) {
            Attention.vibrate([new Attention.VibeProfile(50, 150)]);
        }
        if ((Attention has :playTone) && ds.tonesOn) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }

    function hasData() {
        return fx != null;
    }

    // Sıfırla: tüfek düz ve yatayken o anki yatıklık ve açı 0 olur.
    function reset() {
        pendingReset = true;
        status = "Sıfırlanıyor";
        statusTicks = 0;
        WatchUi.requestUpdate();
    }

    function toggleMount() {
        mount = mount == Level.MOUNT_UPRIGHT ? Level.MOUNT_FACE_UP : Level.MOUNT_UPRIGHT;
        Level.saveMount(mount);
        cantOffset = 0.0;
        angleOffset = 0.0;
        fx = null;
        setStatus("Takma değişti: Sıfırla");
    }

    function sendAngle() {
        if (!hasData()) {
            setStatus("Sensör verisi yok");
            return;
        }
        // Aparat payı sıfırlanmadan ölçülen açı yanlış olur.
        if (!Level.isCalibrated() || pendingReset) {
            setStatus("Önce Sıfırla");
            return;
        }
        var v = Math.round(angle * 10.0) / 10.0;
        if (v.abs() > Level.MAX_SEND_DEG) {
            setStatus("Açı 60° dışında");
            return;
        }
        setStatus("Gönderiliyor");
        Communications.transmit({"type" => "setAngle", "value" => v}, null, new AngleSendListener(self));
    }

    function setStatus(text) {
        status = text;
        statusTicks = Level.STATUS_TICKS;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 10 / 100, Graphics.FONT_XTINY,
                    mount == Level.MOUNT_UPRIGHT ? "Terazi, dik" : "Terazi, ekran yukarı",
                    Graphics.TEXT_JUSTIFY_CENTER);
        if (!hasData()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 45 / 100, Graphics.FONT_SMALL, "Sensör bekleniyor", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        var color = level ? COLOR_CYAN : COLOR_AMBER;

        // Tüfeğin kendi yatayı: iki sabit çentik. Su terazisi çizgisi gerçek
        // yatayı gösterir; düzken çentiklerle aynı hizadadır.
        var ly = h * 33 / 100;
        var len = w * 30 / 100;
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - len - 12, ly - 1, 8, 3);
        dc.fillRectangle(cx + len + 4, ly - 1, 8, 3);
        var rad = Math.toRadians(cant);
        var dx = len * Math.cos(rad);
        var dy = len * Math.sin(rad);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine((cx - dx).toNumber(), (ly + dy).toNumber(), (cx + dx).toNumber(), (ly - dy).toNumber());
        dc.setPenWidth(1);

        var cantText = level ? "düz" : Format.deg(cant) + (cant > 0 ? " sağ" : " sol");
        dc.drawText(cx, h * 41 / 100, Graphics.FONT_MEDIUM, cantText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 58 / 100, Graphics.FONT_SMALL, "Açı " + Format.signedDeg(angle), Graphics.TEXT_JUSTIFY_CENTER);

        var y = h * 74 / 100;
        if (status != null) {
            dc.setColor(COLOR_WARN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, status, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY,
                        Level.isCalibrated() ? "Başlat: açıyı gönder" : "Önce Sıfırla",
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y + xh, Graphics.FONT_XTINY, "Aşağı: Sıfırla, takma", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class LevelDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(levelView) {
        BehaviorDelegate.initialize();
        view = levelView;
    }

    // Başlat: açıyı gönder.
    function onSelect() as Boolean {
        view.sendAngle();
        return true;
    }

    // Aşağı tuşu veya menü: Sıfırla ve takma şekli.
    function onNextPage() as Boolean {
        return openMenu();
    }

    function onMenu() as Boolean {
        return openMenu();
    }

    private function openMenu() {
        var menu = new WatchUi.Menu2({:title => "Terazi"});
        menu.addItem(new WatchUi.MenuItem("Sıfırla", "Tüfek düz ve yatay", :reset, null));
        menu.addItem(new WatchUi.MenuItem("Takma şekli",
            view.mount == Level.MOUNT_UPRIGHT ? "Dik, ekran size" : "Ekran yukarı", :mount, null));
        WatchUi.pushView(menu, new LevelMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}

class LevelMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;

    function initialize(levelView) {
        Menu2InputDelegate.initialize();
        view = levelView;
    }

    function onSelect(item) as Void {
        var id = item.getId();
        if (id == :reset) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new WatchUi.Confirmation("Tüfek düz ve yatay mı?"),
                             new LevelResetDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :mount) {
            view.toggleMount();
            item.setSubLabel(view.mount == Level.MOUNT_UPRIGHT ? "Dik, ekran size" : "Ekran yukarı");
            WatchUi.requestUpdate();
        }
    }
}

class LevelResetDelegate extends WatchUi.ConfirmationDelegate {
    var view;

    function initialize(levelView) {
        ConfirmationDelegate.initialize();
        view = levelView;
    }

    function onResponse(response) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            view.reset();
        }
        return true;
    }
}

class AngleSendListener extends Communications.ConnectionListener {
    var view;

    function initialize(levelView) {
        ConnectionListener.initialize();
        view = levelView;
    }

    function onComplete() as Void {
        view.setStatus("Açı gönderildi");
    }

    function onError() as Void {
        view.setStatus("Telefona ulaşılamadı");
    }
}
