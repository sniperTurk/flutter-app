import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:latlong2/latlong.dart';

import '../../tools/domain/field_calc.dart';
import '../../tools/ports/location_provider.dart';
import '../../tools/ports/place_search.dart';
import '../../tools/tools_services.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

enum _Pick { shooter, target }

/// Esri World Imagery satellite tiles (no API key). Attribution is shown on
/// the map as the provider requires.
const mapImageryUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

/// Google Maps (hybrid satellite) is used when the build was made with the
/// Google Maps iOS key (owner, 2026-10-09; TestFlight passes
/// --dart-define=GOOGLE_MAPS_ENABLED=true only when the key secret exists).
/// Otherwise the keyless Esri map is shown.
const googleMapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');

/// Konum için mesafe: pick the shooter and the target on a satellite map and
/// read the straight-line distance and the bearing. Nothing is stored; the
/// two points live only while the screen is open.
///
/// With [returnDistance] the screen shows "Bu mesafeyi kullan" and pops with
/// the distance in metres (used by the shot-distance dialog).
class MapDistanceScreen extends StatefulWidget {
  final bool returnDistance;

  /// Replaces the network tile loader (tests only).
  final TileProvider? tileProvider;

  const MapDistanceScreen({
    super.key,
    this.returnDistance = false,
    this.tileProvider,
  });

  @override
  State<MapDistanceScreen> createState() => _MapDistanceState();
}

class _MapDistanceState extends State<MapDistanceScreen> {
  final _map = MapController();

  /// Google Maps state (only when [googleMapsEnabled]).
  g.GoogleMapController? _gmap;
  LatLng _gCenter = _turkey;
  _Pick _pick = _Pick.shooter;
  LatLng? _shooter;
  LatLng? _target;
  bool _locating = false;
  String? _message;
  final _query = TextEditingController();
  List<PlaceResult> _results = const [];
  bool _searching = false;
  String? _searchMessage;

