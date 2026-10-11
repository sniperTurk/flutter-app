// SNIPER TÜRK — Garmin Connect IQ saat uygulaması (prototip).
// Telefondaki Atış çözümünü gösterir; balistik hesap YAPMAZ (tek doğru
// kaynak telefondur). Mesaj şeması v1: lib/services/watch/watch_solution.dart.
import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class SniperTurkApp extends Application.AppBase {
    // Son geçerli çözüm (yoksa null).
    var solution = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        var saved = Application.Storage.getValue("solution");
        if (saved instanceof Dictionary) {
            solution = Solution.fromMessage(saved);
        }
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    function onStop(state) {
    }

    // Telefondan gelen çözüm. Geçersiz mesaj yok sayılır: yanlış sayı
    // göstermektense eski geçerli çözüm (eskime uyarısıyla) kalır.
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        var data = msg.data;
        if (data instanceof Dictionary) {
            var s = Solution.fromMessage(data);
            if (s != null) {
                solution = s;
                Application.Storage.setValue("solution", data);
                WatchUi.requestUpdate();
            }
        }
    }

    function getInitialView() {
        return [new MainView(), new MainDelegate()];
    }
}

function getSniperTurkApp() as SniperTurkApp {
    return Application.getApp() as SniperTurkApp;
}
