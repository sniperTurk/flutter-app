part of 'profiles_screen.dart';

// Profile editor (Profil Oluştur / Profili Düzenle): state, checks, saving
// and the page frame. The Tüfek, Dürbün, Mühimmat and Ek mühimmat
// bilgileri sections are in profile_editor_*.dart (moved out of
// profiles_screen.dart, behaviour unchanged).

/// Default name for a new profile that does not repeat an existing one:
/// "Yeni Profil", then "Yeni Profil 2", "Yeni Profil 3", ...
String defaultProfileName(Set<String> taken) {
  const base = 'Yeni Profil';
  if (!taken.contains(base)) return base;
  var n = 2;
  while (taken.contains('$base $n')) {
    n++;
  }
  return '$base $n';
}

/// Full-screen profile editor (create / edit). Returns the validated profile
/// via `Navigator.pop`; persistence stays with the caller.
class _ProfileDialog extends StatefulWidget {
  final RifleProfile? initial;

  /// Names already used by saved profiles (for the new-profile default).
  final Set<String> takenNames;

  /// Rifle / ammunition / scope record ids other saved profiles point at.
  /// A personal record listed here is saved under a new id instead of being
  /// overwritten (PRF-2), so the other profile keeps its values.
  final Set<String> sharedRecordIds;
  const _ProfileDialog({
    this.initial,
    this.takenNames = const {},
    this.sharedRecordIds = const {},
  });

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  /// [setState] for the section extensions in the part files (Tüfek,
  /// Dürbün, Mühimmat, Ek mühimmat bilgileri): an extension may not call the
  /// protected [setState] itself.
  void _update(VoidCallback fn) => setState(fn);

  /// Records the profile pointed at when the editor opened (built-in or
  /// personal). They only prefill the forms; everything is typed in.
  final List<Rifle> _allRifles = CatalogRepository.allRifles;
  final List<Ammunition> _allAmmunition = CatalogRepository.allAmmunition;
  final List<ScopeOptic> _allScopes = CatalogRepository.allScopes;
  final ManualCatalogStore _manualStore = ManualCatalogStore();

  // A new profile starts on Ateşli Tüfek (owner, 2026-10-11).
  WeaponPlatform platform = WeaponPlatform.firearm;

  /// False while the Tür box of a new profile still says "Seçiniz" (owner,
  /// 2026-10-15: every list box starts on "Seçiniz"). Until a Tür is picked
  /// the form may still show the Ateşli Tüfek fields (the default above), but
  /// the profile cannot be saved: "Tür" is listed as missing (owner,
  /// 2026-10-15).
  bool _platformSet = true;

  /// The rifle is typed in by the user (catalog rifle data proved
  /// unreliable). On save it is written as a personal record and the profile
  /// points at it. An existing personal record is updated in place.
  Rifle? rifle;
  late final TextEditingController rifleBrand;
  late final TextEditingController rifleModel;
  late final TextEditingController rifleCaliber;

  /// Focus of the Ağırlık box (the form rebuilds on focus change).
  final FocusNode _grainFocus = FocusNode();

  /// Kalibre lists (owner, 2026-10-09). Firearm calibers are the ones of the
  /// app's firearm rifle/ammunition records.
  static const _pcpCalibers = Cartridges.pcp;

  /// Firearm cartridges, one per line, with the bullet diameter the
  /// solver uses (owner, 2026-10-11: one name per row, no free typing; .308
  /// is a 7.82 mm bullet, 7.62 is the bore). The first [_popularCount] are
  /// the common ones, the rest A-Z.
  static const _popularCount = Cartridges.popularCount;
  static const _firearmCartridges = Cartridges.firearm;

  /// The firearm cartridge chosen in the list (several share a diameter).
  String? _cartridge;

  static String? _cartridgeFor(double mm) {
    for (final (name, d) in _firearmCartridges) {
      if ((d - mm).abs() < 0.005) return name;
    }
    return null;
  }

  static const _otherCaliberKey = '!other';
  static const _noCartridgeKey = '!nodia';

  /// The usual short form of a long cartridge name for the half-width
  /// Kalibre box (".338-378 Weatherby Mag" → ".338-378 Wby Mag").
  static String _shortCartridge(String name) => name
      .replaceAll('Weatherby', 'Wby')
      .replaceAll('Ackley Improved', 'AI')
      .replaceAll(' Springfield', '');

  /// "Fişeğim listede yok": the bullet diameters of the list, one per inch
  /// size (.224 in · 5,69 mm), smallest first.
  static final List<double> _bulletDiameters = () {
    final seen = <String>{};
    final out = <double>[];
    final all = [for (final (_, d) in Cartridges.firearm) d]..sort();
    for (final d in all) {
      final inch = UnitSystem.millimetersToInches(d).toStringAsFixed(3);
      if (seen.add(inch)) out.add(d);
    }
    return out;
  }();

  static String _diameterLabel(double mm) =>
      '.${UnitSystem.millimetersToInches(mm).toStringAsFixed(3).split('.').last} in · '
      '${mm.toStringAsFixed(2).replaceAll('.', ',')} mm';

  // ---- Tüfek Marka / Model / Kalibre lists (owner, 2026-10-11) ----

  /// True after "Listede yok": Marka and Model are typed.
  bool _rifleManual = false;

  /// The chosen rifle variant (one caliber of a model), or null.
  LibraryRifle? _rifleVariant;

  /// Kalibre: the whole cartridge list instead of the model's calibers.
  bool _caliberAll = false;

  /// Kalibre "Fişeğim listede yok": the bullet diameter is picked instead.
  bool _caliberByDiameter = false;

  /// Kimlik "Üretim": true = Yerli, false = İthal, null = all (owner,
  /// 2026-10-11). Filters the rifle Marka list.
  bool? _domestic;

  /// Rifle brands made in Türkiye.
  static const _domesticBrands = {
    'ATA Arms',
    'Aselkon Arms',
    'Balıklı',
    'Derya',
    'Effecto',
    'Ekol',
    'Hatsan',
    'Huğlu',
    'İstanbul Silah',
    'Kale Kalıp',
    'Kral Arms',
    'Kuzey Arms',
    'MKE',
    'Niksan Defence',
    'Retay',
    'Reximex',
    'Sarsılmaz',
    'Utaş Arms',
  };

