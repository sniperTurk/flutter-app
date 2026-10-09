import 'package:flutter/material.dart';

import '../../core/standard_drag_tables.dart';
import '../../core/unit_system.dart';
import '../../models/domain.dart';
import '../../tools/domain/field_calc.dart';
import '../../tools/ports/location_provider.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'reticle_screen.dart';
import 'tool_support.dart';

const _decimal = TextInputType.numberWithOptions(decimal: true, signed: true);

double? _p(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.'));

String _d(double v, int digits) => ToolFormat.dec(v, digits);

/// Hesaplayıcılar: the field calculators (distance, angular size, click
/// check, BC from two velocities, energy, air lab) and the unit converters.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(
      String key,
      IconData icon,
      String title,
      String subtitle,
      Widget page,
    ) => MenzilToolTile(
      tileKey: Key(key),
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _open(context, page),
    );

    Widget conv(String key, IconData icon, ConvCategory cat) => tile(
      key,
      icon,
      cat.title.replaceAll('birimleri', 'birimi dönüştürücü'),
      '${cat.units.map((u) => u.label.split(' ').first).take(4).join(', ')}…',
      ConverterScreen(category: cat),
    );

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Hesaplayıcılar'),
      body: MenzilPage(
        children: [
          tile(
            'calc-stadia',
            Icons.straighten,
            'Stadyametrik mesafe ölçer',
            'Hedef boyutu ve dürbündeki okumadan mesafe',
            const StadiaScreen(),
          ),
          tile(
            'calc-reticle',
            Icons.gps_fixed,
            'Retikül (mil-dot)',
            'Mil-dot çizimi, noktaların mesafedeki cm karşılığı',
            const ReticleScreen(),
          ),
          tile(
            'calc-distance',
            Icons.social_distance_outlined,
            'Mesafe hesaplama',
            'İki koordinat arası mesafe ve yön',
            const CoordinateDistanceScreen(),
          ),
          tile(
            'calc-custom-location',
            Icons.my_location_outlined,
            'Özel konum için mesafe',
            'Bulunduğun yerden girdiğin hedef konuma',
            const CustomLocationScreen(),
          ),
          tile(
            'calc-moa-at-distance',
            Icons.adjust,
            'Mesafedeki MOA',
            'Mesafede MOA, MIL ve cm karşılığı',
            const MoaAtDistanceScreen(),
          ),
          tile(
            'calc-click-check',
            Icons.rule_outlined,
            'Tıklama değeri doğrulama',
            'Gerçek tık değeri ve hata yüzdesi',
            const ClickCheckScreen(),
          ),
          tile(
            'calc-bc-two-velocities',
            Icons.compress,
            '2 hızdan balistik katsayı',
            'İki hız ölçümünden BC (G1 / G7)',
            const TwoVelocityBcScreen(),
          ),
          tile(
            'calc-energy',
            Icons.bolt_outlined,
            'Enerji ve güç',
            'Namlu enerjisi (J, ft·lbf), momentum, güç faktörü',
            const EnergyScreen(),
          ),
          tile(
            'calc-air-lab',
            Icons.cloud_outlined,
            'Hava laboratuvarı',
            'Hava yoğunluğu, yoğunluk irtifası, ses hızı',
            const AirLabScreen(),
          ),
          conv('conv-angle', Icons.change_history, Converters.angle),
          conv('conv-speed', Icons.speed_outlined, Converters.speed),
          conv('conv-weight', Icons.scale_outlined, Converters.weight),
          conv('conv-pressure', Icons.compress, Converters.pressure),
          conv('conv-length', Icons.height, Converters.length),
          conv('conv-torque', Icons.build_outlined, Converters.torque),
          conv('conv-energy', Icons.bolt_outlined, Converters.energy),
          conv(
            'conv-temperature',
            Icons.thermostat_outlined,
            Converters.temperature,
          ),
        ],
      ),
    );
  }
}

/// Shared page frame: title, inputs, then results.
class _CalcPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CalcPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: MenzilSubPageBar(title: title),
    body: MenzilPage(children: children),
  );
}

Widget _field(
  TextEditingController c,
  String label, {
  String? unit,
  String? helper,
  required VoidCallback changed,
  required String info,
  Key? key,
}) => MenzilInput(
  key: key,
  controller: c,
  label: label,
  unit: unit,
  helperText: helper,
  info: info,
  keyboardType: _decimal,
  onChanged: (_) => changed(),
);

Widget _gap() => const SizedBox(height: MenzilSpace.sm);

