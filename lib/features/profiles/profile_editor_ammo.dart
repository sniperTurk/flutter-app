part of 'profiles_screen.dart';

/// Mühimmat section of the profile editor: factory / library / typed
/// ammunition lists, the ammunition fields and the Mühimmat card (moved out
/// of profiles_screen.dart, behaviour unchanged).
extension _AmmoSection on _ProfileDialogState {
  // The editor's static members under their own names, so the moved
  // code reads exactly as it did inside the class (an extension does
  // not see the static members of its type unqualified).
  static List<String> get _allFirearmAmmoBrands =>
      _ProfileDialogState._allFirearmAmmoBrands;
  static const _byName = _ProfileDialogState._byName;
  static const _customKey = _ProfileDialogState._customKey;
  static const _factoryLabel = _ProfileDialogState._factoryLabel;
  static const _grainLabel = _ProfileDialogState._grainLabel;
  static const _grainOtherKey = _ProfileDialogState._grainOtherKey;
  static const _gramText = _ProfileDialogState._gramText;
  static const _manualKey = _ProfileDialogState._manualKey;
  static const _modelOf = _ProfileDialogState._modelOf;
  static const _otherKey = _ProfileDialogState._otherKey;
  static const _parse = _ProfileDialogState._parse;
  static const _showAmmoListedeYok = _ProfileDialogState._showAmmoListedeYok;
  static const _trimDot = _ProfileDialogState._trimDot;

