part of 'profiles_screen.dart';

/// Dürbün section of the profile editor: brand / filter / model / reticle
/// lists, the scope fields and the Dürbün card (moved out of
/// profiles_screen.dart, behaviour unchanged).
extension _ScopeSection on _ProfileDialogState {
  // The editor's static members under their own names, so the moved
  // code reads exactly as it did inside the class (an extension does
  // not see the static members of its type unqualified).
  static const _byName = _ProfileDialogState._byName;
  static const _clickOptions = _ProfileDialogState._clickOptions;
  static const _defaultClick = _ProfileDialogState._defaultClick;
  static const _fromMrad = _ProfileDialogState._fromMrad;
  static const _magRange = _ProfileDialogState._magRange;
  static const _manualKey = _ProfileDialogState._manualKey;
  static const _maxMagOptions = _ProfileDialogState._maxMagOptions;
  static const _minMagOptions = _ProfileDialogState._minMagOptions;
  static const _num = _ProfileDialogState._num;
  static const _objectiveOptions = _ProfileDialogState._objectiveOptions;
  static const _parse = _ProfileDialogState._parse;
  static const _reticlesOf = _ProfileDialogState._reticlesOf;
  static List<ScopeOptic> get _scopeLib => _ProfileDialogState._scopeLib;
  static const _scopeModelOf = _ProfileDialogState._scopeModelOf;
  static const _showScopeListedeYok = _ProfileDialogState._showScopeListedeYok;
  static const _unitName = _ProfileDialogState._unitName;

  /// A catalog scope (picked from the lists): Minimum / Maksimum büyütme,
  /// Mercek çapı, Odak düzlemi and Dürbün birimi come from the record and
  /// are hidden (owner, 2026-10-13: "gizle, silme"). Only a value the
  /// record lacks shows its box so the user can fill it; before a Model is
  /// chosen they all stay hidden.
  bool get _scopeFromList => !_scopeManual && _scopeBrands.isNotEmpty;