  static int _byName(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  /// "6.5 Creedmoor", or with the barrel / twist when the model has the
  /// same caliber more than once.
  static String _variantLabel(LibraryRifle r, List<LibraryRifle> all) {
    if (all.where((v) => v.cartridge == r.cartridge).length < 2) {
      return r.cartridge;
    }
    final parts = <String>[r.cartridge];
    final b = r.barrelLengthMm;
    if (b != null) {
      final inch = UnitSystem.millimetersToInches(b);
      parts.add(
        '${inch.toStringAsFixed((inch - inch.round()).abs() < 0.05 ? 0 : 1)} in namlu',
      );
    }
    final t = r.twistRateIn;
    if (t != null) parts.add('1:${_trimDot(t)}');
    return parts.join(' · ');
  }

  // ---- Dürbün Marka / Model / Retikül lists (owner, 2026-10-11) ----

  /// True after "Aradığın dürbün listede yok mu?": the scope is typed in.
  bool _scopeManual = false;
  String? _scopeBrandSel;

  /// "Listede yok" in the scope Marka list, hidden (owner, 2026-10-13:
  /// "gizle, silme"); the link under the card opens the typed entry.
  static const bool _showScopeListedeYok = bool.fromEnvironment(
    'SCOPE_LISTEDE_YOK',
  );

  /// Profili Düzenle: the saved scope was found in the lists only by the
  /// tolerant rule (older naming, #235); its saved values are kept.
  bool _scopeTolerant = false;

  /// The catalog record the scope values came from (null: none chosen or a
  /// typed scope). Its missing values decide which hidden boxes show.
  ScopeOptic? _scopeRecord;

  /// Profili Düzenle of a catalog scope: Birim / Odak / Tüp / Büyütme stay
  /// hidden until Marka changes (owner, 2026-10-13).
  bool _scopeFiltersHidden = false;

  /// The chosen model: the catalog model without its reticle name.
  String? _scopeModelKey;

  static List<ScopeOptic> get _scopeLib => [
    for (final s in CatalogRepository.scopes)
      if (!s.userEntered) s,
  ];

  /// Reticle names of a record ("VPR-MIL / VHR-MIL" is two).
  static List<String> _reticlesOf(ScopeOptic s) =>
      ReticleCatalog.options(s.reticle);

  /// "Talos HMR 4-16x56 Center-X SFP MOA" -> "Talos HMR 4-16x56 SFP MOA":
  /// the reticles of one model are listed under Retikül.
  static String _scopeModelOf(ScopeOptic s) {
    var m = s.model;
    for (final r in _reticlesOf(s)) {
      final i = m.toLowerCase().indexOf(r.toLowerCase());
      if (i >= 0) m = m.substring(0, i) + m.substring(i + r.length);
    }
    return m.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  // ---- Dürbün filters (owner, 2026-10-13): what the user reads on the
  // scope or its box, narrowing step by step ("süzerek gider"): Marka →
  // Birim | Odak → Tüp | Büyütme → Model (no Objektif filter). Each list offers only
  // the values the scopes left over have, so the Model list is never empty.
  // "Seçiniz" = no filter.
  AngularUnit? _scopeUnitFilter;
  bool? _scopeFfpFilter;
  double? _scopeTubeFilter;
  String? _scopeMagFilter;

  static String _num(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toString().replaceAll('.', ',');

  static String _unitName(AngularUnit u) => switch (u) {
    AngularUnit.mrad => 'MRAD',
    AngularUnit.moa => 'MOA',
    AngularUnit.smoa => 'SMOA',
  };

  /// The magnification range as printed on the scope, e.g. "5-30x".
  static String? _magRange(ScopeOptic s) {
    final lo = s.minMagnification, hi = s.maxMagnification;
    if (hi == null) return null;
    return lo == null || lo == hi ? '${_num(hi)}x' : '${_num(lo)}-${_num(hi)}x';
  }

  // ---- Dürbün values from lists (owner, 2026-10-11: select over typing).
  // Standard values of real scopes; a stored value outside the list is
  // added to it so an older profile still shows what it saved.

  /// Minimum büyütme: 1-6, 1.5-6, 2.5-15, 3-9, 4-16, 5-25, 6-24 …
  static const _minMagOptions = <double>[
    1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 7, 8, 10, 12, //
  ];

  /// Maksimum büyütme (a fixed-power scope has min = max).
  static const _maxMagOptions = <double>[
    4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 24, 25, 27, 28, //
    30, 32, 35, 36, 40, 42, 45, 48, 50, 56, 60, //
  ];

  /// Mercek çapı, mm.
  static const _objectiveOptions = <double>[
    20, 24, 28, 30, 32, 33, 36, 40, 42, 44, 45, 50, 52, 54, 56, 58, 60, //
    62, 64, 72, //
  ];

  /// Klik değeri of the turret, by unit: 0,1 / 0,05 mrad; 1/4, 1/8, 1/2 MOA.
  static List<(double, String)> _clickOptions(AngularUnit u) {
    final name = u == AngularUnit.smoa ? 'SMOA' : 'MOA';
    return u.moaFamily
        ? [(0.25, '1/4 $name'), (0.125, '1/8 $name'), (0.5, '1/2 $name')]
        : const [(0.1, '0,1 MRAD'), (0.05, '0,05 MRAD')];
  }

  /// "Listede yok" in the rifle Marka list, hidden (owner, 2026-10-14:
  /// "gizle, silme"); the link under Marka | Model opens the typed entry.
  static const bool _showRifleListedeYok = bool.fromEnvironment(
    'RIFLE_LISTEDE_YOK',
  );

  static String _trimDot(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
  late final TextEditingController rifleTwist;
  TwistDirection? twistDirection;

  /// The scope is typed in too; stored as a personal scope record.
  late final TextEditingController scopeBrand;
  late final TextEditingController scopeMinMag;
  late final TextEditingController scopeMaxMag;
  late final TextEditingController scopeObjective;
  late final TextEditingController scopeClick;

  /// "Üst kule klik sayısı": total clicks of the top turret; optional. The
  /// side turret's travel is not asked (owner: it is not needed).
  late final TextEditingController scopeTravelElevation;

  /// true = FFP, false = SFP, null = not chosen yet.
  bool? firstFocalPlane;

  /// Ammunition is typed in too. A BC with its G1/G7 model lets the drag
  /// solver compute wind drift (the vacuum baseline keeps wind locked).
  late final TextEditingController ammoBrand;

  /// Mühimmat Model, separate from Marka (owner, 2026-10-11).
  late final TextEditingController ammoModel;

  /// True: Marka/Model are typed ("Listede yok"); false: picked from the
  /// library lists (owner, 2026-10-11: typed names are mistyped).
  bool _ammoManual = false;

  /// Typed firearm ammunition (owner, 2026-10-14): Marka is picked from
  /// every known brand; "Diğer" ([_ammoBrandOther]) opens the typed box.
  /// Ağırlık is picked from the maker weights of this Kalibre; "Listede
  /// yok" ([_grainOther]) opens a typed grain box with a plausibility range.
  bool _ammoBrandOther = false;
  bool _grainOther = false;
  late final TextEditingController ammoGrain;

  /// PCP projectile length in mm. Its box is shown only with
  /// PROFILE_AMMO_LENGTH; the value is still saved and loaded, but the
  /// calculation reads only Pro > Mermi uzunluğu (owner, 2026-10-13).
  late final TextEditingController ammoLength;
  late final TextEditingController ammoBc;

  /// Hıza göre BC (çoklu BC, owner 2026-10-09): up to two steps "below
  /// this speed (fps) the BC is …". Empty rows = single BC.
  late final List<TextEditingController> ammoBandFps;
  late final List<TextEditingController> ammoBandBc;
  AmmunitionType? ammoType;
  BallisticModel? ammoBcModel;

  /// BC modeli "Özel eğri (Mach–Cd)": the bullet's own drag curve replaces
  /// BC, BC model and the speed bands (owner, 2026-10-10).
  bool _customCurve = false;
  List<DragSample>? _dragCurve;
  static const _customKey = 'custom';
  bool _saving = false;
  Ammunition? ammo;
  ScopeOptic? scope;
  late final TextEditingController name;
  final FocusNode _nameFocus = FocusNode();
  String _defaultName = '';
  late final TextEditingController velocity;
  late final TextEditingController zero;
  late final TextEditingController sight;

  /// Barut sıcaklığı (firearms): % per 15 °C and the air temperature (°C)
  /// the velocity was measured at, as typed. [_powderAutoFilled]: the boxes
  /// hold the maker's figure of the picked factory round, so another pick
  /// replaces them; typed values are never cleared by a pick.
  late final TextEditingController powderCoef;
  late final TextEditingController powderTemp;
  bool _powderAutoFilled = false;

  /// PCP tüp ve regülatör basıncı (bar) and basınca göre hız rows (bar |
  /// fps), as typed; PCP only, all optional (owner, 2026-10-12). An empty
  /// regülatör basıncı means an unregulated rifle.
  late final TextEditingController tubePressure;
  late final TextEditingController regulatorPressure;
  late final List<TextEditingController> pvBar;
  late final List<TextEditingController> pvFps;

  /// Dürbün ayağı in MOA, picked from [ProductionLimits.mountCantOptionsMoa].
  late double mountCant;
  String? validationError;
  late AngularUnit angularUnit;

  /// Retikül (owner, 2026-10-10): a catalog reticle name or one of
  /// [Reticles.genericNames]; null = not chosen (plain marks).
  String? scopeReticle;

  /// Metre or yard for the zero (and every distance of this profile).
  late DistanceUnit distanceUnit;

  /// A new profile shows "Seçiniz" in every list box until the user picks
  /// (owner, 2026-10-11); the stored default only keeps the form working.
  /// An edited profile starts with everything chosen.
  bool _distanceUnitSet = true;
  bool _angularUnitSet = true;
  bool _mountCantSet = true;
  bool _ammoSourceSet = true;

  /// Editing an existing profile is fail-closed: a stored reference that no
  /// longer resolves is NEVER replaced by another record. Its form is left
  /// empty, the user is told, and saving stays disabled until they type the
  /// values in. Rifle, ammunition and scope are all typed in (no defaults).
  final List<String> _unresolved = <String>[];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    final initialRifle = p == null
        ? null
        : _allRifles.where((r) => r.id == p.rifleId).firstOrNull;
    rifle = initialRifle;
    ammo = p == null
        ? null
        : _allAmmunition.where((a) => a.id == p.ammunitionId).firstOrNull;
    // Platform of an unresolved rifle comes from its ammunition, else PCP.
    // (It used to be guessed from the pressure, but new PCP profiles carry
    // no pressure since 2026-10-09, so "no pressure" no longer means
    // firearm.)
    platform = p == null
        ? WeaponPlatform.firearm
        : initialRifle?.platform ?? ammo?.platform ?? WeaponPlatform.pcp;
    scope = p == null
        ? null
        : _allScopes.where((o) => o.id == p.scopeId).firstOrNull;
    String num(double? v) =>
        v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());
    rifleBrand = TextEditingController(text: initialRifle?.brand ?? '');
    rifleModel = TextEditingController(text: initialRifle?.model ?? '');
    rifleCaliber = TextEditingController(text: num(initialRifle?.caliberMm));
    _cartridge = initialRifle == null
        ? null
        : RiflePickerScreen.cartridgeName(initialRifle);
    _grainFocus.addListener(() => setState(() {}));
    rifleTwist = TextEditingController(text: num(initialRifle?.twistRateIn));
    twistDirection = initialRifle?.twistDirection;
    // A saved rifle of the lists comes back in the lists; anything else in
    // the typed boxes (owner, 2026-10-11).
    if (rifleBrand.text.isNotEmpty) {
      var known = _rifleLib.any(
        (r) => r.brand == rifleBrand.text && r.model == rifleModel.text,
      );
      // Saved before the list names changed (#235, owner 2026-10-14):
      // matched tolerantly by Marka + Model, then the caliber. Marka and
      // Model take the list's spelling; the saved caliber and yiv stay.
      if (!known) {
        final match = ProfileCatalogMatch.rifle(
          rifleBrand.text,
          rifleModel.text,
          initialRifle?.caliberMm,
          _rifleLib,
        );
        if (match != null) {
          rifleBrand.text = match.brand;
          rifleModel.text = match.model;
          known = true;
        }
      }
      _rifleManual = !known;
      if (known) {
        // Üretim shows the saved rifle's origin, not "Seçiniz" (owner,
        // 2026-10-13). The rifle's brand is in the list of its own origin,
        // so Marka and Model keep their values. A typed rifle stays null.
        _domestic = _domesticBrands.contains(rifleBrand.text);
        _rifleVariant = _variantFor(
          rifleBrand.text,
          rifleModel.text,
          initialRifle?.caliberMm,
        );
        if (_rifleVariant != null) {
          _cartridge = _rifleVariant!.platform == WeaponPlatform.firearm
              ? _rifleVariant!.cartridge
              : null;
        } else {
          _caliberAll = true;
        }
      }
    }
    final s0 = scope;
    // A catalog scope comes back in the lists; a typed one in the typed box.
    if (s0 != null) {
      ScopeOptic? hit = s0.userEntered
          ? _scopeLib
                .where(
                  (r) =>
                      '${r.brand} ${ScopePickerScreen.seriesOf(_scopeModelOf(r))}'
                              .trim() ==
                          s0.brand.trim() &&
                      r.minMagnification == s0.minMagnification &&
                      r.maxMagnification == s0.maxMagnification &&
                      r.objectiveDiameterMm == s0.objectiveDiameterMm &&
                      (s0.reticle == null ||
                          _reticlesOf(r).contains(s0.reticle)),
                )
                .firstOrNull
          : s0;
      // Saved before the 13 Oct catalog update (#235) or under an older
      // naming (owner, 2026-10-14): matched tolerantly by Marka + series,
      // then büyütme / mercek çapı / odak / birim. The exact rule above
      // still goes first.
      if (hit == null && s0.userEntered) {
        hit = ProfileCatalogMatch.scope(s0, _scopeLib, _scopeModelOf);
        if (hit != null) _scopeTolerant = true;
      }
      if (hit == null) {
        _scopeManual = true;
      } else {
        _scopeBrandSel = hit.brand;
        _scopeModelKey = _scopeModelOf(hit);
        _scopeRecord = hit;
        // Profili Düzenle of a catalog scope: no filter boxes (owner,
        // 2026-10-13); they come back when Marka changes.
        _scopeFiltersHidden = true;
      }
    }
    angularUnit = p?.angularUnit ?? s0?.clickUnit ?? AngularUnit.mrad;
    // A built-in record carries its series in Model; the list shows (and
    // saves) "Marka Seri" as a new pick does, so the saved copy comes back
    // in the lists after a save (owner, 2026-10-14).
    final rec = _scopeRecord;
    final series = s0 != null && !s0.userEntered && rec != null
        ? ScopePickerScreen.seriesOf(_scopeModelOf(rec))
        : '';
    scopeBrand = TextEditingController(
      text: series.isEmpty ? (s0?.brand ?? '') : '${rec!.brand} $series',
    );
    // A tolerant match keeps every saved value; only a value the saved
    // record lacks is taken from the list record (nothing is overwritten).
    final fill = _scopeTolerant ? rec : null;
    scopeMinMag = TextEditingController(
      text: num(s0?.minMagnification ?? fill?.minMagnification),
    );
    scopeMaxMag = TextEditingController(
      text: num(s0?.maxMagnification ?? fill?.maxMagnification),
    );
    scopeObjective = TextEditingController(
      text: num(
        fill != null && (s0?.objectiveDiameterMm ?? 0) <= 0
            ? fill.objectiveDiameterMm
            : s0?.objectiveDiameterMm,
      ),
    );
    scopeClick = TextEditingController(
      text: s0 != null && s0.clickUnit == angularUnit
          ? num(s0.clickValue)
          : num(_defaultClick(angularUnit)),
    );
    firstFocalPlane = s0?.firstFocalPlane ?? fill?.firstFocalPlane;
    scopeReticle = s0?.reticle;
    // "Üst kule klik sayısı": total clicks from end to end of the top
    // turret, recovered from the stored travel with the SAME unit and click
    // the form saves with (a MRAD catalog scope on a MOA profile used to
    // come back 27 % shorter after a save).
    String travel(double? mrad) {
      final click = double.tryParse(scopeClick.text);
      if (mrad == null || mrad <= 0 || click == null || click <= 0) return '';
      return (_fromMrad(mrad, angularUnit) / click).round().toString();
    }

    scopeTravelElevation = TextEditingController(
      text: travel(s0?.elevationRangeMrad),
    );
    // An ammunition of the other rifle type (a PCP slug saved with a
    // firearm) is not shown; the user picks a bullet again.
    if (ammo != null && ammo!.platform != platform) ammo = null;
    final a0 = ammo;
    // Marka and Model are separate boxes again (owner, 2026-10-11); a
    // personal record that kept the whole name in the brand shows it there.
    ammoBrand = TextEditingController(text: a0?.brand ?? '');
    ammoModel = TextEditingController(text: a0?.model ?? '');
    // A saved ammunition of the lists comes back in the lists; anything
    // else in the typed boxes (owner, 2026-10-11).
    if (a0 != null) {
      final inFactory = FactoryAmmoLibrary.all.any(
        (f) => f.brand == a0.brand && f.name == a0.model,
      );
      final inLibrary = BulletLibrary.all.any(
        (b) =>
            b.platform == a0.platform &&
            b.brand == a0.brand &&
            _modelOf(b) == a0.model,
      );
      _factoryAmmo = inFactory || !inLibrary;
      _ammoManual = !inFactory && !inLibrary;
    }
    ammoGrain = TextEditingController(text: num(a0?.grain));
    // A saved typed firearm round comes back in the typed boxes with its
    // values: an unknown brand as "Diğer" + typed, an unlisted weight as
    // "Listede yok" + typed (owner, 2026-10-14).
    if (a0 != null && _ammoManual && platform == WeaponPlatform.firearm) {
      _ammoBrandOther =
          ammoBrand.text.isNotEmpty &&
          !_allFirearmAmmoBrands.contains(ammoBrand.text);
      _grainOther =
          a0.grain > 0 && !_caliberWeights.contains(_parse(ammoGrain));
    }
    ammoLength = TextEditingController(text: num(a0?.lengthMm));
    ammoBc = TextEditingController(text: num(a0?.ballisticCoefficient));
    // Stored bands are fastest first: [(s1, main), (s2, bc1), (0, bc2)].
    // Row i shows "below s(i+1) fps -> bc(i+1)".
    final bands = a0?.bcBands ?? const <BcBand>[];
    String fps(double mps) => UnitSystem.mpsToFps(mps).round().toString();
    ammoBandFps = [
      for (var i = 0; i < 2; i++)
        TextEditingController(
          text: i + 1 < bands.length ? fps(bands[i].minVelocityMps) : '',
        ),
    ];
    ammoBandBc = [
      for (var i = 0; i < 2; i++)
        TextEditingController(
          text: i + 1 < bands.length ? num(bands[i + 1].bc) : '',
        ),
    ];
    ammoType = a0?.type;
    // A PCP model picked without a BC is kept too (owner, 2026-10-14).
    ammoBcModel = a0?.ballisticModel ?? a0?.modelWithoutBc;
    _dragCurve = a0?.dragCurve;
    _customCurve = _dragCurve != null;
    // The stored "BC" of a curve is the sectional density; not shown.
    if (_customCurve) ammoBc.text = '';
    if (p != null) {
      if (rifle == null) _unresolved.add('tüfek');
      if (ammo == null) _unresolved.add('mühimmat');
      if (scope == null) _unresolved.add('dürbün');
    }
    name = TextEditingController(
      text: p?.name ?? defaultProfileName(widget.takenNames),
    );
    // New profile (owner, 2026-10-12): a tap on Profil adı clears the
    // default name; leaving it empty puts the default back.
    _defaultName = name.text;
    if (p == null) {
      _nameFocus.addListener(() {
        if (_nameFocus.hasFocus && name.text == _defaultName) {
          name.clear();
        } else if (!_nameFocus.hasFocus && name.text.trim().isEmpty) {
          name.text = _defaultName;
        }
      });
    }
    // Muzzle velocity is entered in fps on Profil (owner decision); the
    // profile keeps storing m/s, so every calculation is unchanged.
    velocity = TextEditingController(
      text: p == null ? '' : _fpsText(p.muzzleVelocityMps),
    );
    // New profiles start empty: no placeholder value is ever taken for the
    // user's data (owner, 2026-10-07: "250 m/s nereden geliyor?").
    distanceUnit = p?.distanceUnit ?? DistanceUnit.meter;
    if (p == null) {
      _platformSet = false;
      _distanceUnitSet = false;
      _angularUnitSet = false;
      _mountCantSet = false;
      _ammoSourceSet = false;
    }
    zero = TextEditingController(
      text: p == null
          ? ''
          : num(_round1(distanceUnit.fromMeters(p.zeroRangeM))),
    );
    sight = TextEditingController(text: p == null ? '' : num(p.sightHeightMm));
    // 0 = normal mount; old profiles have no value.
    mountCant = p?.mountCantMoa ?? 0;
    powderCoef = TextEditingController(
      text: p?.powderTempCoefPercentPer15C == null
          ? ''
          : _trimNum(p!.powderTempCoefPercentPer15C!),
    );
    powderTemp = TextEditingController(
      text: p?.powderTempReferenceC == null
          ? ''
          : _trimNum(p!.powderTempReferenceC!),
    );
    // An older PCP profile's pressure (regülatör basıncı since V379) comes
    // back in its box, so saving keeps it.
    regulatorPressure = TextEditingController(
      text: p?.pressureBar == null ? '' : _trimNum(p!.pressureBar!),
    );
    tubePressure = TextEditingController(
      text: p?.tubePressureBar == null ? '' : _trimNum(p!.tubePressureBar!),
    );
    final pv = p?.pressureVelocityTable ?? const <PressureVelocityPoint>[];
    pvBar = [
      for (var i = 0; i < PcpPressure.tableRows; i++)
        TextEditingController(text: i < pv.length ? _trimNum(pv[i].bar) : ''),
    ];
    pvFps = [
      for (var i = 0; i < PcpPressure.tableRows; i++)
        TextEditingController(text: i < pv.length ? _fpsText(pv[i].mps) : ''),
    ];
  }

  // ---- PCP tüp ve regülatör basıncı (owner, 2026-10-12) -----------------

  static const double _minPcpBar = 10;

  String? _optionalBarError(TextEditingController c) => c.text.trim().isEmpty
      ? null
      : _rangeError(c, _minPcpBar, ProductionLimits.maxPcpPressureBar);

  String? get _tubePressureError => _optionalBarError(tubePressure);

  String? get _regulatorPressureError {
    final e = _optionalBarError(regulatorPressure);
    if (e != null || regulatorPressure.text.trim().isEmpty) return e;
    final tube = _parse(tubePressure);
    if (_tubePressureError == null &&
        tube != null &&
        _parse(regulatorPressure)! >= tube) {
      return 'Tüp basıncından küçük olmalı.';
    }
    return null;
  }

  bool _pvRowEmpty(int i) =>
      pvBar[i].text.trim().isEmpty && pvFps[i].text.trim().isEmpty;

  String? _pvBarError(int i) {
    if (_pvRowEmpty(i)) return null;
    final e = _rangeError(
      pvBar[i],
      _minPcpBar,
      ProductionLimits.maxPcpPressureBar,
    );
    if (e != null) return e;
    for (var j = 0; j < i; j++) {
      if (_parse(pvBar[j]) == _parse(pvBar[i])) {
        return 'Bu basınç başka satırda var.';
      }
    }
    return null;
  }

  String? _pvFpsError(int i) =>
      _pvRowEmpty(i) ? null : _rangeError(pvFps[i], 100, 4900);

  bool get _pcpPressureValid {
    if (platform != WeaponPlatform.pcp) return true;
    if (_tubePressureError != null || _regulatorPressureError != null) {
      return false;
    }
    for (var i = 0; i < PcpPressure.tableRows; i++) {
      if (_pvBarError(i) != null || _pvFpsError(i) != null) return false;
    }
    return true;
  }

  /// Barut sıcaklığı is optional; given, both boxes and the bands of
  /// [PowderTemperature] apply.
  String? get _powderCoefError {
    final t = powderCoef.text.trim();
    if (t.isEmpty) {
      return powderTemp.text.trim().isEmpty ? null : 'Katsayıyı da girin.';
    }
    final v = _parse(powderCoef);
    if (v == null || v.abs() > PowderTemperature.maxCoef) {
      return '-10 ile 10 arasında bir değer girin.';
    }
    return null;
  }

  String? get _powderTempError {
    final t = powderTemp.text.trim();
    if (t.isEmpty) {
      return powderCoef.text.trim().isEmpty ? null : 'Sıcaklığı da girin.';
    }
    final v = _parse(powderTemp);
    if (v == null ||
        v < PowderTemperature.minTempC ||
        v > PowderTemperature.maxTempC) {
      return '-50 ile 60 arasında bir değer girin.';
    }
    return null;
  }

  bool get _powderValid =>
      platform != WeaponPlatform.firearm ||
      (_powderCoefError == null && _powderTempError == null);

  static String _fpsText(double mps) {
    final fps = UnitSystem.mpsToFps(mps);
    return fps.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }

  // 100–4900 fps (4900 fps ≈ 1494 m/s, inside the 1500 m/s production limit).
  String? get _velocityError => _rangeError(velocity, 100, 4900);
  String? get _zeroError => _rangeError(
    zero,
    1,
    distanceUnit.fromMeters(ProductionLimits.maxRangeM).floorToDouble(),
  );

  static double _round1(double v) => (v * 10).roundToDouble() / 10;

  /// The typed zero in metres (the profile stores and solves in metres).
  String get _zeroMetersText {
    final v = _parse(zero);
    return v == null ? zero.text : distanceUnit.toMeters(v).toString();
  }

  /// What is still missing, per section, in the order of the page. Shown
  /// above Kaydet so a disabled button always says why.
  List<String> get _missing {
    final out = <String>[];
    void section(String name, List<(bool, String)> checks) {
      final m = [
        for (final (ok, label) in checks)
          if (!ok) label,
      ];
      if (m.isNotEmpty) out.add('$name: ${m.join(', ')}');
    }

    // Same order as the form (owner, 2026-10-09).
    section('Tüfek', [
      (_platformSet, 'Tür'),
      (_brandError == null, 'Marka'),
      (_modelError == null, 'Model'),
      (_caliberError == null, 'Kalibre'),
      (_twistError == null, 'Yiv oranı'),
      (twistDirection != null, 'Yiv yönü'),
      (_validSight, 'Sight height'),
      (_distanceUnitSet, 'Mesafe birimi'),
      (_zeroError == null, 'Sıfırlama mesafesi'),
      (_velocityError == null, 'Namlu çıkış hızı'),
    ]);
    // Only boxes the user can see are named (owner, 2026-10-14): a catalog
    // scope not chosen yet is "Model", not the five hidden boxes its record
    // fills in.
    final listScope = _scopeFromList;
    section('Dürbün', [
      (_scopeBrandError == null, 'Marka'),
      if (listScope) (_scopeModelKey != null, 'Model'),
      if (_scopeMinMagShown) (_minMagError == null, 'Min. büyütme'),
      if (_scopeMaxMagShown) (_maxMagError == null, 'Maks. büyütme'),
      if (_scopeObjectiveShown) (_objectiveError == null, 'Mercek çapı'),
      if (_scopeFocalShown) (firstFocalPlane != null, 'Odak düzlemi'),
      if (_scopeUnitShown) (_angularUnitSet, 'Dürbün birimi'),
      (_mountCantSet, 'Dürbün ayağı'),
      // Asked for a typed scope; a catalog scope brings its own.
      if (!listScope) (_clickError == null, 'Klik değeri'),
      (_travelError(scopeTravelElevation) == null, 'Üst kule klik sayısı'),
    ]);
    section('Mühimmat', [
      if (platform == WeaponPlatform.firearm) (_ammoSourceSet, 'Mühimmat türü'),
      (_ammoBrandError == null, 'Marka'),
      if (_typedFirearmAmmo) (_ammoModelError == null, 'Model'),
      (_effectiveAmmoType != null, 'Tip'),
      (_grainError == null, 'Ağırlık'),
      if (platform == WeaponPlatform.pcp && _showProfileAmmoLength)
        (_lengthError == null, 'Uzunluk'),
      if (_customCurve)
        (_dragCurve != null, 'Sürüklenme eğrisi')
      else ...[
        (_bcError == null, 'BC'),
        (_bcModelForSave != null, 'BC modeli'),
        (_bandsValid, 'Hıza göre BC'),
      ],
      if (platform == WeaponPlatform.firearm) (_powderValid, 'Barut sıcaklığı'),
      if (platform == WeaponPlatform.pcp) (_pcpPressureValid, 'Basınç'),
    ]);
    return out;
  }

  static double _defaultClick(AngularUnit u) => u.standardClick;

  @override
  void dispose() {
    _nameFocus.dispose();
    rifleBrand.dispose();
    rifleModel.dispose();
    rifleCaliber.dispose();
    _grainFocus.dispose();
    rifleTwist.dispose();
    scopeBrand.dispose();
    scopeMinMag.dispose();
    scopeMaxMag.dispose();
    scopeObjective.dispose();
    scopeClick.dispose();
    scopeTravelElevation.dispose();
    ammoBrand.dispose();
    ammoModel.dispose();
    ammoGrain.dispose();
    ammoLength.dispose();
    ammoBc.dispose();
    powderCoef.dispose();
    powderTemp.dispose();
    tubePressure.dispose();
    regulatorPressure.dispose();
    for (final c in [...ammoBandFps, ...ammoBandBc, ...pvBar, ...pvFps]) {
      c.dispose();
    }
    name.dispose();
    velocity.dispose();
    zero.dispose();
    sight.dispose();
    super.dispose();
  }

  /// Total travel in mrad from a typed click count (clicks × click value).
  double? _travelMrad(TextEditingController c) {
    final clicks = _parse(c);
    final click = _parse(scopeClick);
    if (clicks == null || clicks <= 0 || click == null || click <= 0) {
      return null;
    }
    return _toMrad(clicks * click, angularUnit);
  }

  bool get _validSight {
    final v = double.tryParse(sight.text.replaceAll(',', '.'));
    return v != null && v > 0 && v < 300;
  }

  static double? _parse(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite ? v : null;
  }

  // Plausibility bounds for typed rifle data (application guardrails, not
  // claims about any rifle).
  static const _minCaliberMm = 2.0, _maxCaliberMm = 20.0;
  static const _minTwistIn = 3.0, _maxTwistIn = 80.0;

  String? _textError(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return 'Gerekli.';
    if (t.length > 100) return 'En fazla 100 karakter.';
    return null;
  }

  String? _rangeError(TextEditingController c, double min, double max) {
    if (c.text.trim().isEmpty) return 'Gerekli.';
    final v = _parse(c);
    if (v == null || v < min || v > max) {
      String f(double x) =>
          x % 1 == 0 ? x.toStringAsFixed(0) : '$x'.replaceAll('.', ',');
      return '${f(min)}–${f(max)} arasında bir değer girin.';
    }
    return null;
  }

  String? get _brandError => _textError(rifleBrand);
  String? get _modelError => _textError(rifleModel);
  String? get _caliberError =>
      _rangeError(rifleCaliber, _minCaliberMm, _maxCaliberMm);
  String? get _twistError => _rangeError(rifleTwist, _minTwistIn, _maxTwistIn);

  bool get _rifleValid =>
      _brandError == null &&
      _modelError == null &&
      _caliberError == null &&
      _twistError == null &&
      twistDirection != null;

  String? get _scopeBrandError => _textError(scopeBrand);
  String? get _minMagError => _rangeError(scopeMinMag, 1, 60);
  String? get _maxMagError {
    final e = _rangeError(scopeMaxMag, 1, 100);
    if (e != null) return e;
    final lo = _parse(scopeMinMag), hi = _parse(scopeMaxMag);
    if (lo != null && hi != null && hi < lo) {
      return 'Minimum büyütmeden küçük olamaz.';
    }
    return null;
  }

  String? get _objectiveError => _rangeError(scopeObjective, 10, 80);
  String? get _clickError => angularUnit.moaFamily
      ? _rangeError(scopeClick, 0.05, 1)
      : _rangeError(scopeClick, 0.01, 0.5);

  /// Turret travel is optional; when typed it must be plausible.
  String? _travelError(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    final v = _parse(c);
    if (v != null && v != v.roundToDouble()) return 'Tam sayı girin.';
    return _rangeError(c, 10, 3000);
  }

  static double _toMrad(double v, AngularUnit u) => u.toMrad(v);
  static double _fromMrad(double v, AngularUnit u) => u.fromMrad(v);

  bool get _scopeValid =>
      _travelError(scopeTravelElevation) == null &&
      _scopeBrandError == null &&
      _minMagError == null &&
      _maxMagError == null &&
      _objectiveError == null &&
      _clickError == null &&
      firstFocalPlane != null;

  /// PCP needs no Marka (owner, 2026-10-13: the brand adds nothing to the
  /// calculation); an empty one is saved as "Özel yapım".
  String? get _ammoBrandError =>
      platform == WeaponPlatform.pcp ? null : _textError(ammoBrand);

  /// Typed firearm ammunition needs its Model (owner, 2026-10-14: the same
  /// brand's other rounds would be mixed up otherwise).
  String? get _ammoModelError =>
      _typedFirearmAmmo ? _textError(ammoModel) : null;

  String? get _grainError =>
      _typedFirearmAmmo ? _typedGrainError : _rangeError(ammoGrain, 1, 800);

  // ---- Typed firearm ammunition (owner, 2026-10-14) ----------------------

  /// "Diğer" in the typed Marka list; "Listede yok" in the Ağırlık list.
  static const _otherKey = '__other';
  static const double _grainOtherKey = -1;

  /// Hız eşiğine göre BC for typed firearm ammunition, hidden (owner,
  /// 2026-10-14; hidden, not removed). Saved bands are kept and used.
  static const bool _showTypedBands = bool.fromEnvironment(
    'AMMO_BC_BANDS_TYPED',
  );

  /// The "Listede yok" item of the firearm ammo Marka list, hidden (owner,
  /// 2026-10-14): the typed entry opens from the "Aradığın mühimmat listede
  /// yok mu?" link instead.
  static const bool _showAmmoListedeYok = bool.fromEnvironment(
    'AMMO_LISTEDE_YOK',
  );

  /// Barut katsayısı (%/15 °C) and Hız ölçüm sıcaklığı (°C) lists.
  static const List<double> _powderCoefOptions = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, //
  ];
  static const List<double> _powderTempOptions = [
    -10, -5, 0, 5, 10, 15, 21, 25, 30, 35, 40, //
  ];

  /// Every firearm ammunition brand the app knows (factory rounds and the
  /// firearm bullets of the library), sorted.
  static final List<String> _allFirearmAmmoBrands = {
    for (final a in FactoryAmmoLibrary.all) a.brand,
    for (final b in BulletLibrary.all)
      if (b.platform == WeaponPlatform.firearm) b.brand,
  }.toList()..sort(_byName);

  String? _weightsKey;
  List<double> _weightsCache = const [];

  /// "168 gr (10,9 g)": grain with its gram equivalent, Turkish comma.
  static String _grainLabel(double grain) =>
      '${_trimNum(grain)} gr (${_gramText(grain)} g)';

  static String _gramText(double grain) =>
      (grain * 0.06479891).toStringAsFixed(1).replaceAll('.', ',');

  static const _implausibleGrain =
      'Bu ağırlık bu kalibre için mantıklı değil. Kutudaki değeri kontrol '
      'edin.';

  String? get _typedGrainError {
    if (_parse(rifleCaliber) == null) return 'Önce Kalibre seçin.';
    final g = _parse(ammoGrain);
    if (!_grainOther) {
      // Only a listed weight; a weight of another Kalibre (Kalibre changed
      // after the pick) is not taken silently.
      if (ammoGrain.text.trim().isEmpty) return 'Gerekli.';
      return g != null && _caliberWeights.contains(g)
          ? null
          : 'Ağırlığı listeden seçin.';
    }
    final e = _rangeError(ammoGrain, 1, 800);
    if (e != null) return e;
    final r = _typedGrainRange!;
    return g! < r.$1 || g > r.$2 ? _implausibleGrain : null;
  }

  /// Uzunluk is optional; a typed one must be a plausible pellet/slug.
  String? get _lengthError =>
      ammoLength.text.trim().isEmpty ? null : _rangeError(ammoLength, 1, 60);

  /// PCP: BC may be left empty (owner, 2026-10-12: most Turkish pellets
  /// publish none); a typed one is still range-checked.
  String? get _bcError =>
      platform == WeaponPlatform.pcp && ammoBc.text.trim().isEmpty
      ? null
      : _rangeError(ammoBc, 0.005, 1.5);

  /// PCP: the BC modeli the user picked; G1 while none is known (owner,
  /// 2026-10-14: "G1 seçili kalsın"). Firearm: as chosen, null = not yet.
  BallisticModel? get _bcModelForSave => platform == WeaponPlatform.pcp
      ? ammoBcModel ?? BallisticModel.g1
      : ammoBcModel;

  /// A band row is optional, but half a row (speed without BC or the other
  /// way round) is an error.
  String? _bandFpsError(int i) {
    final f = ammoBandFps[i], b = ammoBandBc[i];
    if (f.text.trim().isEmpty && b.text.trim().isEmpty) return null;
    final e = _rangeError(f, 100, 4000);
    if (e != null) return e;
    // Thresholds must fall row by row.
    if (i == 1 && _parse(ammoBandFps[0]) != null) {
      if (_parse(f)! >= _parse(ammoBandFps[0])!) {
        return '1. eşikten düşük olmalı.';
      }
    }
    return null;
  }

  String? _bandBcError(int i) {
    final f = ammoBandFps[i], b = ammoBandBc[i];
    if (f.text.trim().isEmpty && b.text.trim().isEmpty) return null;
    return _rangeError(b, 0.005, 1.5);
  }

  bool get _bandsValid {
    for (var i = 0; i < 2; i++) {
      if (_bandFpsError(i) != null || _bandBcError(i) != null) return false;
    }
    // Row 2 needs row 1.
    final r1 = ammoBandFps[0].text.trim().isNotEmpty;
    final r2 = ammoBandFps[1].text.trim().isNotEmpty;
    return r1 || !r2;
  }

  /// Bands to store: main BC from the first threshold up, each row below
  /// its threshold; the last band starts at 0.
  List<Map<String, double>> get _bandEntries {
    final rows = <(double, double)>[
      for (var i = 0; i < 2; i++)
        if (_parse(ammoBandFps[i]) != null && _parse(ammoBandBc[i]) != null)
          (
            UnitSystem.fpsToMps(_parse(ammoBandFps[i])!),
            _parse(ammoBandBc[i])!,
          ),
    ];
    final main = _parse(ammoBc);
    if (rows.isEmpty || main == null) return const [];
    return [
      {'mps': rows[0].$1, 'bc': main},
      for (var i = 0; i < rows.length; i++)
        {'mps': i + 1 < rows.length ? rows[i + 1].$1 : 0.0, 'bc': rows[i].$2},
    ];
  }

  /// PCP: pellet or slug must be chosen; firearms always use bullets.
  AmmunitionType? get _effectiveAmmoType => platform == WeaponPlatform.firearm
      ? AmmunitionType.bullet
      : (ammoType == AmmunitionType.bullet ? null : ammoType);

  bool get _ammoValid =>
      _ammoBrandError == null &&
      _ammoModelError == null &&
      _grainError == null &&
      (_customCurve
          ? _dragCurve != null && _curveSd != null
          : _bcError == null && _bandsValid && _bcModelForSave != null) &&
      _effectiveAmmoType != null &&
      _powderValid &&
      _pcpPressureValid;

  /// Sectional density for a custom curve, from the grain and the caliber.
  double? get _curveSd {
    final g = _parse(ammoGrain), d = _parse(rifleCaliber);
    if (g == null || d == null || g <= 0 || d <= 0) return null;
    return DragCurve.sectionalDensity(grain: g, diameterMm: d);
  }

  /// Show field errors only after the user typed something or tried to save.
  bool _showErrors = false;
  String? _shown(String? error, TextEditingController c) =>
      (_showErrors || c.text.isNotEmpty) ? error : null;

  /// A list box shows its error after a save attempt, or once [c] holds a
  /// picked value (Maksimum below Minimum).
  String? _shownSelect(String? error, [TextEditingController? c]) =>
      (_showErrors || (c != null && c.text.isNotEmpty)) ? error : null;

  /// True when saving may update [record] in place: a personal record no
  /// other profile points at. A shared one is written under a new id
  /// (PRF-2); catalog records are read-only.
  bool _ownsRecord(String? id, {required bool userEntered}) =>
      id != null && userEntered && !widget.sharedRecordIds.contains(id);

  Map<String, dynamic> _rifleEntry() {
    final existing = rifle;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
          : 'manual_rifle_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'rifle',
      'platform': platform.name,
      'brand': rifleBrand.text.trim(),
      'model': rifleModel.text.trim(),
      'caliberMm': _parse(rifleCaliber),
      'twistDirection': twistDirection!.name,
      'twistRateIn': _parse(rifleTwist),
      'sourceName': userCatalogSourceName,
    };
  }