  static const _turkey = LatLng(39.0, 35.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _gmap?.dispose();
    _map.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating || !mounted) return;
    final provider = ToolsServicesScope.of(context).location;
    setState(() {
      _locating = true;
      _message = null;
    });
    final result = await provider.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      switch (result) {
        case LocationFix(:final latitude, :final longitude):
          _shooter = LatLng(latitude, longitude);
          _pick = _Pick.target;
          _moveTo(_shooter!, 17);
        case LocationDenied():
          _message =
              'Konum izni verilmedi. Haritaya dokunarak nişancı konumunu seçebilirsiniz.';
        case LocationServiceOff():
          _message =
              'Konum servisleri kapalı. Haritaya dokunarak nişancı konumunu seçebilirsiniz.';
        case LocationFailure():
          _message =
              'Konum alınamadı. Haritaya dokunarak nişancı konumunu seçebilirsiniz.';
      }
    });
  }

  Future<void> _runSearch() async {
    final q = _query.text.trim();
    FocusScope.of(context).unfocus();
    if (q.length < 3) {
      setState(() {
        _results = const [];
        _searchMessage = 'En az 3 harf girin.';
      });
      return;
    }
    final places = ToolsServicesScope.of(context).places;
    setState(() {
      _searching = true;
      _searchMessage = null;
      _results = const [];
    });
    try {
      final found = await places.search(q);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = found;
        if (found.isEmpty) _searchMessage = 'Yer bulunamadı.';
      });
    } on PlaceSearchFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchMessage = e.message;
      });
    }
  }

  void _openResult(PlaceResult r) {
    setState(() {
      _results = const [];
      _searchMessage = null;
    });
    _moveTo(LatLng(r.latitude, r.longitude), 17);
  }

  static g.LatLng _g(LatLng p) => g.LatLng(p.latitude, p.longitude);

  void _moveTo(LatLng p, double zoom) {
    if (googleMapsEnabled) {
      _gCenter = p;
      _gmap?.moveCamera(g.CameraUpdate.newLatLngZoom(_g(p), zoom));
    } else {
      _map.move(p, zoom);
    }
  }

  void _reset() => setState(() {
    _shooter = null;
    _target = null;
    _pick = _Pick.shooter;
    _message = null;
  });

  void _swap() => setState(() {
    final a = _shooter;
    _shooter = _target;
    _target = a;
  });

  void _fit() {
    final s = _shooter, t = _target;
    if (s == null || t == null) return;
    if (googleMapsEnabled) {
      _gmap?.animateCamera(
        g.CameraUpdate.newLatLngBounds(
          g.LatLngBounds(
            southwest: g.LatLng(
              s.latitude < t.latitude ? s.latitude : t.latitude,
              s.longitude < t.longitude ? s.longitude : t.longitude,
            ),
            northeast: g.LatLng(
              s.latitude > t.latitude ? s.latitude : t.latitude,
              s.longitude > t.longitude ? s.longitude : t.longitude,
            ),
          ),
          72,
        ),
      );
      return;
    }
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: [s, t],
        padding: const EdgeInsets.all(72),
        maxZoom: 18,
      ),
    );
  }

  /// Puts the active pin where the centre crosshair is.
  void _placeAtCentre() =>
      _onTap(googleMapsEnabled ? _gCenter : _map.camera.center);

  void _onTap(LatLng p) {
    setState(() {
      if (_pick == _Pick.shooter) {
        _shooter = p;
        _pick = _Pick.target;
      } else {
        _target = p;
      }
    });
  }

  double? get _distanceM {
    final s = _shooter, t = _target;
    if (s == null || t == null) return null;
    return FieldCalc.haversineM(
      s.latitude,
      s.longitude,
      t.latitude,
      t.longitude,
    );
  }

  double? get _bearing {
    final s = _shooter, t = _target;
    if (s == null || t == null) return null;
    return FieldCalc.bearingDeg(
      s.latitude,
      s.longitude,
      t.latitude,
      t.longitude,
    );
  }

  static const _names = ['K', 'KD', 'D', 'GD', 'G', 'GB', 'B', 'KB'];
  static String _dir(double deg) => _names[((deg % 360) / 45).round() % 8];

  Widget _googleMap(MenzilColors c, double? dist) {
    final s = _shooter, t = _target;
    return g.GoogleMap(
      key: const Key('map-view'),
      mapType: g.MapType.hybrid,
      initialCameraPosition: g.CameraPosition(target: _g(_gCenter), zoom: 6),
      onMapCreated: (controller) {
        _gmap = controller;
        // The location may have arrived before the map existed.
        final start = _shooter;
        if (start != null) _moveTo(start, 17);
      },
      onCameraMove: (p) =>
          _gCenter = LatLng(p.target.latitude, p.target.longitude),
      onTap: (p) => _onTap(LatLng(p.latitude, p.longitude)),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      markers: {
        if (s != null)
          g.Marker(
            markerId: const g.MarkerId('shooter'),
            position: _g(s),
            icon: g.BitmapDescriptor.defaultMarkerWithHue(
              g.BitmapDescriptor.hueOrange,
            ),
            infoWindow: const g.InfoWindow(title: 'Nişancı'),
            onTap: () => setState(() => _pick = _Pick.shooter),
          ),
        if (t != null)
          g.Marker(
            markerId: const g.MarkerId('target'),
            position: _g(t),
            icon: g.BitmapDescriptor.defaultMarkerWithHue(
              g.BitmapDescriptor.hueRed,
            ),
            infoWindow: g.InfoWindow(
              title: dist == null
                  ? 'Hedef'
                  : 'Hedef · ${ToolFormat.dec(dist, 0)} m',
            ),
            onTap: () => setState(() => _pick = _Pick.target),
          ),
      },
      polylines: {
        if (s != null && t != null)
          g.Polyline(
            polylineId: const g.PolylineId('line'),
            points: [_g(s), _g(t)],
            color: c.amber,
            width: 3,
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final active = _pick == _Pick.shooter ? _shooter : _target;
    final dist = _distanceM;
    final bearing = _bearing;

    Widget info(String label, String value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$label: '),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: TextStyle(color: c.ink, fontSize: 14),
        ),
      ),
    );

    Widget pin(IconData icon, Color color, bool selected, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.black54,
                    width: selected ? 3 : 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Container(width: 3, height: 12, color: color),
            ],
          ),
        );

    final s = _shooter, t = _target;
    final marker = <Marker>[
      if (s != null && t != null && dist != null)
        Marker(
          point: LatLng(
            (s.latitude + t.latitude) / 2,
            (s.longitude + t.longitude) / 2,
          ),
          width: 96,
          height: 30,
          child: Container(
            key: const Key('map-distance-label'),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.amber, width: 1.5),
            ),
            child: Text(
              '${ToolFormat.dec(dist, 0)} m',
              style: TextStyle(
                color: c.ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      if (s != null)
        Marker(
          point: s,
          width: 44,
          height: 52,
          alignment: Alignment.bottomCenter,
          child: pin(
            Icons.person,
            c.amber,
            _pick == _Pick.shooter,
            () => setState(() => _pick = _Pick.shooter),
          ),
        ),
      if (t != null)
        Marker(
          point: t,
          width: 44,
          height: 52,
          alignment: Alignment.bottomCenter,
          child: pin(
            Icons.gps_fixed,
            c.danger,
            _pick == _Pick.target,
            () => setState(() => _pick = _Pick.target),
          ),
        ),
    ];

    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Konum için mesafe'),
      body: Column(
        children: [
          Container(
            key: const Key('map-info'),
            width: double.infinity,
            color: c.surface2,
            padding: const EdgeInsets.symmetric(
              horizontal: MenzilSpace.gutter,
              vertical: MenzilSpace.sm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    info(
                      'Enlem',
                      active == null
                          ? '—'
                          : '${ToolFormat.dec(active.latitude, 4)}°',
                    ),
                    info(
                      'Mesafe',
                      dist == null
                          ? '—'
                          : '${ToolFormat.dec(dist, 0)} m (${ToolFormat.dec(dist / 0.9144, 0)} yd)',
                    ),
                  ],
                ),
                Row(
                  children: [
                    info(
                      'Boylam',
                      active == null
                          ? '—'
                          : '${ToolFormat.dec(active.longitude, 4)}°',
                    ),
                    info(
                      'Yön',
                      bearing == null
                          ? '—'
                          : '${ToolFormat.dec(bearing, 1)}° ${_dir(bearing)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (googleMapsEnabled)
                  _googleMap(c, dist)
                else
                FlutterMap(
                  key: const Key('map-view'),
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _turkey,
                    initialZoom: 6,
                    minZoom: 2,
                    maxZoom: 18,
                    onTap: (_, p) => _onTap(p),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapImageryUrl,
                      userAgentPackageName: 'com.sniperturk.sniperTurk',
                      // Esri has no imagery beyond about zoom 17 in many rural areas; deeper
                      // zoom levels stretch the zoom-17 tiles instead of showing gaps.
                      maxNativeZoom: 17,
                      tileProvider: widget.tileProvider,
                    ),
                    if (_shooter != null && _target != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_shooter!, _target!],
                            strokeWidth: 3,
                            color: c.amber,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: marker),
                    const SimpleAttributionWidget(
                      source: Text('Esri, Maxar, Earthstar Geographics'),
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.add,
                      key: const Key('map-crosshair'),
                      size: 44,
                      color: c.amber,
                      shadows: const [
                        Shadow(blurRadius: 3, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: MenzilSpace.md,
                  right: MenzilSpace.md,
                  top: MenzilSpace.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        color: c.surface,
                        child: TextField(
                          key: const Key('map-search'),
                          controller: _query,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _runSearch(),
                          style: TextStyle(color: c.ink),
                          decoration: InputDecoration(
                            hintText: 'Yerleri ara',
                            prefixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search),
                            suffixIcon: IconButton(
                              key: const Key('map-search-go'),
                              tooltip: 'Ara',
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _searching ? null : _runSearch,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: MenzilSpace.xs),
                          child: Material(
                            borderRadius: BorderRadius.circular(8),
                            color: c.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(MenzilSpace.md),
                              child: Text(
                                _searchMessage!,
                                key: const Key('map-search-message'),
                                style: TextStyle(color: c.ink2, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      if (_results.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: MenzilSpace.xs),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            color: c.surface,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ListView.separated(
                                key: const Key('map-search-results'),
                                shrinkWrap: true,
                                itemCount: _results.length,
                                separatorBuilder: (_, _) =>
                                    Divider(height: 1, color: c.line),
                                itemBuilder: (_, i) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    _results[i].name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: c.ink),
                                  ),
                                  onTap: () => _openResult(_results[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: MenzilSpace.md,
                  bottom: MenzilSpace.md,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_shooter != null || _target != null) ...[
                        FloatingActionButton.small(
                          key: const Key('map-clear'),
                          heroTag: 'map-clear',
                          tooltip: 'Konumları sıfırla',
                          onPressed: _reset,
                          child: const Icon(Icons.delete_outline),
                        ),
                        const SizedBox(height: MenzilSpace.sm),
                      ],
                      if (_shooter != null && _target != null) ...[
                        FloatingActionButton.small(
                          key: const Key('map-swap'),
                          heroTag: 'map-swap',
                          tooltip: 'Nişancı ve hedefi değiştir',
                          onPressed: _swap,
                          child: const Icon(Icons.swap_vert),
                        ),
                        const SizedBox(height: MenzilSpace.sm),
                        FloatingActionButton.small(
                          key: const Key('map-fit'),
                          heroTag: 'map-fit',
                          tooltip: 'İkisini de göster',
                          onPressed: _fit,
                          child: const Icon(Icons.zoom_out_map),
                        ),
                        const SizedBox(height: MenzilSpace.sm),
                      ],
                      FloatingActionButton.small(
                        key: const Key('map-locate'),
                        heroTag: 'map-locate',
                        tooltip: 'Konumumu nişancı yap',
                        onPressed: _locating ? null : _locate,
                        child: _locating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: c.bg,
            padding: const EdgeInsets.all(MenzilSpace.gutter),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (dist != null && dist > 3000)
                    const MenzilNotice(
                      tone: MenzilNoticeTone.warning,
                      message:
                          'Uygulama atış hesabını en fazla 3000 m için yapar; bu mesafe sınırı aşıyor.',
                    ),
                  if (_message != null)
                    MenzilNotice(
                      tone: MenzilNoticeTone.warning,
                      message: _message!,
                    ),
                  MenzilChipGroup<_Pick>(
                    options: [
                      (
                        _Pick.shooter,
                        _shooter == null
                            ? 'Nişancı konumu'
                            : '✓ Nişancı konumu',
                      ),
                      (
                        _Pick.target,
                        _target == null ? 'Hedef konumu' : '✓ Hedef konumu',
                      ),
                    ],
                    selected: _pick,
                    onSelected: (v) => setState(() => _pick = v),
                  ),
                  const SizedBox(height: MenzilSpace.sm),
                  FilledButton.icon(
                    key: const Key('map-place'),
                    onPressed: _placeAtCentre,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(
                      _pick == _Pick.shooter
                          ? 'Nişancıyı artıya koy'
                          : 'Hedefi artıya koy',
                    ),
                  ),
                  const SizedBox(height: MenzilSpace.sm),
                  Text(
                    _shooter == null
                        ? 'Haritayı kaydırıp yakınlaştırın, artıyı konumun üstüne getirip düğmeye basın (veya haritaya dokunun).'
                        : _target == null
                        ? 'Şimdi artıyı hedefin üstüne getirip düğmeye basın (veya haritaya dokunun).'
                        : 'Bir konumu değiştirmek için üstten seçip artıyla yeniden koyun. '
                              'Mesafe, iki nokta arası düz çizgidir; arazi eğimi hesaba katılmaz.',
                    style: TextStyle(color: c.ink2, fontSize: 13),
                  ),
                  if (widget.returnDistance) ...[
                    const SizedBox(height: MenzilSpace.sm),
                    FilledButton(
                      key: const Key('map-use'),
                      onPressed: dist == null
                          ? null
                          : () => Navigator.pop(context, dist),
                      child: const Text('Bu mesafeyi kullan'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