/// ⓘ texts of the Hesaplayıcılar fields (owner rule, 2026-10-07).
abstract final class CalculatorFieldInfo {
  static const targetSize =
      'Hedefin bilinen gerçek boyu veya genişliği. Örnek: tavşan ~20 cm, '
      'karga ~45 cm, A4 kâğıt 21 cm.';
  static const reading =
      'Hedefin dürbün retikülünde kapladığı aralık (MIL veya MOA). SFP '
      'dürbünde retikülün doğru olduğu büyütmede okuyun. Örnek: 2,5 MIL.';
  static const latitude =
      'Enlem, derece olarak (kuzey +, güney −). Harita uygulamasında konuma '
      'uzun basınca görünür. Örnek: 39,92.';
  static const longitude =
      'Boylam, derece olarak (doğu +, batı −). Harita uygulamasında konuma '
      'uzun basınca görünür. Örnek: 32,85.';
  static const distance =
      'Hedefe olan mesafe; telemetre ile ölçün. Örnek: 50 m.';
  static const sizeToMeasure =
      'İsterseniz bir boy girin; mesafede kaç MOA / MIL tuttuğu gösterilir. '
      'Örnek: 10 cm.';
  static const clicks =
      'Test için kuleden çevirdiğiniz toplam tık sayısı. Ne kadar çok tık, o '
      'kadar doğru sonuç. Örnek: 40 tık.';
  static const shift =
      'Bu tıklarla isabet noktasının hedefte kaydığı mesafe (grup merkezleri '
      'arası), cm olarak. Örnek: 11,6 cm.';
  static const clickValue =
      'Dürbünün kulesinde veya kılavuzunda yazan tık değeri. Örnek: 0,1 MRAD '
      'veya 1/4 MOA.';
  static const v1 =
      'Kronografla namluya yakın ölçülen hız (birkaç atışın ortalaması). '
      'Örnek: 280 m/s.';
  static const v2 =
      'Aynı mühimmatın belirli bir mesafede ölçülen hızı (ortalama). V1’den '
      'küçük olmalı. Örnek: 245 m/s.';
  static const gap =
      'İki hız ölçümü arasındaki mesafe. Fark ne kadar büyükse BC o kadar '
      'doğru çıkar. Örnek: 50 m.';
  static const temperature =
      'Ölçüm yerindeki hava sıcaklığı. Telefonun hava durumu yeterlidir. '
      'Örnek: 18 °C.';
  static const pressure =
      'Hava basıncı. İstasyon basıncı seçiliyse bulunduğunuz yerdeki gerçek '
      'basınç (Kestrel/barometre), değilse hava durumunda yazan deniz '
      'seviyesi basıncı. Örnek: 1013 hPa.';
  static const humidity =
      'Bağıl nem, yüzde olarak; hava durumunda yazar. Örnek: %60.';
  static const altitude =
      'Bulunduğunuz yerin deniz seviyesinden yüksekliği; deniz seviyesi '
      'basıncını istasyon basıncına çevirmek için. Örnek: 900 m.';
  static const value =
      'Dönüştürmek istediğiniz sayı; birimini aşağıdan seçin. Örnek: 12.';
  static const grain =
      'Saçma veya merminin ağırlığı, grain (gr); kutusunda yazar. Örnek: '
      '25,39 gr (.22 saçma) veya 168 gr (.308).';
  static const velocity =
      'Namlu çıkış hızı; kronografla ölçün veya profildeki değeri girin. '
      'Örnek: 270 m/s (885 fps).';
  static const targetEnergy =
      'İsteğe bağlı: ulaşmak veya aşmamak istediğiniz enerji, joule. Bu '
      'ağırlıkta gereken hız gösterilir. Örnek: 16,27 J (12 ft·lbf sınırı).';
}

Widget _header(String text) => MenzilSectionHeader(
  text,
  padding: const EdgeInsets.only(top: MenzilSpace.md, bottom: MenzilSpace.sm),
);

Widget _note(String text, {MenzilNoticeTone tone = MenzilNoticeTone.info}) =>
    MenzilNotice(tone: tone, message: text);

// ---------------------------------------------------------------------------
// Stadyametrik mesafe ölçer
// ---------------------------------------------------------------------------

class StadiaScreen extends StatefulWidget {
  const StadiaScreen({super.key});
  @override
  State<StadiaScreen> createState() => _StadiaState();
}

class _StadiaState extends State<StadiaScreen> {
  final _size = TextEditingController(text: '50');
  final _reading = TextEditingController(text: '5');
  bool _mil = true;
  bool _cm = true;