  /// Length written with the ammunition: the typed box when shown, else
  /// the length this ammunition already had (unused by the calculation,
  /// which asks only Pro > Mermi uzunluğu).
  double? get _savedLengthMm =>
      _showProfileAmmoLength ? _parse(ammoLength) : ammo?.lengthMm;

  Map<String, dynamic> _ammoEntry() {
    final existing = ammo;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
          : 'manual_ammo_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'ammo',
      'platform': platform.name,
      'brand': ammoBrand.text.trim(),
      'model': ammoModel.text.trim(),
      // Caliber follows the rifle, so the pair can never mismatch.
      'caliberMm': _parse(rifleCaliber),
      'grain': _parse(ammoGrain),
      // Box hidden (owner, 2026-10-13 23:32): no new length is written; a
      // length saved before is kept so old data is not lost.
      if (platform == WeaponPlatform.pcp && _savedLengthMm != null)
        'lengthMm': _savedLengthMm,
      'ammoType': _effectiveAmmoType!.name,
      if (_customCurve) ...{
        'bc': _curveSd,
        'bcModel': BallisticModel.g1.name,
        'dragCurve': DragCurve.toJson(_dragCurve!),
      } else ...{
        'bc': _parse(ammoBc),
        'bcModel': _bcModelForSave!.name,
        if (_bandEntries.isNotEmpty) 'bcBands': _bandEntries,
      },
      'sourceName': userCatalogSourceName,
    };
  }

  Map<String, dynamic> _scopeEntry() {
    final existing = scope;
    final lo = _parse(scopeMinMag)!, hi = _parse(scopeMaxMag)!;
    return <String, dynamic>{
      'id':
          _ownsRecord(existing?.id, userEntered: existing?.userEntered == true)
          ? existing!.id
          : 'manual_scope_${DateTime.now().microsecondsSinceEpoch}',
      'kind': 'scope',
      'platform': platform.name,
      'brand': scopeBrand.text.trim(),
      'model': _scopeDesignation,
      'objectiveMm': _parse(scopeObjective),
      'click': _parse(scopeClick),
      'clickUnit': angularUnit.name,
      'focal': firstFocalPlane! ? 'ffp' : 'sfp',
      'minMag': lo,
      'maxMag': hi,
      'magnification': lo == hi
          ? '${_trimNum(lo)}x'
          : '${_trimNum(lo)}-${_trimNum(hi)}x',
      // Total turret travel in mrad (optional). Windage defaults to the
      // elevation travel, as on most spec sheets.
      'elevationRangeMrad': _travelMrad(scopeTravelElevation),
      if (scopeReticle != null) 'reticle': scopeReticle,
      'sourceName': userCatalogSourceName,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_rifleValid || !_ammoValid || !_scopeValid) {
      setState(() {
        _showErrors = true;
        validationError = !_rifleValid
            ? 'Tüfek bilgilerinde eksik veya hatalı alan var.'
            : !_ammoValid
            ? 'Mühimmat bilgilerinde eksik veya hatalı alan var.'
            : 'Dürbün bilgilerinde eksik veya hatalı alan var.';
      });
      return;
    }
    final velocityError = _velocityError;
    if (velocityError != null) {
      setState(() {
        _showErrors = true;
        validationError = 'Namlu çıkış hızı (fps): $velocityError';
      });
      return;
    }
    final mps = UnitSystem.fpsToMps(_parse(velocity)!);
    final ProfileInput input;
    try {
      input = ProfileInput.validate(
        name: name.text.trim().isEmpty ? _defaultName : name.text,
        muzzleVelocityText: mps.toString(),
        zeroRangeText: _zeroMetersText,
        sightHeightText: sight.text,
        platform: platform,
        // PCP only (ProfileInput drops them on a firearm): Regülatör
        // basıncı (empty = unregulated), Tüp basıncı, basınca göre hız.
        pressureText: regulatorPressure.text,
        tubePressureText: tubePressure.text,
        pressureTable: [
          for (var i = 0; i < PcpPressure.tableRows; i++)
            (pvBar[i].text, pvFps[i].text),
        ],
        mountCantMoa: mountCant,
        // Firearms only; ProfileInput drops it on PCP.
        powderCoefText: powderCoef.text,
        powderTempText: powderTemp.text,
      );
    } on FormatException catch (e) {
      setState(() => validationError = e.message);
      return;
    }
    // Profile values are valid: only now write the rifle record, so a
    // rejected profile never leaves a personal record behind.
    setState(() => _saving = true);
    final entry = _rifleEntry();
    final rifleId = entry['id'] as String;
    final scopeRecord = _scopeEntry();
    final scopeId = scopeRecord['id'] as String;
    final ammoRecord = _ammoEntry();
    final ammoId = ammoRecord['id'] as String;
    try {
      await _manualStore.upsert(entry);
      await _manualStore.upsert(ammoRecord);
      await _manualStore.upsert(scopeRecord);
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries(await _manualStore.all()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        validationError =
            'Tüfek bilgileri kaydedilemedi. Profil kaydedilmedi; tekrar deneyin.';
      });
      return;
    }
    if (!mounted) return;
    if (!CatalogRepository.allRifles.any((r) => r.id == rifleId) ||
        !CatalogRepository.allAmmunition.any((a) => a.id == ammoId) ||
        !CatalogRepository.allScopes.any((o) => o.id == scopeId)) {
      setState(() {
        _saving = false;
        validationError =
            'Tüfek, mühimmat veya dürbün kaydı okunamadı. Profil kaydedilmedi.';
      });
      return;
    }
    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    Navigator.pop(
      context,
      RifleProfile(
        id: id,
        name: input.name,
        rifleId: rifleId,
        ammunitionId: ammoId,
        scopeId: scopeId,
        muzzleVelocityMps: input.muzzleVelocityMps,
        zeroRangeM: input.zeroRangeM,
        sightHeightMm: input.sightHeightMm,
        pressureBar: input.pressureBar,
        tubePressureBar: input.tubePressureBar,
        pressureVelocityTable: input.pressureVelocityTable,
        angularUnit: angularUnit,
        distanceUnit: distanceUnit,
        mountCantMoa: input.mountCantMoa,
        powderTempCoefPercentPer15C: input.powderTempCoefPercentPer15C,
        powderTempReferenceC: input.powderTempReferenceC,
      ),
    );
  }

  /// Rebuilds the scope selects after "Listeden seç" (their initial value
  /// is read once).
  int _scopePickToken = 0;

  /// Bumped when the ammunition list is shown again, so its selects start
  /// fresh ("Seçiniz") instead of keeping "Listede yok".
  int _ammoListToken = 0;

  /// Firearm ammunition: true = Fabrika fişeği (Marka/Model fill weight,
  /// BC and velocity), false = El dolumu (the bullet library; the shooter
  /// types the chronograph velocity). Owner, 2026-10-11.
  bool _factoryAmmo = true;

  static String _factoryLabel(FactoryAmmo a) {
    final g = _trimDot(a.grain);
    return a.name.contains('$g gr') ? a.name : '${a.name} · $g gr';
  }

  static String _modelOf(LibraryBullet b) =>
      b.name.toLowerCase().startsWith(b.brand.toLowerCase())
      ? b.name.substring(b.brand.length).trim()
      : b.name;

  static const _manualKey = '__manual';

  /// PCP Marka | Model lists, hidden (owner, 2026-10-13: "Pellet marka
  /// bullet marka almanın hiç bir faydası yok"; hidden, not removed). PCP
  /// asks only Tip, Ağırlık and BC.
  static const bool _showPcpAmmoBrand = bool.fromEnvironment('PCP_AMMO_BRAND');

  /// PCP Mühimmat "Uzunluk", hidden (owner, 2026-10-13 23:32: "Profilden
  /// çıkartın"; hidden, not removed). The length is asked only in Pro >
  /// Mermi uzunluğu, so one value never lives in two places.
  static const bool _showProfileAmmoLength = bool.fromEnvironment(
    'PROFILE_AMMO_LENGTH',
  );

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final missing = _missing;
    final canSave =
        !_saving &&
        _rifleValid &&
        _ammoValid &&
        _scopeValid &&
        _validSight &&
        missing.isEmpty;

    return Scaffold(
      appBar: MenzilSubPageBar(
        title: widget.initial == null ? 'Profil Oluştur' : 'Profili Düzenle',
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.gutter,
              MenzilSpace.sm,
              MenzilSpace.gutter,
              MenzilSpace.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing.isNotEmpty) ...[
                  Text(
                    'Kaydetmek için eksik: ${missing.join(' · ')}',
                    key: const Key('profile-missing'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: MenzilType.caption(c.danger),
                  ),
                  const SizedBox(height: MenzilSpace.xs),
                ],
                Row(
                  children: [
                    Expanded(
                      child: MenzilSecondaryButton(
                        label: 'İptal',
                        expand: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: MenzilSpace.md),
                    Expanded(
                      flex: 2,
                      child: MenzilPrimaryButton(
                        label: widget.initial == null ? 'Kaydet' : 'Güncelle',
                        onPressed: canSave ? _save : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: MenzilPage(
        children: [
          if (validationError != null)
            MenzilNotice(
              tone: MenzilNoticeTone.danger,
              message: validationError!,
            ),
          if (_unresolved.isNotEmpty)
            MenzilNotice(
              tone: MenzilNoticeTone.warning,
              message:
                  'Bu profilin kayıtlı ${_unresolved.join(', ')} bilgisi katalogda bulunamadı. '
                  'Başka bir kayıt sessizce seçilmedi; lütfen ilgili alanları kendiniz doldurun.',
            ),
          const MenzilSectionHeader(
            'Kimlik',
            padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          ),
          MenzilCard(
            padding: const EdgeInsets.fromLTRB(
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.lg,
              MenzilSpace.xxs,
            ),
            child: MenzilFieldGrid(
              children: [
                MenzilFullWidth(
                  child: MenzilInput(
                    key: const Key('profile-name'),
                    controller: name,
                    focusNode: _nameFocus,
                    label: 'Profil adı',
                    keyboardType: TextInputType.text,
                    maxLength: ProductionLimits.maxProfileNameLength,
                  ),
                ),
                MenzilSelect<WeaponPlatform>(
                  key: const Key('profile-platform'),
                  label: 'Tür',
                  info: ProfileFieldInfo.platform,
                  initialValue: _platformSet ? platform : null,
                  items: WeaponPlatform.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e == WeaponPlatform.pcp
                                ? 'PCP Tüfek'
                                : 'Ateşli Tüfek',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    final changed = v != platform;
                    _platformSet = true;
                    platform = v!;
                    // Pellet/slug only exist on PCP; firearms use bullets.
                    if (platform == WeaponPlatform.firearm) ammoType = null;
                    // The ammunition belongs to the rifle type: an H&N slug
                    // must not stay in a firearm profile (owner,
                    // 2026-10-11). A rifle of the other type goes too.
                    if (changed) {
                      _clearAmmo();
                      _factoryAmmo = true;
                      // A rifle picked from the other type's lists goes.
                      if ((rifle != null && rifle!.platform != platform) ||
                          !_rifleManual) {
                        rifle = null;
                        rifleBrand.text = '';
                        rifleModel.text = '';
                      }
                      _rifleVariant = null;
                      _caliberAll = false;
                      _caliberByDiameter = false;
                    }
                    // A caliber of the other list does not carry over.
                    final cal = _parse(rifleCaliber);
                    if (cal != null && _caliberItem(cal) == null) {
                      rifleCaliber.text = '';
                    }
                    _cartridge = null;
                  }),
                ),
                KeyedSubtree(
                  key: const Key('rifle-origin'),
                  child: MenzilSelect<bool?>(
                    key: ValueKey('rifle-origin-$_domestic'),
                    info: ProfileFieldInfo.rifleOrigin,
                    label: 'Üretim',
                    initialValue: _domestic,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: true, child: Text('Yerli')),
                      DropdownMenuItem(value: false, child: Text('İthal')),
                    ],
                    onChanged: (v) => setState(() {
                      _domestic = v;
                      // A listed rifle of the other origin goes.
                      if (!_rifleManual &&
                          rifleBrand.text.isNotEmpty &&
                          !_rifleBrands.contains(rifleBrand.text)) {
                        final before = (rifleCaliber.text, _cartridge);
                        rifleBrand.text = '';
                        rifleModel.text = '';
                        _clearRifleChoice();
                        _keepAmmoInCaliber(before);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          ..._rifleSection(),
          ..._scopeSection(c),
          ..._ammoSection(c),
          ..._ammoExtraSection(c),
        ],
      ),
    );
  }
}