  /// BC model choices per rifle type (owner, 2026-10-10: the other public
  /// BRL drag laws). A stored model of the other type stays selectable.
  List<(BallisticModel, String)> get _bcModelChoices {
    final list = platform == WeaponPlatform.firearm
        ? const [
            // G1 first, then by number (owner, 2026-10-13), the others
            // last.
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g2, 'G2'),
            (BallisticModel.g5, 'G5'),
            (BallisticModel.g6, 'G6'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.g8, 'G8'),
            (BallisticModel.gi, 'GI (Ingalls)'),
            (BallisticModel.ra4, 'RA4 (.22 LR rimfire)'),
          ]
        // PCP (owner, 2026-10-14 11:35/11:38): every standard table, G1
        // first; the ⓘ says which shape each one is.
        : const [
            (BallisticModel.g1, 'G1'),
            (BallisticModel.g7, 'G7'),
            (BallisticModel.g2, 'G2'),
            (BallisticModel.g5, 'G5'),
            (BallisticModel.g6, 'G6'),
            (BallisticModel.g8, 'G8'),
            (BallisticModel.gi, 'GI'),
            (BallisticModel.gs, 'GS'),
            (BallisticModel.ra4, 'RA4'),
          ];
    final m = ammoBcModel;
    if (m == null || list.any((e) => e.$1 == m)) return list;
    return [...list, (m, m.label)];
  }

  /// Firearm ammunition the shooter types (link or nothing listed here).
  bool get _typedFirearmAmmo =>
      platform == WeaponPlatform.firearm && (_ammoManual || _ammoListEmpty);

  /// The firearm Marka list has nothing for this Kalibre (Fabrika fişeği
  /// without a Kalibre lists every round, so it is never empty).
  bool get _ammoListEmpty {
    if (platform != WeaponPlatform.firearm) return false;
    if (_factoryAmmo) {
      return _parse(rifleCaliber) != null && _factoryHere.isEmpty;
    }
    return _libraryHere.isEmpty;
  }

  /// Maker weights (grain) in the app's data for this Kalibre: the factory
  /// rounds of the cartridge (else of the diameter) and the firearm library
  /// bullets of the diameter; unique, ascending. Empty without a Kalibre.
  List<double> get _caliberWeights {
    final cal = _parse(rifleCaliber);
    if (cal == null) return const [];
    final c = _cartridge;
    final key = '$cal|$c';
    if (key == _weightsKey) return _weightsCache;
    final set = <double>{
      for (final a in FactoryAmmoLibrary.all)
        if (c != null ? a.cartridge == c : (a.diameterMm - cal).abs() < 0.02)
          a.grain,
      for (final b in BulletLibrary.all)
        if (b.platform == WeaponPlatform.firearm &&
            (b.caliberMm - cal).abs() < 0.02)
          b.grain,
    };
    _weightsKey = key;
    return _weightsCache = set.toList()..sort();
  }

  /// Accepted typed weights for this Kalibre: 0,8 × lightest to 1,25 ×
  /// heaviest listed weight; without listed weights, a sectional density of
  /// 0,08–0,45 lb/in² (grain / (7000 · d²), d in inches).
  (double, double)? get _typedGrainRange {
    final cal = _parse(rifleCaliber);
    if (cal == null || cal <= 0) return null;
    final w = _caliberWeights;
    if (w.isNotEmpty) return (0.8 * w.first, 1.25 * w.last);
    return (
      EstimatedBc.grainForSectionalDensity(0.08, cal),
      EstimatedBc.grainForSectionalDensity(0.45, cal),
    );
  }

  /// "Federal Gold Medal · .308 Win · 168 gr (10,9 g) · BC 0,462 G1", once
  /// Marka, Model, Ağırlık, BC and BC modeli are valid; else null.
  String? get _typedAmmoSummary {
    if (!_typedFirearmAmmo || _customCurve) return null;
    final model = _bcModelForSave;
    final bc = _parse(ammoBc), g = _parse(ammoGrain);
    if (_ammoBrandError != null ||
        _ammoModelError != null ||
        _grainError != null ||
        _bcError != null ||
        model == null ||
        bc == null ||
        g == null) {
      return null;
    }
    final cal = _parse(rifleCaliber)!;
    final caliber = _cartridge ?? '${_trimNum(cal)} mm';
    final name = '${ammoBrand.text.trim()} ${ammoModel.text.trim()}';
    return '$name · $caliber · ${_grainLabel(g)} · '
        'BC ${_trimNum(bc)} ${model.name.toUpperCase()}';
  }

  /// Opens the typed entry from the "listede yok mu?" link. A PCP keeps its
  /// Tip (owner, 2026-10-16: Tip stays in its place above the typed boxes).
  void _openAmmoManual() {
    final type = ammoType;
    _clearAmmo();
    if (platform == WeaponPlatform.pcp) ammoType = type;
    _ammoManual = true;
  }

  /// A typed BC far outside every manufacturer BC of its kind in the
  /// library (owner, 2026-10-13: "1,2" for a 130 gr bullet). Bounds are
  /// the form factor i = SD / BC seen in lib/data/bullet_library.dart
  /// (2026-10-13), widened by about 10 %: firearm G1 0.36–4.15, G7
  /// 0.70–1.61, PCP slug G1 0.40–1.23, pellet G1 1.05–4.28. A warning,
  /// never a block.
  String? get _bcPlausibilityWarning {
    if (_customCurve) return null;
    final bc = _parse(ammoBc), grain = _parse(ammoGrain);
    final cal = _parse(rifleCaliber);
    if (bc == null || bc <= 0 || grain == null || cal == null || cal <= 0) {
      return null;
    }
    final model = _bcModelForSave;
    final type = _effectiveAmmoType;
    final (double lo, double hi)? range = switch ((platform, type, model)) {
      (WeaponPlatform.firearm, _, BallisticModel.g1) => (0.32, 4.6),
      (WeaponPlatform.firearm, _, BallisticModel.g7) => (0.63, 1.8),
      (WeaponPlatform.pcp, AmmunitionType.slug, BallisticModel.g1) => (
        0.36,
        1.4,
      ),
      (WeaponPlatform.pcp, AmmunitionType.pellet, BallisticModel.g1) => (
        0.95,
        4.7,
      ),
      _ => null,
    };
    if (range == null) return null;
    final i = EstimatedBc.sectionalDensity(grain, cal) / bc;
    if (i < range.$1) {
      return 'Bu BC, bu kalibre ve ağırlık için çok yüksek görünüyor. '
          'Kutudaki değeri kontrol edin; yanlışsa uzak mesafede düşüş '
          'olduğundan az hesaplanır.';
    }
    if (i > range.$2) {
      return 'Bu BC, bu kalibre ve ağırlık için çok düşük görünüyor. '
          'Kutudaki değeri kontrol edin.';
    }
    return null;
  }

  /// The BC plausibility warning, full width.
  Widget get _bcWarningNotice => MenzilFullWidth(
    child: MenzilNotice(
      key: const Key('ammo-bc-warning'),
      tone: MenzilNoticeTone.warning,
      message: _bcPlausibilityWarning!,
    ),
  );

  /// Back from typed ammunition to the list (owner, 2026-10-12): asks
  /// before the typed values go and keeps Tip, so the brand list shows the
  /// listed pellets or slugs of this Kalibre.
  Future<void> _backToAmmoList() async {
    final typed = [
      ammoBrand,
      ammoModel,
      ammoGrain,
      ammoLength,
      ammoBc,
    ].any((c) => c.text.trim().isNotEmpty);
    if (typed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Listeye dönülsün mü?'),
          content: const Text('Girdiğiniz mühimmat bilgileri silinecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Listeye dön'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    _update(() {
      final type = ammoType;
      _clearAmmo();
      ammoType = type;
      _ammoListToken++;
    });
  }

  /// Empties the ammunition part of the form (another rifle type).
  void _clearAmmo() {
    ammo = null;
    ammoBrand.text = '';
    ammoModel.text = '';
    _ammoManual = false;
    _ammoBrandOther = false;
    _grainOther = false;
    ammoGrain.text = '';
    ammoLength.text = '';
    ammoBc.text = '';
    ammoBcModel = null;
    ammoType = null;
    _customCurve = false;
    _dragCurve = null;
    for (var i = 0; i < 2; i++) {
      ammoBandFps[i].text = '';
      ammoBandBc[i].text = '';
    }
  }

  /// Fills the ammunition from a library record (list or library screen).
  void _applyBullet(LibraryBullet b, double? cal) {
    _ammoManual = false;
    {
      ammoBrand.text = b.brand;
      ammoModel.text = b.name.toLowerCase().startsWith(b.brand.toLowerCase())
          ? b.name.substring(b.brand.length).trim()
          : b.name;
      ammoGrain.text = _trimNum(b.grain);
      // No maker BC (2026-10-12): the box stays empty for the shooter's own.
      ammoBc.text = b.bc == null ? '' : _trimNum(b.bc!);
      ammoBcModel = b.model;
      // A library bullet carries its BC; one with a published measured
      // Cd–Mach curve also fills that curve (owner, 2026-10-11). The BC
      // stays filled for a switch back to G1/G7.
      final measured = MeasuredDragLookup.forBullet(b)?.samples;
      _customCurve = measured != null;
      _dragCurve = measured;
      if (platform == WeaponPlatform.pcp) ammoType = b.type;
      for (var i = 0; i < 2; i++) {
        final band = i < b.bands.length ? b.bands[i] : null;
        ammoBandFps[i].text = band == null ? '' : band.$1.toString();
        ammoBandBc[i].text = band == null ? '' : _trimNum(band.$2);
      }
      // The ammunition's caliber follows the rifle: a bullet of another
      // caliber sets it.
      if (cal == null || (cal - b.caliberMm).abs() > 0.02) {
        rifleCaliber.text = _trimDot(b.caliberMm);
        _cartridge = null;
      }
    }
  }

  /// PCP: no listed pellet or slug for this Kalibre and Tip.
  bool get _noPcpForCaliber =>
      platform == WeaponPlatform.pcp &&
      _parse(rifleCaliber) != null &&
      _libraryHere.isEmpty;

  /// Library records for this rifle type and caliber (Marka/Model lists).
  List<LibraryBullet> get _libraryHere {
    final cal = _parse(rifleCaliber);
    return [
      for (final b in BulletLibrary.all)
        if (b.platform == platform &&
            (cal == null || (b.caliberMm - cal).abs() < 0.02) &&
            (platform != WeaponPlatform.pcp ||
                ammoType == null ||
                b.type == ammoType))
          b,
    ];
  }

  /// Factory cartridges for the chosen Kalibre: the cartridge name when it
  /// is known, else the bullet diameter.
  List<FactoryAmmo> get _factoryHere {
    final cal = _parse(rifleCaliber);
    final c = _cartridge;
    // No Kalibre yet: every factory round, as El dolumu lists every bullet
    // (owner, 2026-10-11: Fabrika fişeği came up empty). Picking one fills
    // the Kalibre.
    return [
      for (final a in FactoryAmmoLibrary.all)
        if (c != null
            ? a.cartridge == c
            : cal == null || (a.diameterMm - cal).abs() < 0.02)
          a,
    ];
  }

  /// Fabrika fişeği with a Kalibre that has no listed round.
  bool get _noFactoryForCaliber =>
      platform == WeaponPlatform.firearm &&
      _factoryAmmo &&
      _parse(rifleCaliber) != null &&
      _factoryHere.isEmpty;

  /// The manufacturer note of the listed factory round now in the form
  /// (e.g. "BC G1/G7 etiketi olmadan verilmiş; G1 kabul edildi…"), added to
  /// the BC ⓘ (owner, 2026-10-11: "bilgi notu olacak"); for a round whose BC
  /// is the NATO standard bullet's, first how that BC was taken (2026-10-12).
  String get _factoryBcNote {
    for (final a in _factoryHere) {
      if (a.brand != ammoBrand.text || a.name != ammoModel.text) continue;
      var nato = '';
      if (a.bcSource == 'nato-standard') {
        final t = ProfileFieldInfo.bcNatoStandard(
          brand: a.brand,
          standard: a.bcStandard!,
          report: a.bcReport!,
          probable: a.bcProbable,
        );
        nato = '\n\n$t';
      }
      final note = a.note == null ? '' : '\n\nBu fişek: ${a.note}';
      // A listed factory round whose maker publishes no BC (2026-10-14).
      final noBc =
          a.bc == null && platform == WeaponPlatform.firearm && _factoryAmmo
          ? '\n\n${ProfileFieldInfo.bcFactoryNoBc}'
          : '';
      if (nato.isNotEmpty || note.isNotEmpty || noBc.isNotEmpty) {
        return nato + note + noBc;
      }
    }
    // A listed bullet / pellet whose maker publishes no BC (2026-10-12).
    if (!(platform == WeaponPlatform.firearm && _factoryAmmo)) {
      for (final b in _libraryHere) {
        if (b.bc == null &&
            b.brand == ammoBrand.text &&
            _modelOf(b) == ammoModel.text) {
          return '\n\nBu mermi: Üretici BC yayımlamıyor. Kendi atışlarınızdan '
              'bulduğunuz BC\'yi girin.';
        }
      }
    }
    return '';
  }

  /// MUH-1 (owner, 2026-10-15): BC modeli changed on a listed factory
  /// round with a maker BC: the maker's BC for the new model when the
  /// record has one, otherwise an empty box; never the other curve's number.
  void _factoryBcForModel() {
    if (platform != WeaponPlatform.firearm || !_factoryAmmo || _ammoManual) {
      return;
    }
    for (final a in _factoryHere) {
      if (a.brand != ammoBrand.text || a.name != ammoModel.text) continue;
      if (a.bc == null) return;
      final m = ammoBcModel;
      final bc = m == a.model
          ? a.bc
          : m == BallisticModel.g7
          ? a.bcG7
          : null;
      ammoBc.text = bc == null ? '' : _trimNum(bc);
      return;
    }
  }

  /// Fills the ammunition (and the velocity) from a factory cartridge.
  void _applyFactory(FactoryAmmo a) {
    _ammoSourceSet = true; // a listed factory round: Fabrika fişeği
    // Kalibre not chosen yet: the round tells it.
    if (_cartridge == null && rifleCaliber.text.trim().isEmpty) {
      _cartridge = a.cartridge;
      rifleCaliber.text = _trimDot(a.diameterMm);
    }
    _ammoManual = false;
    ammoBrand.text = a.brand;
    ammoModel.text = a.name;
    ammoGrain.text = _trimNum(a.grain);
    ammoBc.text = a.bc == null ? '' : _trimNum(a.bc!);
    ammoBcModel = a.model;
    _customCurve = false;
    _dragCurve = null;
    for (var i = 0; i < 2; i++) {
      ammoBandFps[i].text = '';
      ammoBandBc[i].text = '';
    }
    velocity.text = _trimNum(a.muzzleVelocityFps);
    // Barut sıcaklığı: the maker's figure when it publishes one; otherwise
    // only a previous automatic fill goes (typed values stay).
    final pt = FactoryPowderTempLibrary.lookup(a.brand, a.name);
    if (pt != null) {
      powderCoef.text = _trimNum(pt.coefPercentPer15C);
      powderTemp.text = _trimNum(pt.referenceTempC);
      _powderAutoFilled = true;
    } else if (_powderAutoFilled) {
      powderCoef.text = '';
      powderTemp.text = '';
      _powderAutoFilled = false;
    }
  }

  /// Marka | Model of the ammunition: two lists side by side (factory
  /// cartridges or the bullet library for this caliber); the typed boxes
  /// only after "Listede yok" or when nothing is listed here.
  List<Widget> _ammoNameFields({
    required Widget type,
    required Widget brandText,
    required Widget modelText,
  }) {
    final firearm = platform == WeaponPlatform.firearm;
    // Firearm: Mühimmat türü | Marka; PCP (owner, 2026-10-16, the approved
    // design): Tip | Marka. Model gets its own row on both.
    List<Widget> arrange(Widget brand, Widget model) => [
      type,
      brand,
      MenzilFullWidth(child: model),
    ];
    final factory = platform == WeaponPlatform.firearm && _factoryAmmo;
    final fHere = factory ? _factoryHere : const <FactoryAmmo>[];
    final lHere = factory ? const <LibraryBullet>[] : _libraryHere;
    // Without a Kalibre the factory list shows every round (picking one
    // fills the Kalibre), so it is never treated as empty.
    final noCaliber = factory && _parse(rifleCaliber) == null;
    final empty = !noCaliber && (factory ? fHere.isEmpty : lHere.isEmpty);
    if (firearm && (_ammoManual || empty)) {
      // Typed firearm round (owner, 2026-10-14): Marka from the list of
      // every known brand ("Diğer" types it), Model typed.
      final brandPick = KeyedSubtree(
        key: const Key('ammo-brand-pick'),
        child: MenzilSelect<String>(
          key: ValueKey(
            'ammo-brand-pick-$_ammoBrandOther-${_ammoBrandOther ? '' : ammoBrand.text}',
          ),
          label: 'Marka',
          hint: 'Seçiniz',
          info: empty
              ? '${ProfileFieldInfo.ammoBrandPick}\n\n'
                    '${ProfileFieldInfo.ammoNothingListed}'
              : ProfileFieldInfo.ammoBrandPick,
          initialValue: _ammoBrandOther
              ? _otherKey
              : (_allFirearmAmmoBrands.contains(ammoBrand.text)
                    ? ammoBrand.text
                    : null),
          items: [
            for (final b in _allFirearmAmmoBrands)
              DropdownMenuItem(value: b, child: Text(b)),
            const DropdownMenuItem(value: _otherKey, child: Text('Diğer')),
          ],
          errorText: _ammoBrandOther
              ? null
              : _shownSelect(_ammoBrandError, ammoBrand),
          onChanged: (v) => _update(() {
            if (v == null) return;
            final other = v == _otherKey;
            if (other && _ammoBrandOther) return;
            _ammoBrandOther = other;
            ammoBrand.text = other ? '' : v;
          }),
        ),
      );
      return [
        type,
        brandPick,
        if (_ammoBrandOther) ...[
          brandText,
          modelText,
        ] else
          MenzilFullWidth(child: modelText),
        if (!empty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ammo-back-to-list'),
                onPressed: _backToAmmoList,
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeye dön'),
              ),
            ),
          ),
      ];
    }
    if (_ammoManual || empty) {
      // PCP typed entry (owner, 2026-10-16): Tip stays on top, then the
      // typed Marka | Model side by side.
      return [
        MenzilFullWidth(child: type),
        brandText,
        modelText,
        if (!empty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ammo-back-to-list'),
                onPressed: _backToAmmoList,
                icon: const Icon(Icons.list_alt, size: 18),
                // "Listeden seç" read like a model list for a brand that is
                // not listed (owner, 2026-10-12).
                label: const Text('Listeye dön'),
              ),
            ),
          ),
      ];
    }
    final brands = {
      if (factory)
        for (final a in fHere) a.brand
      else
        for (final b in lHere) b.brand,
    }.toList()..sort(_byName);
    final brand = brands.contains(ammoBrand.text) ? ammoBrand.text : null;
    final labels = <String>[];
    final picks = <void Function()>[];
    var modelIndex = -1;
    if (factory) {
      for (final a in fHere) {
        if (a.brand != brand) continue;
        if (a.name == ammoModel.text && _parse(ammoGrain) == a.grain) {
          modelIndex = labels.length;
        }
        labels.add(_factoryLabel(a));
        picks.add(() => _applyFactory(a));
      }
    } else {
      for (final b in lHere) {
        if (b.brand != brand) continue;
        if (_modelOf(b) == ammoModel.text && _parse(ammoGrain) == b.grain) {
          modelIndex = labels.length;
        }
        final m = _modelOf(b);
        final g = '${_trimDot(b.grain)} gr';
        labels.add(m.contains(g) ? m : '$m · $g');
        picks.add(() => _applyBullet(b, _parse(rifleCaliber)));
      }
    }
    // PCP Marka (owner, 2026-10-16): always in its place; a list box that
    // waits ("Seçiniz", not tappable) until Tip is chosen, because the list
    // is the pellets or slugs of this Kalibre. The rule is in its ⓘ.
    final waitsForType = !firearm && ammoType == null;
    final brandSelect = KeyedSubtree(
      key: const Key('ammo-brand-select'),
      child: MenzilSelect<String>(
        key: ValueKey(
          'ammo-brand-select-${platform.name}-$factory-'
          '${rifleCaliber.text}-$brand-$_ammoListToken-$ammoType',
        ),
        label: 'Marka',
        hint: 'Seçiniz',
        info: firearm ? null : ProfileFieldInfo.pcpAmmoBrand,
        initialValue: brand,
        items: [
          for (final b in brands) DropdownMenuItem(value: b, child: Text(b)),
          // Firearm: hidden behind AMMO_LISTEDE_YOK (owner, 2026-10-14);
          // the link under Model opens the typed entry (PCP too since
          // 2026-10-16).
          if (firearm && _showAmmoListedeYok)
            const DropdownMenuItem(
              value: _manualKey,
              child: Text('Listede yok'),
            ),
        ],
        onChanged: waitsForType
            ? null
            : (v) => _update(() {
                if (v == _manualKey) {
                  _clearAmmo();
                  _ammoManual = true;
                  return;
                }
                ammoBrand.text = v ?? '';
                ammoModel.text = '';
              }),
      ),
    );
    final modelSelect = KeyedSubtree(
      key: const Key('ammo-model-select'),
      child: MenzilSelect<int>(
        key: ValueKey(
          'ammo-model-select-$factory-$brand-${rifleCaliber.text}-$modelIndex',
        ),
        label: 'Model',
        hint: 'Seçiniz',
        initialValue: modelIndex < 0 ? null : modelIndex,
        items: [
          for (final (k, text) in labels.indexed)
            DropdownMenuItem(value: k, child: Text(text, maxLines: 2)),
        ],
        onChanged: (k) {
          if (k == null) return;
          _update(picks[k]);
        },
      ),
    );
    return [
      ...arrange(brandSelect, modelSelect),
      // Owner, 2026-10-14: like the scope's link (#269), the typed firearm
      // round opens from here instead of a "Listede yok" item; the PCP
      // pellet or slug too since 2026-10-16.
      MenzilFullWidth(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('ammo-not-listed'),
            onPressed: () => _update(_openAmmoManual),
            child: const Text('Aradığın mühimmat listede yok mu?'),
          ),
        ),
      ),
    ];
  }

  /// Typed firearm Ağırlık (owner, 2026-10-14): the maker weights of this
  /// Kalibre as "168 gr (10,9 g)"; "Listede yok" adds a typed grain box
  /// under it that shows the grams and accepts only a plausible weight.
  /// Without a Kalibre only a notice (no free typing).
  List<Widget> _typedGrainFields() {
    final cal = _parse(rifleCaliber);
    if (cal == null) {
      return const [
        MenzilFullWidth(
          child: MenzilNotice(
            key: Key('ammo-grain-need-caliber'),
            tone: MenzilNoticeTone.info,
            message:
                'Ağırlık listesi kalibreye göre gelir. Önce Tüfek bölümünde '
                'Kalibre seçin.',
          ),
        ),
      ];
    }
    final weights = _caliberWeights;
    final g = _parse(ammoGrain);
    final select = KeyedSubtree(
      key: const Key('ammo-grain-select'),
      child: MenzilSelect<double>(
        key: ValueKey(
          'ammo-grain-select-$cal-$_grainOther-'
          '${_grainOther ? '' : ammoGrain.text}',
        ),
        label: 'Ağırlık',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.grainPick,
        initialValue: _grainOther
            ? _grainOtherKey
            : (g != null && weights.contains(g) ? g : null),
        items: [
          for (final w in weights)
            DropdownMenuItem(value: w, child: Text(_grainLabel(w))),
          const DropdownMenuItem(
            value: _grainOtherKey,
            child: Text('Listede yok'),
          ),
        ],
        errorText: _grainOther ? null : _shownSelect(_grainError, ammoGrain),
        onChanged: (v) => _update(() {
          if (v == null) return;
          if (v == _grainOtherKey) {
            if (!_grainOther) ammoGrain.text = '';
            _grainOther = true;
            return;
          }
          _grainOther = false;
          ammoGrain.text = _trimNum(v);
        }),
      ),
    );
    if (!_grainOther) return [MenzilFullWidth(child: select)];
    // Each on its own row: the gram text next to the unit and ⓘ does not
    // fit a half-width box on a phone.
    return [
      MenzilFullWidth(child: select),
      MenzilFullWidth(
        child: MenzilInput(
          key: const Key('ammo-grain'),
          controller: ammoGrain,
          label: 'Kutudaki ağırlık',
          // The gram equivalent in the unit area, so a gram value typed as
          // grain stands out (owner: "Ağırlığın doğru yazılması çok önemli").
          unit: g == null || g <= 0 ? 'gr' : 'gr = ${_gramText(g)} g',
          info: ProfileFieldInfo.grainTyped,
          onChanged: (_) => _update(() {}),
          errorText: _shown(_grainError, ammoGrain),
        ),
      ),
    ];
  }

  /// BC modeli of a typed firearm round: G1 or G7 (owner, 2026-10-14); a
  /// saved other model or curve stays selectable so the record is kept.
  List<DropdownMenuItem<String>> get _typedBcModelItems => [
    const DropdownMenuItem(value: 'g1', child: Text('G1')),
    const DropdownMenuItem(value: 'g7', child: Text('G7')),
    if (!_customCurve &&
        ammoBcModel != null &&
        ammoBcModel != BallisticModel.g1 &&
        ammoBcModel != BallisticModel.g7)
      DropdownMenuItem(
        value: ammoBcModel!.name,
        child: Text('${ammoBcModel!.name.toUpperCase()} (kayıtlı)'),
      ),
    if (_customCurve)
      const DropdownMenuItem(
        value: _customKey,
        child: Text('Özel eğri (kayıtlı)'),
      ),
  ];

  /// PCP: En düşük | En yüksek namlu çıkış hızı (owner, 2026-10-16), fps,
  /// optional, both or neither. With both the calculation uses their mean;
  /// otherwise the Tüfek card's Namlu çıkış hızı. An older PCP profile
  /// opens them empty and calculates as before.
  List<Widget> _pcpVelocityFields() => [
    MenzilInput(
      key: const Key('profile-pcp-velocity-min'),
      controller: pcpMinVelocity,
      label: 'En düşük namlu çıkış hızı',
      unit: 'fps',
      info: ProfileFieldInfo.pcpMinVelocity,
      onChanged: (_) => _update(() {}),
      errorText: _shownPcpVelocity(_pcpMinVelocityError),
    ),
    MenzilInput(
      key: const Key('profile-pcp-velocity-max'),
      controller: pcpMaxVelocity,
      label: 'En yüksek namlu çıkış hızı',
      unit: 'fps',
      info: ProfileFieldInfo.pcpMaxVelocity,
      onChanged: (_) => _update(() {}),
      errorText: _shownPcpVelocity(_pcpMaxVelocityError),
    ),
  ];

  /// Tip of a PCP round: Pellet or Slug.
  Widget get _pcpTypeSelect => KeyedSubtree(
    key: const Key('ammo-type'),
    child: MenzilSelect<AmmunitionType>(
      key: ValueKey('ammo-type-$ammoType'),
      info: ProfileFieldInfo.ammoType,
      label: 'Tip',
      initialValue: ammoType == AmmunitionType.bullet ? null : ammoType,
      items: const [
        DropdownMenuItem(value: AmmunitionType.pellet, child: Text('Pellet')),
        DropdownMenuItem(value: AmmunitionType.slug, child: Text('Slug')),
      ],
      onChanged: (v) => _update(() {
        if (v == ammoType) return;
        // A listed model of the other type goes; the brand stays.
        if (!_ammoManual && ammoModel.text.isNotEmpty) {
          final brand = ammoBrand.text;
          _clearAmmo();
          ammoBrand.text = brand;
        }
        ammoType = v;
      }),
    ),
  );

  /// Mühimmat türü of a firearm round: Fabrika fişeği or El dolumu.
  Widget get _ammoSourceSelect => KeyedSubtree(
    key: const Key('ammo-source'),
    child: MenzilSelect<bool>(
      key: ValueKey('ammo-source-$_factoryAmmo'),
      info: ProfileFieldInfo.ammoSource,
      label: 'Mühimmat türü',
      initialValue: _ammoSourceSet ? _factoryAmmo : null,
      items: const [
        DropdownMenuItem(value: true, child: Text('Fabrika fişeği')),
        DropdownMenuItem(value: false, child: Text('El dolumu')),
      ],
      onChanged: (v) => _update(() {
        if (v == null) return;
        final was = _ammoSourceSet;
        _ammoSourceSet = true;
        if (was && v == _factoryAmmo) return;
        _factoryAmmo = v;
        _clearAmmo();
      }),
    ),
  );

  /// BC modeli list.
  Widget get _bcModelSelect => KeyedSubtree(
    key: const Key('ammo-bc-model'),
    child: MenzilSelect<String>(
      key: ValueKey(
        'ammo-bc-model-${_customCurve ? _customKey : ammoBcModel?.name}',
      ),
      info: platform == WeaponPlatform.firearm
          ? ProfileFieldInfo.bcModelWithCustom
          : ProfileFieldInfo.bcModel,
      label: 'BC modeli',
      hint: 'Seçiniz',
      // PCP starts on G1 (owner, 2026-10-14: "G1 seçili kalsın"); a firearm
      // starts on "Seçiniz" as before.
      initialValue: _customCurve
          ? _customKey
          : platform == WeaponPlatform.pcp
          ? _bcModelForSave!.name
          : ammoBcModel?.name,
      items: _typedFirearmAmmo
          ? _typedBcModelItems
          : [
              for (final (m, text) in _bcModelChoices)
                DropdownMenuItem(value: m.name, child: Text(text)),
              if (platform == WeaponPlatform.firearm)
                const DropdownMenuItem(
                  value: _customKey,
                  child: Text('Özel eğri (Mach–Cd)'),
                )
              else if (_customCurve)
                const DropdownMenuItem(
                  value: _customKey,
                  child: Text('Özel eğri (kayıtlı)'),
                ),
            ],
      onChanged: (v) => _update(() {
        _customCurve = v == _customKey;
        if (!_customCurve) {
          final was = ammoBcModel;
          ammoBcModel = BallisticModel.values
              .where((m) => m.name == v)
              .firstOrNull;
          if (ammoBcModel != was) _factoryBcForModel();
        }
      }),
    ),
  );

  /// "Mühimmat" heading and card.
  List<Widget> _ammoSection(MenzilColors c) {
    final pcp = platform == WeaponPlatform.pcp;
    return [
      const MenzilSectionHeader(
        'Mühimmat',
        padding: EdgeInsets.only(top: MenzilSpace.xxs, bottom: MenzilSpace.sm),
      ),
      MenzilCard(
        key: const Key('profile-ammo-form'),
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.xxs,
        ),
        // PCP (owner, 2026-10-16, the approved design): the Hava Durumu
        // boxes, with the unit inside each box at its right and the ⓘ at the
        // right end of the label row (owner, 2026-10-17); the
        // firearm card is unchanged.
        child: MenzilCompactFields(
          enabled: pcp,
          child: MenzilFieldGrid(children: _ammoFields(c)),
        ),
      ),
    ];
  }

  /// The Mühimmat card's boxes, top to bottom.
  ///
  /// Firearm (owner, 2026-10-11): Mühimmat türü | Marka, Model on its own
  /// row, then Ağırlık | BC, BC modeli | Mermi uzunluğu. Namlu çıkış hızı is on the Tüfek
  /// card since 2026-10-13.
  ///
  /// PCP (owner, 2026-10-16): Tip | Marka; Model; "Aradığın mühimmat
  /// listede yok mu?"; Ağırlık | BC; BC modeli | Mermi uzunluğu; En
  /// düşük | En yüksek namlu çıkış hızı. Tüp basıncı | Regülatör basıncı
  /// are on the Tüfek card (owner, 2026-10-16 20:49–21:04).
  List<Widget> _ammoFields(MenzilColors c) {
    final pcp = platform == WeaponPlatform.pcp;
    final bcModel = _bcModelSelect;
    return [
      ..._ammoNameFields(
        type: pcp ? _pcpTypeSelect : _ammoSourceSelect,
        brandText: MenzilInput(
          key: const Key('ammo-brand'),
          controller: ammoBrand,
          label: 'Marka',
          // The list has no factory round for this Kalibre: say so instead
          // of a silently typed box (owner, 2026-10-11).
          info: _typedFirearmAmmo
              ? ProfileFieldInfo.ammoBrandOther
              : _noFactoryForCaliber
              ? 'Bu kalibre için listede henüz fabrika fişeği yok. '
                    'Fişeğin markasını ve modelini kutunun üstünden okuyup '
                    'yazın; ağırlık, BC ve hız kutuda veya üreticinin '
                    'sitesinde yazar. Kendi doldurduğunuz fişekse Mühimmat '
                    'türünde El dolumu seçin.'
              : _noPcpForCaliber
              // Owner, 2026-10-12: the empty list must say why.
              ? 'Bu kalibre ve tipte listede henüz ürün yok. Markayı ve '
                    'modeli kutunun üstünden okuyup yazın. BC bilinmiyorsa '
                    'boş bırakabilirsiniz.'
              : pcp
              ? ProfileFieldInfo.pcpAmmoBrandTyped
              : null,
          keyboardType: TextInputType.text,
          maxLength: 60,
          onChanged: (_) => _update(() {}),
          errorText: _shown(_ammoBrandError, ammoBrand),
        ),
        modelText: MenzilInput(
          key: const Key('ammo-model'),
          controller: ammoModel,
          label: 'Model',
          info: _typedFirearmAmmo
              ? ProfileFieldInfo.ammoModelTyped
              : pcp
              ? ProfileFieldInfo.pcpAmmoModelTyped
              : null,
          keyboardType: TextInputType.text,
          maxLength: 80,
          onChanged: (_) => _update(() {}),
          errorText: _shown(_ammoModelError, ammoModel),
        ),
      ),
      if (_typedFirearmAmmo)
        ..._typedGrainFields()
      else
        MenzilInput(
          key: const Key('ammo-grain'),
          info: pcp ? ProfileFieldInfo.grain : ProfileFieldInfo.grainFirearm,
          controller: ammoGrain,
          focusNode: _grainFocus,
          label: 'Ağırlık',
          unit: 'gr',
          onChanged: (_) => _update(() {}),
          errorText: _shown(_grainError, ammoGrain),
        ),
      if (!_customCurve)
        MenzilInput(
          key: const Key('ammo-bc'),
          info:
              (pcp ? ProfileFieldInfo.bc : ProfileFieldInfo.bcFirearm) +
              _factoryBcNote,
          controller: ammoBc,
          label: 'BC',
          // A typed BC picks G1 when no model is chosen yet (owner,
          // 2026-10-13); G7 or others stay selectable.
          onChanged: (v) => _update(() {
            // Typed firearm round: BC modeli is chosen on purpose (owner,
            // 2026-10-14: starts "Seçiniz").
            if (platform == WeaponPlatform.firearm &&
                !_typedFirearmAmmo &&
                !_customCurve &&
                ammoBcModel == null &&
                v.trim().isNotEmpty) {
              ammoBcModel = BallisticModel.g1;
            }
          }),
          errorText: _shown(_bcError, ammoBc),
        ),
      // Firearm: the warning under BC as before; PCP: under BC modeli.
      if (_bcPlausibilityWarning != null && !pcp) _bcWarningNotice,
      // BC modeli | Mermi uzunluğu on one row, firearm and PCP (owner,
      // 2026-10-17 11:34: the length is a property of the bullet; moved
      // here from Pro). Their own full-width grid keeps the pair on one
      // row whatever comes before them.
      MenzilFullWidth(
        key: const Key('ammo-bc-model-length-row'),
        child: MenzilFieldGrid(
          children: [
            bcModel,
            MenzilInput(
              key: const Key('ammo-length'),
              controller: ammoLength,
              label: 'Mermi uzunluğu',
              unit: 'mm',
              info: ProfileFieldInfo.ammoLength,
              onChanged: (_) => _update(() {}),
              errorText: _shown(_lengthError, ammoLength),
            ),
          ],
        ),
      ),
      if (_bcPlausibilityWarning != null && pcp) _bcWarningNotice,
      if (pcp) ..._pcpVelocityFields(),
      if (_customCurve)
        MenzilFullWidth(
          child: DragCurveField(
            key: const Key('ammo-curve'),
            curve: _dragCurve,
            errorText: _showErrors && _dragCurve == null
                ? 'Eğriyi yükleyin.'
                : null,
            onChanged: (v) => _update(() => _dragCurve = v),
          ),
        ),
      if (_showErrors &&
          ((!_customCurve && _bcModelForSave == null) ||
              _effectiveAmmoType == null))
        const MenzilFullWidth(
          child: MenzilNotice(
            tone: MenzilNoticeTone.danger,
            message: 'Mühimmat tipini ve BC modelini (G1/G7) seçin.',
          ),
        ),
      // Read-only check line above Kaydet (owner, 2026-10-14).
      if (_typedAmmoSummary != null)
        MenzilFullWidth(
          child: MenzilCard(
            key: const Key('ammo-typed-summary'),
            padding: const EdgeInsets.all(MenzilSpace.md),
            child: Text(
              _typedAmmoSummary!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MenzilType.body(c.ink),
            ),
          ),
        ),
    ];
  }
}
