import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_settings.dart';
import '../../tools/domain/compass_math.dart';
import '../../tools/domain/weather_policy.dart';
import '../../tools/ports/weather_provider.dart';
import '../../tools/state/weather_controller.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// Hava & Rüzgâr: service data for the user's coarse location.
///
/// This is MODEL/forecast-service data for a grid cell. The phone's GPS does
/// not measure wind, and the value is not the wind at the shooter or target.
/// The data is never written into the ballistic inputs automatically.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with WidgetsBindingObserver {
  WeatherController? _controller;
  Timer? _ageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Freshness/age are derived from the clock, not from controller events:
    // re-evaluate every minute and when the app returns to the foreground so a
    // "Güncel" badge cannot outlive its 30 minutes.
    _ageTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final s = ToolsServicesScope.of(context);
      _controller = WeatherController(location: s.location, provider: s.weather, clock: s.clock);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ageTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Hava & Rüzgâr'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MenzilPage(children: _children(context, controller)),
      ),
    );
  }

  List<Widget> _children(BuildContext context, WeatherController controller) {
    final metric = AppSettingsScope.metricOf(context);
    final obs = controller.observation;
    final phase = controller.phase;
    final busy = phase == WeatherPhase.locating || phase == WeatherPhase.loading;

    return [
      if (obs == null) ..._withoutData(context, controller, busy) else ..._withData(context, controller, obs, metric, busy),
      const SizedBox(height: MenzilSpace.md),
      MenzilNotice(
        tone: MenzilNoticeTone.warning,
        title: 'Bu bir ölçüm değildir',
        message: 'Veri, ${_sourceName(controller)} hava servisinin model tahminidir. Telefonun GPS\'i rüzgâr '
            'ölçmez; değer konumunuzdaki veya hedefteki gerçek rüzgârı göstermez. '
            'Atış hesabına otomatik aktarılmaz.',
      ),
    ];
  }

  String _sourceName(WeatherController controller) => controller.provider.sourceName;

  List<Widget> _withoutData(BuildContext context, WeatherController controller, bool busy) {
    final phase = controller.phase;
    if (busy) {
      return [
        SizedBox(
          height: 280,
          child: MenzilStateMessage(
            icon: Icons.cloud_sync_outlined,
            message: phase == WeatherPhase.locating ? 'Konum alınıyor…' : 'Hava verisi yükleniyor…',
            action: const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
        ),
      ];
    }
    final String message;
    final bool settings;
    switch (phase) {
      case WeatherPhase.locationDenied:
        message = controller.deniedPermanently
            ? 'Konum izni kalıcı olarak kapalı. Hava verisi için Ayarlar\'dan konum iznini açın.'
            : 'Konum izni verilmedi. Hava verisi yalnızca izin verirseniz getirilir.';
        settings = controller.deniedPermanently;
      case WeatherPhase.locationOff:
        message = 'Konum servisleri kapalı. Ayarlar\'dan açıp tekrar deneyin.';
        settings = true;
      case WeatherPhase.locationFailed:
        message = 'Konum alınamadı. Açık havada tekrar deneyin.';
        settings = false;
      case WeatherPhase.failed:
        message = _failureText(controller.failure);
        settings = false;
      case WeatherPhase.idle:
      case WeatherPhase.locating:
      case WeatherPhase.loading:
      case WeatherPhase.ready:
        message = 'Konumunuza göre rüzgâr, sıcaklık, nem ve basınç servis verisini getirir. '
            'Konumunuz yalnızca bu istek için kullanılır ve saklanmaz.';
        settings = false;
    }
    final isIdle = phase == WeatherPhase.idle;
    return [
      SizedBox(
        height: 300,
        child: MenzilStateMessage(
          icon: isIdle ? Icons.cloud_outlined : Icons.cloud_off_outlined,
          message: message,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenzilPrimaryButton(
                label: isIdle ? 'Hava verisini getir' : 'Tekrar dene',
                onPressed: controller.refresh,
                icon: Icons.my_location_outlined,
                expand: false,
              ),
              if (settings) ...[
                const SizedBox(height: MenzilSpace.sm),
                MenzilSecondaryButton(label: 'Ayarlar\'ı aç', onPressed: controller.openSettings, expand: false),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  /// A refresh that ends in a location problem must not leave old data on
  /// screen without explanation.
  String? _locationRefreshNote(WeatherController controller) {
    switch (controller.phase) {
      case WeatherPhase.locationDenied:
        return controller.deniedPermanently
            ? 'Konum izni kapalı; Ayarlar\'dan açın.'
            : 'Konum izni verilmedi.';
      case WeatherPhase.locationOff:
        return 'Konum servisleri kapalı.';
      case WeatherPhase.locationFailed:
        return 'Konum alınamadı.';
      case WeatherPhase.idle:
      case WeatherPhase.locating:
      case WeatherPhase.loading:
      case WeatherPhase.ready:
      case WeatherPhase.failed:
        return null;
    }
  }

  String _failureText(WeatherFailure? f) {
    switch (f?.kind) {
      case WeatherFailureKind.offline:
        return 'İnternet bağlantısı yok. Bağlandığınızda tekrar deneyin.';
      case WeatherFailureKind.timeout:
        return 'Hava servisi yanıt vermedi. Tekrar deneyin.';
      case WeatherFailureKind.rateLimited:
        return 'Hava servisi istek sınırına ulaştı. Biraz sonra tekrar deneyin.';
      case WeatherFailureKind.notConfigured:
        return 'Hava servisi bu derlemede yapılandırılmamış: MET Norway için iletişim bilgisi '
            '(METNO_CONTACT) derleme sırasında verilmedi.';
      case WeatherFailureKind.server:
      case WeatherFailureKind.invalidResponse:
      case null:
        return 'Hava verisi alınamadı. Tekrar deneyin.';
    }
  }

  List<Widget> _withData(
    BuildContext context,
    WeatherController controller,
    WeatherObservation obs,
    bool metric,
    bool busy,
  ) {
    final c = MenzilColors.of(context);
    final freshness = controller.freshness ?? WeatherFreshness.expired;
    final age = controller.age ?? Duration.zero;
    final failed = controller.phase == WeatherPhase.failed;
    final locationNote = _locationRefreshNote(controller);
    final dim = freshness == WeatherFreshness.expired;
    final valueColor = dim ? c.ink2 : c.ink;
    final condition = ToolFormat.condition(obs.conditionCode);

    final (IconData badgeIcon, String badgeText) = switch (freshness) {
      WeatherFreshness.fresh => (Icons.check_circle_outline, 'Güncel'),
      WeatherFreshness.stale => (Icons.history, 'Bayat veri'),
      WeatherFreshness.expired => (Icons.warning_amber_outlined, 'Güncel değil'),
    };

    return [
      if (locationNote != null)
        MenzilNotice(
          tone: MenzilNoticeTone.danger,
          title: 'Güncelleme başarısız',
          message: '$locationNote Aşağıda son alınan veri gösteriliyor; güncel olduğu varsayılmamalı.',
        ),
      if (failed)
        MenzilNotice(
          tone: MenzilNoticeTone.danger,
          title: 'Güncelleme başarısız',
          message: '${_failureText(controller.failure)} Aşağıda son alınan veri gösteriliyor; '
              'güncel olduğu varsayılmamalı.',
        ),
      MenzilCard(
        accent: c.cyan,
        child: Semantics(
          label: 'Rüzgâr ${ToolFormat.windSpeed(obs.windSpeedMps, metric: metric)}, '
              '${CompassMath.wholeDegrees(obs.windFromDeg)} derece ${CompassMath.cardinal16Spoken(obs.windFromDeg)} yönünden esiyor.',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rüzgâr', style: MenzilType.label(c.cyanInk)),
                const SizedBox(height: MenzilSpace.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ToolFormat.windSpeed(obs.windSpeedMps, metric: metric),
                    key: const Key('weather-wind-speed'),
                    style: MenzilType.display(valueColor, size: 52),
                  ),
                ),
                Text(ToolFormat.windSpeedAlt(obs.windSpeedMps, metric: metric), style: MenzilType.caption(c.ink2)),
                const SizedBox(height: MenzilSpace.sm),
                Text(
                  'Yön: ${CompassMath.wholeDegrees(obs.windFromDeg)}° ${CompassMath.cardinal16(obs.windFromDeg)} '
                  '(esen yön — rüzgârın geldiği taraf)',
                  key: const Key('weather-wind-dir'),
                  style: MenzilType.body(valueColor),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: MenzilSpace.md),
      MenzilMetricGrid(
        columns: 2,
        metrics: [
          MenzilMetric('Sıcaklık', ToolFormat.temperature(obs.temperatureC, metric: metric)),
          MenzilMetric('Nem', '${obs.humidityPercent.toStringAsFixed(0)} %'),
          MenzilMetric(
            obs.pressureKind == PressureKind.seaLevel ? 'Basınç (deniz seviyesi)' : 'Basınç (istasyon)',
            ToolFormat.pressure(obs.pressureHpa, metric: metric),
          ),
          MenzilMetric('Hava durumu', condition ?? '—'),
        ],
      ),
      MenzilCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badgeIcon, color: c.ink),
                const SizedBox(width: MenzilSpace.xs),
                Text(badgeText, key: const Key('weather-freshness'), style: MenzilType.heading(c.ink, size: 20)),
              ],
            ),
            const SizedBox(height: MenzilSpace.xs),
            Text(
              'Alındı: ${WeatherPolicy.ageText(age)} · ${ToolFormat.dateTime(obs.fetchedAt)}',
              key: const Key('weather-age'),
              style: MenzilType.body(c.ink),
            ),
            Text('Veri geçerlilik zamanı: ${ToolFormat.dateTime(obs.validAt)}', style: MenzilType.caption(c.ink2)),
            const SizedBox(height: MenzilSpace.xs),
            Text('Kaynak: ${obs.sourceName}', style: MenzilType.caption(c.ink2)),
            if (obs.pressureKind == PressureKind.seaLevel)
              Text(
                'Basınç deniz seviyesine indirgenmiş değerdir; bulunduğunuz yerdeki istasyon basıncı değildir.',
                style: MenzilType.caption(c.ink2),
              ),
          ],
        ),
      ),
      MenzilPrimaryButton(
        label: busy ? 'Yenileniyor…' : 'Yenile',
        onPressed: busy ? null : controller.refresh,
        icon: Icons.refresh,
      ),
    ];
  }
}