  @override
  void dispose() {
    _size.dispose();
    _reading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _p(_size);
    final reading = _p(_reading);
    double? dist;
    if (size != null && reading != null) {
      final sizeM = _cm ? size / 100 : size * 0.0254;
      final rad = reading * (_mil ? FieldCalc.radPerMil : FieldCalc.radPerMoa);
      dist = FieldCalc.distanceFromAngle(sizeM, rad);
    }
    return _CalcPage(
      title: 'Stadyametrik mesafe ölçer',
      children: [
        _header('1 · Hedef ve okuma'),
        _field(
          _size,
          'Hedefin gerçek boyu', info: CalculatorFieldInfo.targetSize,
          unit: _cm ? 'cm' : 'inç',
          changed: () => setState(() {}),
          key: const Key('stadia-size'),
        ),
        MenzilChipGroup<bool>(
          options: const [(true, 'cm'), (false, 'inç')],
          selected: _cm,
          onSelected: (v) => setState(() => _cm = v),
        ),
        _gap(),
        _field(
          _reading,
          'Dürbündeki okuma (hedefin kapladığı)', info: CalculatorFieldInfo.reading,
          unit: _mil ? 'MIL' : 'MOA',
          changed: () => setState(() {}),
          key: const Key('stadia-reading'),
        ),
        MenzilChipGroup<bool>(
          options: const [(true, 'MIL'), (false, 'MOA')],
          selected: _mil,
          onSelected: (v) => setState(() => _mil = v),
        ),
        _header('2 · Sonuç'),
        if (dist == null)
          _note('Boy ve okuma için pozitif sayı girin.')
        else
          MenzilMetricGrid(
            columns: 2,
            metrics: [
              MenzilMetric('Mesafe', _d(dist, 1), 'm'),
              MenzilMetric('Mesafe', _d(dist / 0.9144, 1), 'yd'),
            ],
          ),
        _note(
          'Sonuç, hedefin boyunu doğru bildiğinize ve okumayı doğru yaptığınıza bağlıdır; '
          'ölçüm hatası mesafeye aynı oranda yansır.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mesafe hesaplama (iki koordinat)
// ---------------------------------------------------------------------------

class CoordinateDistanceScreen extends StatefulWidget {
  const CoordinateDistanceScreen({super.key});
  @override
  State<CoordinateDistanceScreen> createState() => _CoordState();
}

class _CoordState extends State<CoordinateDistanceScreen> {
  final _lat1 = TextEditingController();
  final _lon1 = TextEditingController();
  final _lat2 = TextEditingController();
  final _lon2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_lat1, _lon1, _lat2, _lon2]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _p(_lat1), b = _p(_lon1), c = _p(_lat2), d = _p(_lon2);
    final ok =
        a != null &&
        b != null &&
        c != null &&
        d != null &&
        FieldCalc.validLatLon(a, b) &&
        FieldCalc.validLatLon(c, d);
    return _CalcPage(
      title: 'Mesafe hesaplama',
      children: [
        _header('1 · Birinci nokta'),
        MenzilFieldGrid(
          children: [
            _field(
              _lat1,
              'Enlem', info: CalculatorFieldInfo.latitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('coord-lat1'),
            ),
            _field(
              _lon1,
              'Boylam', info: CalculatorFieldInfo.longitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('coord-lon1'),
            ),
          ],
        ),
        _header('2 · İkinci nokta'),
        MenzilFieldGrid(
          children: [
            _field(
              _lat2,
              'Enlem', info: CalculatorFieldInfo.latitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('coord-lat2'),
            ),
            _field(
              _lon2,
              'Boylam', info: CalculatorFieldInfo.longitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('coord-lon2'),
            ),
          ],
        ),
        _header('3 · Sonuç'),
        if (!ok)
          _note(
            'Enlem −90..90, boylam −180..180 arasında ondalık derece girin.',
          )
        else
          _distanceMetrics(
            FieldCalc.haversineM(a, b, c, d),
            FieldCalc.bearingDeg(a, b, c, d),
          ),
        _note(
          'Düz çizgi (büyük daire) mesafesidir; arazi eğimi ve yükseklik farkı dahil değildir.',
        ),
      ],
    );
  }
}

Widget _distanceMetrics(double meters, double bearing) => MenzilMetricGrid(
  columns: 2,
  metrics: [
    MenzilMetric('Mesafe', _d(meters, 1), 'm'),
    MenzilMetric('Mesafe', _d(meters / 0.9144, 1), 'yd'),
    MenzilMetric('Yön (pusula)', _d(bearing, 1), '°'),
    MenzilMetric('Yön', '${_d(bearing, 0)}° ${_cardinal(bearing)}'),
  ],
);

String _cardinal(double deg) {
  const n = ['K', 'KD', 'D', 'GD', 'G', 'GB', 'B', 'KB'];
  return n[((deg % 360) / 45).round() % 8];
}

// ---------------------------------------------------------------------------
// Özel konum için mesafe
// ---------------------------------------------------------------------------

class CustomLocationScreen extends StatefulWidget {
  const CustomLocationScreen({super.key});
  @override
  State<CustomLocationScreen> createState() => _CustomLocState();
}

class _CustomLocState extends State<CustomLocationScreen> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  LocationFix? _fix;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final provider = ToolsServicesScope.of(context).location;
    setState(() {
      _busy = true;
      _message = null;
    });
    final r = await provider.current();
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (r) {
        case LocationFix():
          _fix = r;
        case LocationDenied(:final permanent):
          _message = permanent
              ? 'Konum izni reddedildi. iPhone Ayarlar > Gizlilik > Konum Servisleri bölümünden izin verin.'
              : 'Konum izni verilmedi.';
        case LocationServiceOff():
          _message = 'Konum servisleri kapalı.';
        case LocationFailure(:final message):
          _message = 'Konum alınamadı: $message';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lat = _p(_lat), lon = _p(_lon);
    final fix = _fix;
    final ok =
        fix != null &&
        lat != null &&
        lon != null &&
        FieldCalc.validLatLon(lat, lon);
    return _CalcPage(
      title: 'Özel konum için mesafe',
      children: [
        _header('1 · Bulunduğum yer'),
        MenzilSecondaryButton(
          key: const Key('custom-loc-get'),
          expand: true,
          label: _busy
              ? 'Konum alınıyor…'
              : (fix == null ? 'Konumumu al' : 'Konumu yenile'),
          icon: Icons.my_location_outlined,
          onPressed: _busy ? null : _locate,
        ),
        if (fix != null)
          Padding(
            padding: const EdgeInsets.only(top: MenzilSpace.xs),
            child: Text(
              'Konum: ${_d(fix.latitude, 5)}, ${_d(fix.longitude, 5)} (yaklaşık)',
              style: MenzilType.caption(MenzilColors.of(context).ink2),
            ),
          ),
        if (_message != null) _note(_message!, tone: MenzilNoticeTone.warning),
        _header('2 · Hedef konum'),
        MenzilFieldGrid(
          children: [
            _field(
              _lat,
              'Enlem', info: CalculatorFieldInfo.latitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('custom-loc-lat'),
            ),
            _field(
              _lon,
              'Boylam', info: CalculatorFieldInfo.longitude,
              unit: '°',
              changed: () => setState(() {}),
              key: const Key('custom-loc-lon'),
            ),
          ],
        ),
        _header('3 · Sonuç'),
        if (!ok)
          _note(
            'Önce konumunuzu alın ve hedefin enlem/boylamını ondalık derece girin.',
          )
        else
          _distanceMetrics(
            FieldCalc.haversineM(fix.latitude, fix.longitude, lat, lon),
            FieldCalc.bearingDeg(fix.latitude, fix.longitude, lat, lon),
          ),
        _note(
          'Konum yalnızca bu hesap için bir kez okunur, saklanmaz. Telefon konumu birkaç metre '
          'sapabilir; kısa menzillerde bu sapma sonucu bozar.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mesafedeki MOA
// ---------------------------------------------------------------------------

class MoaAtDistanceScreen extends StatefulWidget {
  const MoaAtDistanceScreen({super.key});
  @override
  State<MoaAtDistanceScreen> createState() => _MoaAtDistState();
}

class _MoaAtDistState extends State<MoaAtDistanceScreen> {
  final _dist = TextEditingController(text: '100');
  final _size = TextEditingController(text: '10');

  @override
  void dispose() {
    _dist.dispose();
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dist = _p(_dist), sizeCm = _p(_size);
    final oneMoaCm = dist == null
        ? null
        : FieldCalc.sizeFromAngle(dist, FieldCalc.radPerMoa);
    final oneMilCm = dist == null
        ? null
        : FieldCalc.sizeFromAngle(dist, FieldCalc.radPerMil);
    final rad = (dist != null && sizeCm != null)
        ? FieldCalc.angleFromSize(sizeCm / 100, dist)
        : null;
    return _CalcPage(
      title: 'Mesafedeki MOA',
      children: [
        _header('1 · Girdiler'),
        _field(
          _dist,
          'Mesafe', info: CalculatorFieldInfo.distance,
          unit: 'm',
          changed: () => setState(() {}),
          key: const Key('moa-dist'),
        ),
        _gap(),
        _field(
          _size,
          'Ölçülecek boy (isteğe bağlı)', info: CalculatorFieldInfo.sizeToMeasure,
          unit: 'cm',
          helper: 'Ör. vuruş noktası ile hedef arası',
          changed: () => setState(() {}),
          key: const Key('moa-size'),
        ),
        _header('2 · Sonuç'),
        if (oneMoaCm == null || oneMilCm == null)
          _note('Pozitif mesafe girin.')
        else
          MenzilMetricGrid(
            columns: 2,
            metrics: [
              MenzilMetric('1 MOA', _d(oneMoaCm * 100, 2), 'cm'),
              MenzilMetric('1 MIL', _d(oneMilCm * 100, 2), 'cm'),
              if (rad != null) ...[
                MenzilMetric('Boy', _d(rad / FieldCalc.radPerMoa, 2), 'MOA'),
                MenzilMetric('Boy', _d(rad / FieldCalc.radPerMil, 2), 'MIL'),
              ],
            ],
          ),
        _note(
          'MOA, gerçek açısal MOA (1/60°) olarak hesaplanır. Bazı dürbünler "inç/100 yd" '
          '(SMOA) kullanır; farkı yaklaşık %4,7\'dir.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tıklama değeri doğrulama
// ---------------------------------------------------------------------------

class ClickCheckScreen extends StatefulWidget {
  const ClickCheckScreen({super.key});
  @override
  State<ClickCheckScreen> createState() => _ClickCheckState();
}

class _ClickCheckState extends State<ClickCheckScreen> {
  final _dist = TextEditingController(text: '100');
  final _clicks = TextEditingController(text: '40');
  final _moved = TextEditingController();
  final _nominal = TextEditingController(text: '0,1');
  bool _mil = true;

  @override
  void dispose() {
    for (final c in [_dist, _clicks, _moved, _nominal]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitRad = _mil ? FieldCalc.radPerMil : FieldCalc.radPerMoa;
    final unitName = _mil ? 'MIL' : 'MOA';
    final dist = _p(_dist);
    final clicksD = _p(_clicks);
    final movedCm = _p(_moved);
    final nominal = _p(_nominal);
    final clicks = (clicksD != null && clicksD == clicksD.roundToDouble())
        ? clicksD.toInt()
        : null;
    final real = (dist != null && movedCm != null && clicks != null)
        ? FieldCalc.realClickRad(
            distanceM: dist,
            movedM: movedCm / 100,
            clicks: clicks,
          )
        : null;
    final hasResult = real != null && nominal != null && nominal > 0;
    return _CalcPage(
      title: 'Tıklama değeri doğrulama',
      children: [
        _header('1 · Test'),
        _note(
          'Dürbünü sıfırla, hedefe bir grup at, belirli sayıda tık çevir, ikinci grubu at ve '
          'iki grup merkezi arasındaki kaymayı ölç. Tık sayısı büyük olsun (ör. 20–40).',
        ),
        _gap(),
        _field(
          _dist,
          'Mesafe', info: CalculatorFieldInfo.distance,
          unit: 'm',
          changed: () => setState(() {}),
          key: const Key('click-dist'),
        ),
        _gap(),
        _field(
          _clicks,
          'Çevirdiğin tık sayısı', info: CalculatorFieldInfo.clicks,
          unit: 'tık',
          changed: () => setState(() {}),
          key: const Key('click-count'),
        ),
        _gap(),
        _field(
          _moved,
          'Ölçülen kayma', info: CalculatorFieldInfo.shift,
          unit: 'cm',
          changed: () => setState(() {}),
          key: const Key('click-moved'),
        ),
        _header('2 · Dürbünün yazan değeri'),
        MenzilChipGroup<bool>(
          options: const [(true, 'MIL'), (false, 'MOA')],
          selected: _mil,
          onSelected: (v) => setState(() {
            _mil = v;
            _nominal.text = v ? '0,1' : '0,25';
          }),
        ),
        _gap(),
        _field(
          _nominal,
          'Tık başına yazan değer', info: CalculatorFieldInfo.clickValue,
          unit: unitName,
          changed: () => setState(() {}),
          key: const Key('click-nominal'),
        ),
        _header('3 · Sonuç'),
        if (!hasResult)
          _note(
            'Mesafe, tık sayısı (tam sayı), ölçülen kayma ve yazan değeri girin.',
          )
        else
          Builder(
            builder: (_) {
              final actual = real / unitRad;
              final errPct = (actual - nominal) / nominal * 100;
              return MenzilMetricGrid(
                columns: 2,
                metrics: [
                  MenzilMetric('Gerçek tık', _d(actual, 4), unitName),
                  MenzilMetric('Yazan tık', _d(nominal, 4), unitName),
                  MenzilMetric(
                    'Fark',
                    '${errPct >= 0 ? '+' : ''}${_d(errPct, 1)}',
                    '%',
                  ),
                  MenzilMetric('Gerçek ÷ yazan', _d(actual / nominal, 4)),
                ],
              );
            },
          ),
        _note(
          'Oran = gerçek tık ÷ yazan tık. Tek bir grup çiftinden çıkan sonuç grup dağılımı '
          'kadar belirsizdir; testi farklı mesafe ve tık sayılarıyla tekrarlayın. '
          'Bu araç yalnızca dürbünün gerçek tık değerini ölçer; atış düzeltmesi vermez.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2 hızdan balistik katsayı
// ---------------------------------------------------------------------------

class TwoVelocityBcScreen extends StatefulWidget {
  const TwoVelocityBcScreen({super.key});
  @override
  State<TwoVelocityBcScreen> createState() => _TwoVelState();
}

class _TwoVelState extends State<TwoVelocityBcScreen> {
  final _v1 = TextEditingController();
  final _v2 = TextEditingController();
  final _dist = TextEditingController(text: '30');
  final _temp = TextEditingController(text: '15');
  final _press = TextEditingController(text: '1013,25');
  final _rh = TextEditingController(text: '50');
  bool _fps = false;
  bool _g1 = true;

  @override
  void dispose() {
    for (final c in [_v1, _v2, _dist, _temp, _press, _rh]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _fps ? 0.3048 : 1.0;
    final v1 = _p(_v1), v2 = _p(_v2), dist = _p(_dist);
    final t = _p(_temp), pr = _p(_press), rh = _p(_rh);
    double? bc;
    String? problem;
    if (v1 != null &&
        v2 != null &&
        dist != null &&
        t != null &&
        pr != null &&
        rh != null) {
      if (!(v1 > 0 && v2 > 0 && dist > 0 && pr > 0 && rh >= 0 && rh <= 100)) {
        problem = 'Değerler pozitif olmalı; nem 0–100.';
      } else if (v2 >= v1) {
        problem = 'Uzaktaki hız, namlu hızından küçük olmalı.';
      } else {
        try {
          bc = FieldCalc.ballisticCoefficientFromTwoVelocities(
            table: _g1 ? StandardDragTables.g1 : StandardDragTables.g7,
            v1Mps: v1 * f,
            v2Mps: v2 * f,
            distanceM: dist,
            env: EnvironmentData(
              temperatureC: t,
              pressureHpa: pr,
              humidityPercent: rh,
            ),
          );
          if (bc == null) {
            problem =
                'Bu değerlere uyan bir BC (0,005–3,0) bulunamadı. Hızları ve mesafeyi kontrol edin.';
          }
        } on ArgumentError catch (e) {
          problem = 'Geçersiz atmosfer değeri: ${e.message}';
        }
      }
    }
    return _CalcPage(
      title: '2 hızdan balistik katsayı',
      children: [
        _header('1 · Hız ölçümleri'),
        _note(
          'Kronografı namluya yakın (V1) ve belirli bir mesafede (V2) kullanarak iki hız ölçün; '
          'aynı mühimmatın birkaç atışının ortalamasını girin.',
        ),
        _gap(),
        MenzilChipGroup<bool>(
          options: const [(false, 'm/s'), (true, 'fps')],
          selected: _fps,
          onSelected: (v) => setState(() => _fps = v),
        ),
        _gap(),
        _field(
          _v1,
          'Namlu yakını hız (V1)', info: CalculatorFieldInfo.v1,
          unit: _fps ? 'fps' : 'm/s',
          changed: () => setState(() {}),
          key: const Key('bc-v1'),
        ),
        _gap(),
        _field(
          _v2,
          'Uzaktaki hız (V2)', info: CalculatorFieldInfo.v2,
          unit: _fps ? 'fps' : 'm/s',
          changed: () => setState(() {}),
          key: const Key('bc-v2'),
        ),
        _gap(),
        _field(
          _dist,
          'İki ölçüm arası mesafe', info: CalculatorFieldInfo.gap,
          unit: 'm',
          changed: () => setState(() {}),
          key: const Key('bc-dist'),
        ),
        _header('2 · Hava ve model'),
        MenzilFieldGrid(
          children: [
            _field(
              _temp,
              'Sıcaklık', info: CalculatorFieldInfo.temperature,
              unit: '°C',
              changed: () => setState(() {}),
            ),
            _field(
              _press,
              'Basınç', info: CalculatorFieldInfo.pressure,
              unit: 'hPa',
              changed: () => setState(() {}),
            ),
            _field(_rh, 'Nem', info: CalculatorFieldInfo.humidity, unit: '%', changed: () => setState(() {})),
          ],
        ),
        _gap(),
        MenzilChipGroup<bool>(
          options: const [(true, 'G1'), (false, 'G7')],
          selected: _g1,
          onSelected: (v) => setState(() => _g1 = v),
        ),
        _header('3 · Sonuç'),
        if (problem != null)
          _note(problem, tone: MenzilNoticeTone.warning)
        else if (bc == null)
          _note('V1, V2 ve mesafeyi girin.')
        else
          MenzilMetricGrid(
            columns: 2,
            metrics: [
              MenzilMetric('BC (${_g1 ? 'G1' : 'G7'})', _d(bc, 3), 'lb/in²'),
              MenzilMetric('Hız kaybı', _d((v1! - v2!) * f, 1), 'm/s'),
            ],
          ),
        _note(
          'Bu bir referans hesaptır: standart G1/G7 sürtünme tablosu kullanılır ve '
          'yörünge hesabına (DOPE) bağlanmaz. Havalı tüfek saçmaları standart '
          'G1/G7 şeklinden çok farklı olabilir; sonuç mühimmat üreticisinin BC değerinden '
          'sapabilir. Kronograf hatası sonucu güçlü etkiler (%1 hız hatası, BC\'de çok daha büyük hata).',
          tone: MenzilNoticeTone.warning,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hava laboratuvarı
// ---------------------------------------------------------------------------

class AirLabScreen extends StatefulWidget {
  const AirLabScreen({super.key});
  @override
  State<AirLabScreen> createState() => _AirLabState();
}

class _AirLabState extends State<AirLabScreen> {
  final _temp = TextEditingController(text: '15');
  final _press = TextEditingController(text: '1013,25');
  final _rh = TextEditingController(text: '50');
  final _alt = TextEditingController(text: '0');
  bool _station = true;

  @override
  void dispose() {
    for (final c in [_temp, _press, _rh, _alt]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _p(_temp), pr = _p(_press), rh = _p(_rh), alt = _p(_alt);
    AirLab? lab;
    String? problem;
    if (t != null && pr != null && rh != null && (_station || alt != null)) {
      final station = _station
          ? pr
          : FieldCalc.stationPressureHpa(pr, alt ?? 0, temperatureC: t);
      try {
        lab = FieldCalc.airLab(
          EnvironmentData(
            temperatureC: t,
            pressureHpa: station,
            humidityPercent: rh,
            altitudeM: alt ?? 0,
          ),
        );
        if (!lab.densityKgM3.isFinite) lab = null;
      } on ArgumentError catch (e) {
        problem = 'Geçersiz değer: ${e.message}';
      }
    }
    return _CalcPage(
      title: 'Hava laboratuvarı',
      children: [
        _header('1 · Hava'),
        MenzilFieldGrid(
          children: [
            _field(
              _temp,
              'Sıcaklık', info: CalculatorFieldInfo.temperature,
              unit: '°C',
              changed: () => setState(() {}),
              key: const Key('air-temp'),
            ),
            _field(
              _rh,
              'Nem', info: CalculatorFieldInfo.humidity,
              unit: '%',
              changed: () => setState(() {}),
              key: const Key('air-rh'),
            ),
          ],
        ),
        _gap(),
        _field(
          _press,
          'Basınç', info: CalculatorFieldInfo.pressure,
          unit: 'hPa',
          changed: () => setState(() {}),
          key: const Key('air-press'),
        ),
        _gap(),
        MenzilChipGroup<bool>(
          options: const [
            (true, 'İstasyon (mutlak) basıncı'),
            (false, 'Deniz seviyesi basıncı'),
          ],
          selected: _station,
          onSelected: (v) => setState(() => _station = v),
        ),
        if (!_station) ...[
          _gap(),
          _field(
            _alt,
            'Rakım', info: CalculatorFieldInfo.altitude,
            unit: 'm',
            changed: () => setState(() {}),
            key: const Key('air-alt'),
          ),
        ],
        _header('2 · Sonuç'),
        if (problem != null)
          _note(problem, tone: MenzilNoticeTone.warning)
        else if (lab == null)
          _note('Sıcaklık, basınç ve nem girin.')
        else
          MenzilMetricGrid(
            columns: 2,
            metrics: [
              MenzilMetric('Hava yoğunluğu', _d(lab.densityKgM3, 4), 'kg/m³'),
              MenzilMetric(
                'Standarda oranı',
                _d(lab.densityRatioPercent, 1),
                '%',
              ),
              MenzilMetric(
                'Yoğunluk irtifası',
                _d(lab.densityAltitudeM, 0),
                'm',
              ),
              MenzilMetric(
                'Yoğunluk irtifası',
                _d(lab.densityAltitudeM / 0.3048, 0),
                'ft',
              ),
              MenzilMetric('Ses hızı', _d(lab.speedOfSoundMps, 1), 'm/s'),
              MenzilMetric('Çiğ noktası', _d(lab.dewPointC, 1), '°C'),
            ],
          ),
        _note(
          'Standart: ICAO, 15 °C, 1013,25 hPa, %0 nem = 1,225 kg/m³. Hesap nemli hava '
          'modeline (Magnus buhar basıncı) dayanır; hesaplamalar sensör doğruluğu kadar güvenilirdir.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Birim dönüştürücü
// ---------------------------------------------------------------------------

class ConverterScreen extends StatefulWidget {
  final ConvCategory category;
  const ConverterScreen({super.key, required this.category});
  @override
  State<ConverterScreen> createState() => _ConverterState();
}

class _ConverterState extends State<ConverterScreen> {
  final _value = TextEditingController(text: '1');
  late ConvUnit _from = widget.category.units.first;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v == 0) return '0';
    final abs = v.abs();
    final digits = abs >= 1000
        ? 2
        : abs >= 1
        ? 4
        : abs >= 0.001
        ? 6
        : 9;
    var s = v.toStringAsFixed(digits);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final c = MenzilColors.of(context);
    final v = _p(_value);
    return _CalcPage(
      title: cat.title.replaceAll('birimleri', 'birimi dönüştürücü'),
      children: [
        _header('1 · Değer ve birim'),
        _field(
          _value,
          'Değer', info: CalculatorFieldInfo.value,
          changed: () => setState(() {}),
          key: Key('conv-${cat.id}-value'),
        ),
        _gap(),
        MenzilChipGroup<ConvUnit>(
          options: [for (final u in cat.units) (u, u.label)],
          selected: _from,
          onSelected: (u) => setState(() => _from = u),
        ),
        _header('2 · Karşılıkları'),
        if (v == null || !v.isFinite)
          _note('Bir sayı girin.')
        else
          MenzilCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final u in cat.units)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(u.label, style: MenzilType.body(c.ink2)),
                        ),
                        Flexible(
                          child: Text(
                            _fmt(cat.convert(v, _from, u)),
                            key: Key('conv-${cat.id}-${u.label}'),
                            textAlign: TextAlign.right,
                            style: MenzilType.heading(c.ink, size: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (cat.id == 'angle')
          _note(
            'MOA gerçek açısal MOA (1/60°); SMOA = 1 inç / 100 yd. NATO mil bir çemberi 6400\'e böler.',
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Enerji ve güç
// ---------------------------------------------------------------------------

/// Muzzle energy ½·m·v², momentum, power factor and the velocity needed for
/// a target energy (e.g. the 16.27 J / 12 ft·lbf airgun limit).
class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});
  @override
  State<EnergyScreen> createState() => _EnergyState();
}

class _EnergyState extends State<EnergyScreen> {
  final _grain = TextEditingController(text: '25,39');
  final _velocity = TextEditingController(text: '270');
  final _target = TextEditingController();
  bool _fps = false;

  @override
  void dispose() {
    for (final c in [_grain, _velocity, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = _p(_grain), vIn = _p(_velocity), e = _p(_target);
    final f = _fps ? 0.3048 : 1.0;
    final ok = g != null && g > 0 && vIn != null && vIn > 0;
    final v = ok ? vIn * f : null;
    final joules = ok ? FieldCalc.energyJ(g, v!) : null;
    final need = (g != null && g > 0 && e != null && e > 0)
        ? FieldCalc.velocityForEnergyMps(g, e)
        : null;
    return _CalcPage(
      title: 'Enerji ve güç',
      children: [
        _header('1 · Mühimmat ve hız'),
        _field(
          _grain,
          'Ağırlık',
          info: CalculatorFieldInfo.grain,
          unit: 'gr',
          changed: () => setState(() {}),
          key: const Key('energy-grain'),
        ),
        _gap(),
        MenzilChipGroup<bool>(
          options: const [(false, 'm/s'), (true, 'fps')],
          selected: _fps,
          onSelected: (x) => setState(() => _fps = x),
        ),
        _gap(),
        _field(
          _velocity,
          'Hız',
          info: CalculatorFieldInfo.velocity,
          unit: _fps ? 'fps' : 'm/s',
          changed: () => setState(() {}),
          key: const Key('energy-velocity'),
        ),
        _gap(),
        _field(
          _target,
          'Hedef enerji (isteğe bağlı)',
          info: CalculatorFieldInfo.targetEnergy,
          unit: 'J',
          changed: () => setState(() {}),
          key: const Key('energy-target'),
        ),
        _header('2 · Sonuç'),
        if (!ok)
          _note('Ağırlık ve hız için pozitif sayı girin.')
        else
          MenzilMetricGrid(
            key: const Key('energy-result'),
            columns: 2,
            metrics: [
              MenzilMetric('Enerji', _d(joules!, 1), 'J'),
              MenzilMetric(
                'Enerji',
                _d(UnitSystem.joulesToFootPounds(joules), 1),
                'ft·lbf',
              ),
              MenzilMetric(
                'Momentum',
                _d(FieldCalc.momentumNs(g, v!), 3),
                'N·s',
              ),
              MenzilMetric('Güç faktörü', _d(FieldCalc.powerFactor(g, v), 0)),
            ],
          ),
        if (need != null) ...[
          _gap(),
          MenzilMetricGrid(
            key: const Key('energy-need'),
            columns: 2,
            metrics: [
              MenzilMetric('Gereken hız', _d(need, 1), 'm/s'),
              MenzilMetric('Gereken hız', _d(need / 0.3048, 0), 'fps'),
            ],
          ),
        ],
        _gap(),
        _note(
          'Enerji = ½ · kütle · hız². Güç faktörü = grain × fps / 1000. '
          'Yasal sınırlar ülkeye göre değişir; kendi mevzuatınızı kontrol edin.',
        ),
      ],
    );
  }
}