  bool get _scopeMinMagShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.minMagnification == null);

  bool get _scopeMaxMagShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.maxMagnification == null);

  bool get _scopeObjectiveShown =>
      !_scopeFromList ||
      (_scopeModelKey != null &&
          ((_scopeRecord?.objectiveDiameterMm ?? 0) <= 0));

  bool get _scopeFocalShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && _scopeRecord?.firstFocalPlane == null);

  bool get _scopeUnitShown =>
      !_scopeFromList ||
      (_scopeModelKey != null && (_scopeRecord == null || !_angularUnitSet));

  /// Opens the typed scope entry ("Aradığın dürbün listede yok mu?", and the
  /// hidden "Listede yok" item): every box starts on "Seçiniz".
  void _openScopeManual() {
    _scopeModelKey = null;
    scopeReticle = null;
    _scopePickToken++;
    _scopeManual = true;
    _scopeBrandSel = null;
    _scopeRecord = null;
    _scopeFiltersHidden = false;
    scopeBrand.text = '';
    for (final c in [
      scopeMinMag,
      scopeMaxMag,
      scopeObjective,
      scopeClick,
      scopeTravelElevation,
    ]) {
      c.clear();
    }
    firstFocalPlane = null;
    _angularUnitSet = false;
  }

  List<String> get _scopeBrands =>
      {for (final s in _scopeLib) s.brand}.toList()
        ..sort(_byName);

  List<String> _scopeModels(String brand) => {
    for (final s in _scopeLib)
      if (s.brand == brand && _scopeFilterAccepts(s))
        _scopeModelOf(s),
  }.toList()..sort(_byName);

  /// [level]: how many filters apply (1 Birim, 2 Odak, 3 Tüp, 4 Büyütme).
  bool _scopeFilterAccepts(ScopeOptic s, [int level = 4]) {
    if (level >= 1 &&
        _scopeUnitFilter != null &&
        s.clickUnit != _scopeUnitFilter) {
      return false;
    }
    if (level >= 2 &&
        _scopeFfpFilter != null &&
        s.firstFocalPlane != _scopeFfpFilter) {
      return false;
    }
    if (level >= 3 &&
        _scopeTubeFilter != null &&
        s.tubeDiameterMm != _scopeTubeFilter) {
      return false;
    }
    if (level >= 4 &&
        _scopeMagFilter != null &&
        _magRange(s) != _scopeMagFilter) {
      return false;
    }
    return true;
  }

  /// Scopes of the chosen brand that pass the filters before [level].
  Iterable<ScopeOptic> _scopesBefore(int level) =>
      _scopeLib.where(
        (s) => s.brand == _scopeBrandSel && _scopeFilterAccepts(s, level - 1),
      );

  List<AngularUnit> get _scopeUnitChoices {
    final have = {for (final s in _scopesBefore(1)) s.clickUnit};
    return [
      for (final u in AngularUnit.values)
        if (have.contains(u)) u,
    ];
  }

  List<bool> get _scopeFfpChoices {
    final have = {
      for (final s in _scopesBefore(2))
        if (s.firstFocalPlane != null) s.firstFocalPlane!,
    };
    return [
      for (final f in const [true, false])
        if (have.contains(f)) f,
    ];
  }

  List<String> get _scopeMagChoices {
    final byLow = <String, (double, double)>{};
    for (final s in _scopesBefore(4)) {
      final r = _magRange(s);
      if (r != null) {
        byLow[r] = (s.minMagnification ?? 0, s.maxMagnification ?? 0);
      }
    }
    return byLow.keys.toList()..sort((a, b) {
      final (la, ha) = byLow[a]!;
      final (lb, hb) = byLow[b]!;
      return la != lb ? la.compareTo(lb) : ha.compareTo(hb);
    });
  }

  List<double> get _scopeTubeChoices => {
    for (final s in _scopesBefore(3))
      if (s.tubeDiameterMm != null) s.tubeDiameterMm!,
  }.toList()..sort();

  /// After a change, a filter whose choice is no longer offered goes back
  /// to "Seçiniz" (checked in order, each against the ones before it).
  void _dropUnavailableScopeFilters() {
    if (_scopeUnitFilter != null &&
        !_scopeUnitChoices.contains(_scopeUnitFilter)) {
      _scopeUnitFilter = null;
    }
    if (_scopeFfpFilter != null &&
        !_scopeFfpChoices.contains(_scopeFfpFilter)) {
      _scopeFfpFilter = null;
    }
    if (_scopeTubeFilter != null &&
        !_scopeTubeChoices.contains(_scopeTubeFilter)) {
      _scopeTubeFilter = null;
    }
    if (_scopeMagFilter != null &&
        !_scopeMagChoices.contains(_scopeMagFilter)) {
      _scopeMagFilter = null;
    }
  }

  /// One line per model with its data (owner, 2026-10-13), e.g.
  /// "Continental x6 5-30x56i Fiber SFP · MOA".
  String _scopeModelLine(String brand, String model) {
    final s = _scopeLib
        .where(
          (x) =>
              x.brand == brand &&
              _scopeModelOf(x) == model &&
              _scopeFilterAccepts(x),
        )
        .firstOrNull;
    if (s == null) return model;
    // What the product name already says is not repeated (owner,
    // 2026-10-13: "CONTINENTAL X6 4-24X56 MBR FFP 34MM").
    final name = model.toLowerCase().replaceAll(' ', '');
    bool said(String t) => name.contains(t.toLowerCase().replaceAll(' ', ''));
    final unit = _unitName(s.clickUnit);
    final focal = s.firstFocalPlane == null
        ? null
        : s.firstFocalPlane!
        ? 'FFP'
        : 'SFP';
    // No brand and no tube on the line: too many parts made it tiny
    // (owner, 2026-10-13); the brand is chosen above anyway.
    return [
      model,
      if (!said(unit)) unit,
      if (focal != null && !said(focal)) focal,
    ].join(' · ');
  }

  List<Widget> _scopeFilterFields() {
    void changed(VoidCallback f) => _update(() {
      f();
      _dropUnavailableScopeFilters();
      // A chosen model that the filter drops goes back to "Seçiniz".
      final brand = _scopeBrandSel;
      if (brand != null &&
          _scopeModelKey != null &&
          !_scopeModels(brand).contains(_scopeModelKey)) {
        _scopeModelKey = null;
        scopeReticle = null;
      }
      _scopePickToken++;
    });
    String k(String name, Object? v) => 'scope-filter-$name-$_scopeBrandSel-$v';
    return [
      MenzilSelect<AngularUnit>(
        key: ValueKey(k('unit', _scopeUnitFilter)),
        label: 'Birim',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterUnit,
        initialValue: _scopeUnitFilter,
        items: [
          const DropdownMenuItem<AngularUnit>(child: Text('Seçiniz')),
          for (final u in _scopeUnitChoices)
            DropdownMenuItem(
              value: u,
              child: Text(_unitName(u)),
            ),
        ],
        onChanged: (v) => changed(() => _scopeUnitFilter = v),
      ),
      MenzilSelect<bool>(
        key: ValueKey(k('ffp', _scopeFfpFilter)),
        label: 'Odak',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterFocal,
        initialValue: _scopeFfpFilter,
        items: [
          const DropdownMenuItem<bool>(child: Text('Seçiniz')),
          for (final f in _scopeFfpChoices)
            DropdownMenuItem(value: f, child: Text(f ? 'FFP' : 'SFP')),
        ],
        onChanged: (v) => changed(() => _scopeFfpFilter = v),
      ),
      MenzilSelect<double>(
        key: ValueKey(k('tube', _scopeTubeFilter)),
        label: 'Tüp',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterTube,
        initialValue: _scopeTubeFilter,
        items: [
          const DropdownMenuItem<double>(child: Text('Seçiniz')),
          for (final d in _scopeTubeChoices)
            DropdownMenuItem(
              value: d,
              child: Text('${_num(d)} mm'),
            ),
        ],
        onChanged: (v) => changed(() => _scopeTubeFilter = v),
      ),
      MenzilSelect<String>(
        key: ValueKey(k('mag', _scopeMagFilter)),
        label: 'Büyütme',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterMag,
        initialValue: _scopeMagFilter,
        items: [
          const DropdownMenuItem<String>(child: Text('Seçiniz')),
          for (final r in _scopeMagChoices)
            DropdownMenuItem(value: r, child: Text(r)),
        ],
        onChanged: (v) => changed(() => _scopeMagFilter = v),
      ),
    ];
  }

  List<ScopeOptic> get _scopeGroup => [
    for (final s in _scopeLib)
      if (s.brand == _scopeBrandSel &&
          _scopeModelOf(s) == _scopeModelKey)
        s,
  ];

  /// Retikül choices of the chosen model and the record each one belongs to.
  List<(String, ScopeOptic)> get _scopeReticleChoices {
    final out = <(String, ScopeOptic)>[];
    for (final s in _scopeGroup) {
      for (final r in _reticlesOf(s)) {
        if (!out.any((e) => e.$1 == r)) out.add((r, s));
      }
    }
    return out;
  }

  /// A plain reticle pattern that matches the scope's turret unit: MIL
  /// patterns for a MRAD scope, the MOA pattern for MOA / SMOA; Duplex fits
  /// both. A typed scope whose Dürbün birimi still says "Seçiniz" lists all
  /// five (owner, 2026-10-14): the hidden unit (MRAD in a new profile, the
  /// saved unit on edit) gave Profil Oluştur 4 and Profili Düzenle 2.
  bool _genericFitsUnit(String n) {
    if (!_scopeFromList && !_angularUnitSet) return true;
    if (n == Reticles.duplex) return true;
    final moa = angularUnit.moaFamily;
    return n == Reticles.hashMoa ? moa : !moa;
  }

  /// A number picked from [options] into [controller] ("Seçiniz" while
  /// empty). [suffix] follows the number in the list ("x", " mm").
  Widget _numberSelect({
    required String key,
    required String label,
    required String info,
    required TextEditingController controller,
    required List<double> options,
    String suffix = '',
    String? errorText,
  }) {
    final current = _parse(controller);
    final values = [
      ...options,
      if (current != null && !options.contains(current)) current,
    ]..sort();
    return KeyedSubtree(
      key: Key(key),
      child: MenzilSelect<double>(
        key: ValueKey('$key-$_scopePickToken'),
        info: info,
        label: label,
        initialValue: current,
        errorText: errorText,
        items: [
          for (final v in values)
            DropdownMenuItem(value: v, child: Text('${_trimNum(v)}$suffix')),
        ],
        onChanged: (v) => _update(() {
          controller.text = v == null ? '' : _trimNum(v);
        }),
      ),
    );
  }

  /// Klik değeri, asked only for a typed scope ("Aradığın dürbün listede yok
  /// mu?"); a catalog
  /// scope brings its own. Empty until Dürbün birimi is chosen.
  Widget _clickSelect() {
    final options = _angularUnitSet
        ? _clickOptions(angularUnit)
        : const <(double, String)>[];
    final current = _parse(scopeClick);
    return KeyedSubtree(
      key: const Key('scope-click'),
      child: MenzilSelect<double>(
        key: ValueKey('scope-click-${angularUnit.name}-$_scopePickToken'),
        info: ProfileFieldInfo.clickValue,
        label: 'Klik değeri',
        initialValue: options.any((o) => o.$1 == current) ? current : null,
        errorText: _showErrors ? _clickError : null,
        items: [
          for (final (v, name) in options)
            DropdownMenuItem(value: v, child: Text(name)),
        ],
        onChanged: (v) => _update(() {
          scopeClick.text = v == null ? '' : _trimNum(v);
        }),
      ),
    );
  }

  /// Fills the scope form from a catalog record.
  void _applyScope(ScopeOptic s, {String? reticle}) {
    _angularUnitSet = true; // the catalog scope tells its unit
    final series = ScopePickerScreen.seriesOf(
      _scopeModelOf(s),
    );
    _scopeRecord = s;
    scopeBrand.text = series.isEmpty ? s.brand : '${s.brand} $series';
    // A value the record lacks is emptied (not kept from an earlier model)
    // and its box is shown for the user to fill.
    scopeMinMag.text = s.minMagnification == null
        ? ''
        : _trimNum(s.minMagnification!);
    scopeMaxMag.text = s.maxMagnification == null
        ? ''
        : _trimNum(s.maxMagnification!);
    scopeObjective.text = s.objectiveDiameterMm > 0
        ? _trimNum(s.objectiveDiameterMm)
        : '';
    firstFocalPlane = s.firstFocalPlane;
    angularUnit = s.clickUnit;
    scopeClick.text = _trimNum(s.clickValue);
    final travel = s.elevationRangeMrad;
    scopeTravelElevation.text = travel == null || travel <= 0
        ? ''
        : (_fromMrad(travel, angularUnit) / s.clickValue)
              .round()
              .toString();
    scopeReticle = reticle;
    _scopePickToken++;
  }

  /// Marka and Model of the scope, each on its own row.
  List<Widget> _scopeNameFields() {
    final brands = _scopeBrands;
    if (_scopeManual || brands.isEmpty) {
      return [
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('scope-brand'),
            controller: scopeBrand,
            label: 'Dürbün markası',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => _update(() {}),
            errorText: _shown(_scopeBrandError, scopeBrand),
          ),
        ),
        if (brands.isNotEmpty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('scope-back-to-list'),
                onPressed: () => _update(() {
                  _scopeManual = false;
                  _scopeBrandSel = null;
                  _scopeModelKey = null;
                  _scopeRecord = null;
                  scopeBrand.text = '';
                  scopeClick.text = _trimNum(
                    _defaultClick(angularUnit),
                  );
                  scopeReticle = null;
                  _scopePickToken++;
                }),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeden seç'),
              ),
            ),
          ),
      ];
    }
    final brand = brands.contains(_scopeBrandSel) ? _scopeBrandSel : null;
    final models = brand == null ? const <String>[] : _scopeModels(brand);
    final model = models.contains(_scopeModelKey) ? _scopeModelKey : null;
    return [
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('scope-brand-select'),
          child: MenzilSelect<String>(
            key: ValueKey('scope-brand-select-$brand'),
            label: 'Marka',
            hint: 'Seçiniz',
            initialValue: brand,
            items: [
              for (final b in brands)
                DropdownMenuItem(value: b, child: Text(b)),
              if (_showScopeListedeYok)
                const DropdownMenuItem(
                  value: _manualKey,
                  child: Text('Listede yok'),
                ),
            ],
            onChanged: (v) => _update(() {
              if (v == _manualKey) {
                _openScopeManual();
                return;
              }
              _scopeModelKey = null;
              _scopeRecord = null;
              scopeReticle = null;
              _scopePickToken++;
              // A changed Marka shows the filters again (owner, 2026-10-13).
              _scopeFiltersHidden = false;
              _scopeBrandSel = v;
              scopeBrand.text = v ?? '';
              // A new brand starts every filter on "Seçiniz" (owner,
              // 2026-10-13).
              _scopeUnitFilter = null;
              _scopeFfpFilter = null;
              _scopeTubeFilter = null;
              _scopeMagFilter = null;
            }),
          ),
        ),
      ),
      if (brand != null && !_scopeFiltersHidden) ..._scopeFilterFields(),
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('scope-model-select'),
          child: MenzilSelect<String>(
            key: ValueKey(
              'scope-model-select-$brand-$model-$_scopeUnitFilter-'
              '$_scopeFfpFilter-$_scopeTubeFilter-$_scopeMagFilter',
            ),
            label: 'Model',
            hint: 'Seçiniz',
            initialValue: model,
            // Model and its data, no brand (owner, 2026-10-13). A long line
            // keeps its size and wraps, in the list (two lines) and in the
            // box, which grows (owner, 2026-10-14: like Mühimmat Model;
            // never smaller).
            wrapSelected: true,
            items: [
              for (final m in models)
                DropdownMenuItem(
                  value: m,
                  child: Text(_scopeModelLine(brand!, m), maxLines: 2),
                ),
            ],
            onChanged: (v) => _update(() {
              _scopeModelKey = v;
              final choices = _scopeReticleChoices;
              final group = _scopeGroup;
              if (group.isEmpty) return;
              // One reticle: chosen right away; otherwise Retikül waits.
              _applyScope(
                choices.length == 1 ? choices.first.$2 : group.first,
                reticle: choices.length == 1 ? choices.first.$1 : null,
              );
            }),
          ),
        ),
      ),
    ];
  }

  /// One Dürbün ayağı choice with its ready click gain for the scope as
  /// entered now ("60 MOA · +240 klik"); just the angle while the click
  /// value is not valid yet.
  String _mountLabel(double moa) {
    if (moa == 0) return 'Normal (0 MOA)';
    final name = '${_trimNum(moa)} MOA';
    final click = _parse(scopeClick);
    if (click == null || !click.isFinite || click <= 0) return name;
    final clicks = ScopeDialMath.mountCantClicks(moa, click, angularUnit);
    return '$name · +$clicks klik';
  }

  /// One-line designation, e.g. "6-24x56 FFP" (empty parts are skipped).
  String get _scopeDesignation {
    String part(TextEditingController c) {
      final v = _parse(c);
      return v == null ? '' : _trimNum(v);
    }

    final lo = part(scopeMinMag), hi = part(scopeMaxMag);
    final obj = part(scopeObjective);
    final zoom = lo.isEmpty && hi.isEmpty
        ? ''
        : lo == hi || hi.isEmpty
        ? lo
        : lo.isEmpty
        ? hi
        : '$lo-$hi';
    final body = zoom.isEmpty && obj.isEmpty
        ? ''
        : '${zoom}x${obj.isEmpty ? '' : obj}';
    final plane = firstFocalPlane == null
        ? ''
        : (firstFocalPlane! ? 'FFP' : 'SFP');
    return [body, plane].where((x) => x.isNotEmpty).join(' ');
  }

  /// "Dürbün" heading and card.
  List<Widget> _scopeSection(MenzilColors c) => [
    const MenzilSectionHeader(
      'Dürbün',
      padding: EdgeInsets.only(top: MenzilSpace.xxs, bottom: MenzilSpace.sm),
    ),
    MenzilCard(
      key: const Key('profile-scope-form'),
      padding: const EdgeInsets.fromLTRB(
        MenzilSpace.lg,
        MenzilSpace.lg,
        MenzilSpace.lg,
        MenzilSpace.xxs,
      ),
      child: MenzilFieldGrid(
        children: [
          // Owner, 2026-10-11: Marka, then the models of that brand,
          // then only that model's reticles.
          ..._scopeNameFields(),
          // Owner, 2026-10-11: picked from standard values, not
          // typed; Minimum | Maksimum side by side.
          if (_scopeMinMagShown)
            _numberSelect(
              key: 'scope-min-mag',
              label: 'Minimum büyütme',
              info: ProfileFieldInfo.minMag,
              controller: scopeMinMag,
              options: _minMagOptions,
              suffix: 'x',
              errorText: _shownSelect(_minMagError),
            ),
          if (_scopeMaxMagShown)
            _numberSelect(
              key: 'scope-max-mag',
              label: 'Maksimum büyütme',
              info: ProfileFieldInfo.maxMag,
              controller: scopeMaxMag,
              options: _maxMagOptions,
              suffix: 'x',
              errorText: _shownSelect(_maxMagError, scopeMaxMag),
            ),
          if (_scopeObjectiveShown)
            _numberSelect(
              key: 'scope-objective',
              label: 'Mercek çapı',
              info: ProfileFieldInfo.objective,
              controller: scopeObjective,
              options: _objectiveOptions,
              suffix: ' mm',
              errorText: _shownSelect(_objectiveError),
            ),
          if (_scopeFocalShown)
            KeyedSubtree(
              key: const Key('scope-focal-plane'),
              child: MenzilSelect<bool>(
                key: ValueKey('scope-focal-plane-$_scopePickToken'),
                info: ProfileFieldInfo.focalPlane,
                label: 'Odak düzlemi',
                initialValue: firstFocalPlane,
                items: const [
                  DropdownMenuItem(value: true, child: Text('FFP')),
                  DropdownMenuItem(value: false, child: Text('SFP')),
                ],
                onChanged: (v) => _update(() => firstFocalPlane = v),
              ),
            ),
          if (_scopeUnitShown)
            KeyedSubtree(
              key: const Key('scope-unit'),
              child: MenzilSelect<AngularUnit>(
                key: ValueKey(
                  'profile-angular-unit-${angularUnit.name}'
                  '${_scopePickToken == 0 ? '' : '-$_scopePickToken'}',
                ),
                info: ProfileFieldInfo.scopeUnit,
                label: 'Dürbün birimi',
                initialValue: _angularUnitSet ? angularUnit : null,
                items: const [
                  DropdownMenuItem(
                    value: AngularUnit.mrad,
                    child: Text('MRAD'),
                  ),
                  DropdownMenuItem(value: AngularUnit.moa, child: Text('MOA')),
                  // "1/4 IN @ 100 YDS" turrets (owner, 2026-10-09).
                  DropdownMenuItem(
                    value: AngularUnit.smoa,
                    child: Text('SMOA'),
                  ),
                ],
                onChanged: (v) => _update(() {
                  _angularUnitSet = v != null;
                  final next = v ?? AngularUnit.mrad;
                  // A catalog scope's click follows the unit (0.1 MRAD,
                  // 1/4 MOA; owner, 2026-10-09).
                  if (_scopeManual) {
                    // A typed scope picks its Klik değeri from the
                    // new unit's list; one that does not fit is cleared.
                    final click = _parse(scopeClick);
                    if (!_clickOptions(
                      next,
                    ).any((o) => o.$1 == click)) {
                      scopeClick.clear();
                    }
                  } else if (next != angularUnit) {
                    scopeClick.text = _trimNum(
                      _defaultClick(next),
                    );
                  }
                  angularUnit = next;
                }),
              ),
            ),
          // Typed scope: Dürbün birimi | Klik değeri side by side.
          if (_scopeManual || _scopeBrands.isEmpty) _clickSelect(),
          // Üst kule klik sayısı | Dürbün ayağı, Dürbün ayağı on the right
          // (owner, 2026-10-15).
          MenzilInput(
            key: const Key('scope-travel-elevation'),
            info: ProfileFieldInfo.elevationTravel,
            controller: scopeTravelElevation,
            label: 'Üst kule klik sayısı',
            keyboardType: TextInputType.number,
            onChanged: (_) => _update(() {}),
            errorText: _travelError(scopeTravelElevation),
          ),
          KeyedSubtree(
            key: const Key('scope-mount'),
            child: MenzilSelect<double>(
              // Rebuilt when the click value/unit changes so every
              // choice shows its ready click gain.
              key: ValueKey(
                'scope-mount-cant-${angularUnit.name}-${scopeClick.text}',
              ),
              info: ProfileFieldInfo.mountCant,
              label: 'Dürbün ayağı',
              initialValue: _mountCantSet ? mountCant : null,
              // Closed box: just "0 MOA" / "30 MOA"; the list keeps
              // "Normal" and the click gain.
              selectedLabels: [
                for (final moa in ProductionLimits.mountCantOptionsMoa)
                  '${_trimNum(moa)} MOA',
              ],
              items: [
                for (final moa in ProductionLimits.mountCantOptionsMoa)
                  DropdownMenuItem(
                    value: moa,
                    child: Text(
                      _mountLabel(moa),
                      key: Key('scope-mount-cant-${_trimNum(moa)}'),
                    ),
                  ),
              ],
              onChanged: (v) => _update(() {
                _mountCantSet = v != null;
                mountCant = v ?? 0;
              }),
            ),
          ),
          MenzilFullWidth(
            child: KeyedSubtree(
              key: const Key('scope-reticle'),
              child: Builder(
                builder: (context) {
                  final choices = _scopeManual
                      ? const <(String, ScopeOptic)>[]
                      : _scopeReticleChoices;
                  if (choices.isNotEmpty) {
                    return MenzilSelect<String>(
                      key: ValueKey(
                        'scope-reticle-$_scopePickToken-$_scopeModelKey',
                      ),
                      info: ProfileFieldInfo.reticle,
                      label: 'Retikül',
                      hint: 'Seçiniz',
                      initialValue: choices.any((e) => e.$1 == scopeReticle)
                          ? scopeReticle
                          : null,
                      items: [
                        for (final (r, _) in choices)
                          DropdownMenuItem(value: r, child: Text(r)),
                      ],
                      onChanged: (v) => _update(() {
                        final hit = choices.where((e) => e.$1 == v).firstOrNull;
                        if (hit != null) {
                          _applyScope(hit.$2, reticle: hit.$1);
                        }
                      }),
                    );
                  }
                  return MenzilSelect<String>(
                    key: ValueKey('scope-reticle-$_scopePickToken'),
                    info: ProfileFieldInfo.reticle,
                    label: 'Retikül',
                    initialValue: scopeReticle,
                    items: [
                      if (scopeReticle != null &&
                          !Reticles.genericNames.contains(scopeReticle))
                        DropdownMenuItem(
                          value: scopeReticle,
                          child: Text(scopeReticle!),
                        ),
                      // The manufacturer names no reticle: only the
                      // plain patterns of the scope's unit (owner,
                      // 2026-10-11: a MRAD scope listed MOA too).
                      for (final n in Reticles.genericNames)
                        if (_genericFitsUnit(n) || n == scopeReticle)
                          DropdownMenuItem(value: n, child: Text(n)),
                    ],
                    onChanged: (v) => _update(() => scopeReticle = v),
                  );
                },
              ),
            ),
          ),
          MenzilFullWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scopeDesignation.isEmpty
                      ? 'Dürbün: —'
                      : 'Dürbün: ${scopeBrand.text.trim()} $_scopeDesignation'
                            .trim(),
                  key: const Key('scope-designation'),
                  style: MenzilType.body(c.ink),
                ),
                if (_showErrors && firstFocalPlane == null)
                  const MenzilNotice(
                    tone: MenzilNoticeTone.danger,
                    message: 'Odak düzlemini seçin (FFP / SFP).',
                  ),
              ],
            ),
          ),
          // Owner, 2026-10-13: the typed entry opens from this link
          // instead of a "Listede yok" item in the Marka list.
          if (_scopeFromList)
            MenzilFullWidth(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('scope-not-listed'),
                  onPressed: () => _update(_openScopeManual),
                  child: const Text('Aradığın dürbün listede yok mu?'),
                ),
              ),
            ),
        ],
      ),
    ),
  ];
}
