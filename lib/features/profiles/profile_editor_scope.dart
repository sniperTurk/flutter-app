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
  static List<double> get _maxMagOptions => _ProfileDialogState._maxMagOptions;
  static List<double> get _minMagOptions => _ProfileDialogState._minMagOptions;
  static const _num = _ProfileDialogState._num;
  static List<double> get _objectiveOptions =>
      _ProfileDialogState._objectiveOptions;
  static const _parse = _ProfileDialogState._parse;
  static const _reticlesOf = _ProfileDialogState._reticlesOf;
  static List<ScopeOptic> get _scopeLib => _ProfileDialogState._scopeLib;
  static const _scopeModelOf = _ProfileDialogState._scopeModelOf;
  static const _showScopeListedeYok = _ProfileDialogState._showScopeListedeYok;
  static const _typedReticleNames = _ProfileDialogState._typedReticleNames;
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
    scopeBrand.text = '';
    scopeModel.text = '';
    _scopeLegacyNoModel = false;
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
      {for (final s in _scopeLib) s.brand}.toList()..sort(_byName);

  List<String> _scopeModels(String brand) => {
    for (final s in _scopeLib)
      if (s.brand == brand && _scopeFilterAccepts(s)) _scopeModelOf(s),
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
  Iterable<ScopeOptic> _scopesBefore(int level) => _scopeLib.where(
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

  /// Birim | Odak düzlemi, Tüp | Büyütme: always in their place (approved
  /// design, owner 2026-10-16); on "Seçiniz" and closed until a Marka is
  /// chosen.
  List<Widget> _scopeFilterFields() {
    final open = _scopeBrandSel != null;
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
            DropdownMenuItem(value: u, child: Text(_unitName(u))),
        ],
        onChanged: open ? (v) => changed(() => _scopeUnitFilter = v) : null,
      ),
      MenzilSelect<bool>(
        key: ValueKey(k('ffp', _scopeFfpFilter)),
        label: 'Odak düzlemi',
        hint: 'Seçiniz',
        info: ProfileFieldInfo.scopeFilterFocal,
        initialValue: _scopeFfpFilter,
        items: [
          const DropdownMenuItem<bool>(child: Text('Seçiniz')),
          for (final f in _scopeFfpChoices)
            DropdownMenuItem(value: f, child: Text(f ? 'FFP' : 'SFP')),
        ],
        onChanged: open ? (v) => changed(() => _scopeFfpFilter = v) : null,
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
            DropdownMenuItem(value: d, child: Text('${_num(d)} mm')),
        ],
        onChanged: open ? (v) => changed(() => _scopeTubeFilter = v) : null,
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
        onChanged: open ? (v) => changed(() => _scopeMagFilter = v) : null,
      ),
    ];
  }

  List<ScopeOptic> get _scopeGroup => [
    for (final s in _scopeLib)
      if (s.brand == _scopeBrandSel && _scopeModelOf(s) == _scopeModelKey) s,
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

  /// A number picked from [options] into [controller] ("Seçiniz" while
  /// empty; the list starts with a "Seçiniz" row). [suffix] follows the
  /// number in the list ("x", " mm"). A value that is not an option shows
  /// "Seçiniz" (owner, 2026-10-16: old values open empty).
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
    return KeyedSubtree(
      key: Key(key),
      child: MenzilSelect<double>(
        key: ValueKey('$key-$_scopePickToken'),
        info: info,
        label: label,
        hint: 'Seçiniz',
        initialValue: options.contains(current) ? current : null,
        errorText: errorText,
        items: [
          const DropdownMenuItem<double>(child: Text('Seçiniz')),
          for (final v in options)
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
        hint: 'Seçiniz',
        initialValue: options.any((o) => o.$1 == current) ? current : null,
        errorText: _showErrors ? _clickError : null,
        items: [
          const DropdownMenuItem<double>(child: Text('Seçiniz')),
          for (final (v, name) in options)
            DropdownMenuItem(value: v, child: Text(name)),
        ],
        onChanged: (v) => _update(() {
          // Üst kule klik sayısı was counted in the old click: with another
          // click (or none) it would mean another travel, so it is asked
          // again (DEN17B-1; owner, 2026-10-17). The same click keeps it
          // (compared as numbers: a saved profile opens with "0.1").
          if (v != _parse(scopeClick)) scopeTravelElevation.clear();
          scopeClick.text = v == null ? '' : _trimNum(v);
        }),
      ),
    );
  }

  /// Fills the scope form from a catalog record.
  void _applyScope(ScopeOptic s, {String? reticle}) {
    _angularUnitSet = true; // the catalog scope tells its unit
    final series = ScopePickerScreen.seriesOf(_scopeModelOf(s));
    _scopeRecord = s;
    _scopeOwn = s;
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
        : (_fromMrad(travel, angularUnit) / s.clickValue).round().toString();
    scopeReticle = reticle;
    _scopePickToken++;
  }

  /// True while the scope is typed in ("Aradığın dürbün listede yok mu?",
  /// or no list to pick from).
  bool get _scopeTyped => !_scopeFromList;

  /// Typed scope: Dürbün markası | Dürbün modeli side by side (owner,
  /// 2026-10-16); list scope: Marka, the four filters, then Model.
  List<Widget> _scopeNameFields() {
    final brands = _scopeBrands;
    if (_scopeTyped) {
      return [
        MenzilInput(
          key: const Key('scope-brand'),
          controller: scopeBrand,
          label: 'Dürbün markası',
          keyboardType: TextInputType.text,
          maxLength: 100,
          onChanged: (_) => _update(() {}),
          errorText: _shown(_scopeBrandError, scopeBrand),
        ),
        MenzilInput(
          key: const Key('scope-model'),
          controller: scopeModel,
          label: 'Dürbün modeli',
          keyboardType: TextInputType.text,
          maxLength: _ProfileDialogState._scopeModelMaxLength,
          onChanged: (_) => _update(() {}),
          errorText: _shown(_scopeModelError, scopeModel),
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
              const DropdownMenuItem<String>(child: Text('Seçiniz')),
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
      ..._scopeFilterFields(),
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
            // wraps in the list (two lines); the closed box shows one line
            // cut with "…" (owner, 2026-10-17 18:05).
            items: [
              const DropdownMenuItem<String>(child: Text('Seçiniz')),
              for (final m in models)
                DropdownMenuItem(
                  value: m,
                  child: Text(_scopeModelLine(brand!, m), maxLines: 2),
                ),
            ],
            onChanged: (v) => _update(() {
              _scopeModelKey = v;
              if (v == null) {
                // Back on "Seçiniz": no model, no reticle.
                _scopeRecord = null;
                scopeReticle = null;
                _scopePickToken++;
                return;
              }
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
  String get _scopeDesignation => _scopeDesignationOf(
    _parse(scopeMinMag),
    _parse(scopeMaxMag),
    _parse(scopeObjective),
    firstFocalPlane,
  );

  /// The "Dürbün: …" line: Marka, the typed Dürbün modeli and the
  /// designation ("Dürbün: Benim Optik X5 5-25x56 FFP").
  String get _scopeLine {
    final text = [
      scopeBrand.text.trim(),
      if (_scopeTyped) scopeModel.text.trim(),
      _scopeDesignation,
    ].where((x) => x.isNotEmpty).join(' ');
    return text.isEmpty ? 'Dürbün: —' : 'Dürbün: $text';
  }

  /// "Listeden seç": back from the typed entry to the lists.
  Widget _scopeBackToList() => MenzilFullWidth(
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
          scopeModel.text = '';
          _scopeLegacyNoModel = false;
          scopeClick.text = _trimNum(_defaultClick(angularUnit));
          scopeReticle = null;
          _scopePickToken++;
        }),
        icon: const Icon(Icons.list_alt, size: 18),
        label: const Text('Listeden seç'),
      ),
    ),
  );

  /// Odak düzlemi of a typed scope (or of a list record that lacks it).
  Widget _scopeFocalSelect() => KeyedSubtree(
    key: const Key('scope-focal-plane'),
    child: MenzilSelect<bool>(
      key: ValueKey('scope-focal-plane-$_scopePickToken'),
      info: ProfileFieldInfo.focalPlane,
      label: 'Odak düzlemi',
      hint: 'Seçiniz',
      initialValue: firstFocalPlane,
      items: const [
        DropdownMenuItem<bool>(child: Text('Seçiniz')),
        DropdownMenuItem(value: true, child: Text('FFP')),
        DropdownMenuItem(value: false, child: Text('SFP')),
      ],
      onChanged: (v) => _update(() => firstFocalPlane = v),
    ),
  );

  /// Dürbün birimi of a typed scope (or of a list record that lacks it).
  Widget _scopeUnitSelect() => KeyedSubtree(
    key: const Key('scope-unit'),
    child: MenzilSelect<AngularUnit>(
      key: ValueKey(
        'profile-angular-unit-${angularUnit.name}'
        '${_scopePickToken == 0 ? '' : '-$_scopePickToken'}',
      ),
      info: ProfileFieldInfo.scopeUnit,
      label: 'Dürbün birimi',
      hint: 'Seçiniz',
      initialValue: _angularUnitSet ? angularUnit : null,
      items: const [
        DropdownMenuItem<AngularUnit>(child: Text('Seçiniz')),
        DropdownMenuItem(value: AngularUnit.mrad, child: Text('MRAD')),
        DropdownMenuItem(value: AngularUnit.moa, child: Text('MOA')),
        // "1/4 IN @ 100 YDS" turrets (owner, 2026-10-09).
        DropdownMenuItem(value: AngularUnit.smoa, child: Text('SMOA')),
      ],
      onChanged: (v) => _update(() {
        _angularUnitSet = v != null;
        final next = v ?? AngularUnit.mrad;
        final clickBefore = _parse(scopeClick);
        // A catalog scope's click follows the unit (0.1 MRAD,
        // 1/4 MOA; owner, 2026-10-09).
        if (_scopeManual) {
          // A typed scope picks its Klik değeri from the new unit's
          // list; one that does not fit (or no unit) is cleared.
          final click = _parse(scopeClick);
          if (v == null || !_clickOptions(next).any((o) => o.$1 == click)) {
            scopeClick.clear();
          }
        } else if (next != angularUnit) {
          scopeClick.text = _trimNum(_defaultClick(next));
        }
        // A typed scope's Üst kule klik sayısı was counted in the click the
        // unit change emptied or replaced: it is asked again (DEN17B-1).
        // A catalog scope keeps its own travel.
        if (_scopeTyped && _parse(scopeClick) != clickBefore) {
          scopeTravelElevation.clear();
        }
        angularUnit = next;
      }),
    ),
  );

  /// Dürbün ayağı: MOA only, 0–60 in 5 MOA steps and 90 (owner,
  /// 2026-10-16), each with its ready click gain.
  Widget _scopeMountSelect() => KeyedSubtree(
    key: const Key('scope-mount'),
    child: MenzilSelect<double>(
      // Rebuilt when the click value/unit changes so every
      // choice shows its ready click gain.
      key: ValueKey('scope-mount-cant-${angularUnit.name}-${scopeClick.text}'),
      info: ProfileFieldInfo.mountCant,
      label: 'Dürbün ayağı',
      hint: 'Seçiniz',
      initialValue: _mountCantSet ? mountCant : null,
      // Closed box: just "0 MOA" / "30 MOA"; the list keeps
      // "Normal" and the click gain.
      selectedLabels: [
        'Seçiniz',
        for (final moa in ProductionLimits.mountCantOptionsMoa)
          '${_trimNum(moa)} MOA',
      ],
      items: [
        const DropdownMenuItem<double>(child: Text('Seçiniz')),
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
  );

  /// Retikül: a list scope offers its model's reticles; a typed scope
  /// every reticle name of the catalog that fits its Dürbün birimi and the
  /// plain patterns (owner, 2026-10-16). Every list starts with "Seçiniz".
  Widget _scopeReticleSelect() {
    final choices = _scopeManual
        ? const <(String, ScopeOptic)>[]
        : _scopeReticleChoices;
    if (choices.isNotEmpty) {
      return MenzilSelect<String>(
        key: ValueKey('scope-reticle-$_scopePickToken-$_scopeModelKey'),
        info: ProfileFieldInfo.reticle,
        label: 'Retikül',
        hint: 'Seçiniz',
        initialValue: choices.any((e) => e.$1 == scopeReticle)
            ? scopeReticle
            : null,
        items: [
          const DropdownMenuItem<String>(child: Text('Seçiniz')),
          for (final (r, _) in choices)
            DropdownMenuItem(value: r, child: Text(r)),
        ],
        onChanged: (v) => _update(() {
          final hit = choices.where((e) => e.$1 == v).firstOrNull;
          if (hit != null) {
            _applyScope(hit.$2, reticle: hit.$1);
          } else {
            scopeReticle = null;
          }
        }),
      );
    }
    final List<String> names;
    if (_scopeTyped) {
      names = _typedReticleNames(
        angularUnit,
        unitSet: _angularUnitSet,
        keep: scopeReticle,
      );
    } else {
      // A list scope whose maker names no reticle: only the plain patterns
      // of its unit (owner, 2026-10-11: a MRAD scope listed MOA too); a
      // saved name stays offered.
      final plain = [
        for (final n in _typedReticleNames(angularUnit, unitSet: true))
          if (Reticles.genericNames.contains(n)) n,
      ];
      final saved = scopeReticle;
      names = [if (saved != null && !plain.contains(saved)) saved, ...plain];
    }
    return MenzilSelect<String>(
      key: ValueKey('scope-reticle-$_scopePickToken'),
      info: ProfileFieldInfo.reticle,
      label: 'Retikül',
      hint: 'Seçiniz',
      initialValue: names.contains(scopeReticle) ? scopeReticle : null,
      items: [
        const DropdownMenuItem<String>(child: Text('Seçiniz')),
        for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
      ],
      onChanged: (v) => _update(() => scopeReticle = v),
    );
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
          // Typed scope (owner, 2026-10-16 22:14–22:49), two per row:
          // Dürbün birimi | Odak düzlemi, Minimum | Maksimum büyütme,
          // Mercek çapı | Klik değeri, Üst kule klik sayısı | Dürbün ayağı,
          // Retikül. A list scope shows only the boxes its record lacks,
          // in the same order.
          if (_scopeUnitShown) _scopeUnitSelect(),
          if (_scopeFocalShown) _scopeFocalSelect(),
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
          if (_scopeTyped) _clickSelect(),
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
          _scopeMountSelect(),
          MenzilFullWidth(
            child: KeyedSubtree(
              key: const Key('scope-reticle'),
              child: _scopeReticleSelect(),
            ),
          ),
          MenzilFullWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scopeLine,
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
          // Typed entry: "Listeden seç" last, under the Dürbün line
          // (owner, 2026-10-16).
          if (_scopeManual && _scopeBrands.isNotEmpty) _scopeBackToList(),
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

/// "6-24x56 FFP" from a scope's values (empty parts are skipped).
String _scopeDesignationOf(double? min, double? max, double? obj, bool? ffp) {
  String part(double? v) => v == null ? '' : _trimNum(v);
  final lo = part(min), hi = part(max), o = part(obj);
  final zoom = lo.isEmpty && hi.isEmpty
      ? ''
      : lo == hi || hi.isEmpty
      ? lo
      : lo.isEmpty
      ? hi
      : '$lo-$hi';
  final body = zoom.isEmpty && o.isEmpty ? '' : '${zoom}x$o';
  final plane = ffp == null ? '' : (ffp ? 'FFP' : 'SFP');
  return [body, plane].where((x) => x.isNotEmpty).join(' ');
}

/// Dürbün modeli of a saved typed scope: the record's model before its
/// designation ("X5 5-25x56 FFP" -> "X5"); empty for a record saved before
/// 2026-10-16, which kept only the designation.
String _typedScopeModelOf(ScopeOptic s) {
  final d = _scopeDesignationOf(
    s.minMagnification,
    s.maxMagnification,
    s.objectiveDiameterMm > 0 ? s.objectiveDiameterMm : null,
    s.firstFocalPlane,
  );
  final m = s.model.trim();
  if (d.isEmpty || !m.endsWith(' $d')) return '';
  return m.substring(0, m.length - d.length - 1).trim();
}
