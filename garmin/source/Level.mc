import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;

// Atış terazisi ve atış açısı: saat tüfeğe raya takılı bir aparatla bağlı.
// Saf hesap; tools/test_garmin_level_math.py aynı formülü bilinen
// vektörlerle sınar (iki dosya birlikte değişmeli).
module Level {
    // Dik: ekran atıcıya bakar (ekran namluya dik), saat 12 yukarı.
    const MOUNT_UPRIGHT = 0;
    // Ekran yukarı: saat yatay, saat 12 namluya doğru.
    const MOUNT_FACE_UP = 1;

    // |yatıklık| bu kadar veya azsa tüfek "düz".
    const LEVEL_DEG = 0.5;
    // Titreşim, yatıklık bunu geçip yeniden düzelince tekrar verilir
    // (sınırda titreyen ölçüm sürekli titreşim yapmasın).
    const REARM_DEG = 0.8;
    // Telefon bu aralığın dışındaki açıyı kabul etmez.
    const MAX_SEND_DEG = 60.0;

    // Birinci derece alçak geçiren süzgeç, telefondaki Su Terazisi ile aynı
    // biçim (lib/core/low_pass.dart): k = 1 - e^(-dt/tau); dt = 0,1 sn
    // (ölçüm aralığı), tau = 0,25 sn -> k = 0,33.
    const SAMPLE_MS = 100;
    const LP_K = 0.33;
    // Sıfırla, ekran açıldıktan bu kadar ölçüm sonra uygulanır (1 sn;
    // süzgeç 0,25 sn'lik zaman sabitinin 4 katında oturur).
    const SETTLE_TICKS = 10;
    // Durum yazısı (ör. "Açı gönderildi") 3 sn görünür.
    const STATUS_TICKS = 30;

    // ax, ay, az: Sensor ivmesi (milli-g; saat dururken yukarıyı gösterir;
    // x saat 3, y saat 12, z ekrandan dışarı). Döner: [yatıklık, eğim],
    // derece. Yatıklık + = tüfeğin üstü sağa (atıcıdan bakınca saat yönü),
    // eğim + = namlu yukarı. Önce eğim, sonra namlu ekseni çevresinde
    // yatıklık: ikisi birbirine karışmaz.
    function angles(ax, ay, az, mount) {
        // Yerçekimi yönü tüfeğin eksenlerinde: sağ, yukarı, geri.
        var right = -ax.toFloat();
        var up;
        var back;
        if (mount == MOUNT_FACE_UP) {
            up = -az.toFloat();
            back = ay.toFloat();
        } else {
            up = -ay.toFloat();
            back = -az.toFloat();
        }
        var cant = Math.toDegrees(Math.atan2(right, -up));
        var angle = Math.toDegrees(Math.atan2(back, Math.sqrt(right * right + up * up)));
        return [cant, angle];
    }

    function loadMount() {
        var m = Application.Storage.getValue("levelMount");
        return m == MOUNT_FACE_UP ? MOUNT_FACE_UP : MOUNT_UPRIGHT;
    }

    // [yatıklık, eğim] sıfır farkı (Sıfırla); yoksa [0, 0].
    function loadOffsets() {
        var o = Application.Storage.getValue("levelOffsets");
        if (o instanceof Array && o.size() == 2
                && (o[0] instanceof Float || o[0] instanceof Double)
                && (o[1] instanceof Float || o[1] instanceof Double)) {
            return [o[0].toFloat(), o[1].toFloat()];
        }
        return [0.0, 0.0];
    }

    function saveMount(mount) {
        Application.Storage.setValue("levelMount", mount);
        // Başka takma şeklinin sıfır farkı geçersizdir: yeniden Sıfırla.
        Application.Storage.deleteValue("levelOffsets");
    }

    function saveOffsets(cantOffset, angleOffset) {
        Application.Storage.setValue("levelOffsets", [cantOffset.toFloat(), angleOffset.toFloat()]);
    }

    function isCalibrated() {
        return Application.Storage.getValue("levelOffsets") != null;
    }
}
