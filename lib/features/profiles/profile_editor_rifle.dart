part of 'profiles_screen.dart';

/// Tüfek section of the profile editor: Marka / Model / Kalibre lists,
/// the rifle fields and the Tüfek card (moved out of profiles_screen.dart,
/// behaviour unchanged).
extension _RifleSection on _ProfileDialogState {
  // The editor's static members under their own names, so the moved
  // code reads exactly as it did inside the class (an extension does
  // not see the static members of its type unqualified).
  static List<double> get _bulletDiameters =>
      _ProfileDialogState._bulletDiameters;
  static const _byName = _ProfileDialogState._byName;
  static const _cartridgeFor = _ProfileDialogState._cartridgeFor;
  static const _diameterLabel = _ProfileDialogState._diameterLabel;
  static const _domesticBrands = _ProfileDialogState._domesticBrands;
  static const _firearmCartridges = _ProfileDialogState._firearmCartridges;
  static const _manualKey = _ProfileDialogState._manualKey;
  static const _noCartridgeKey = _ProfileDialogState._noCartridgeKey;
  static const _otherCaliberKey = _ProfileDialogState._otherCaliberKey;
  static const _parse = _ProfileDialogState._parse;
  static const _pcpCalibers = _ProfileDialogState._pcpCalibers;
  static const _popularCount = _ProfileDialogState._popularCount;
  static const _round1 = _ProfileDialogState._round1;
  static const _shortCartridge = _ProfileDialogState._shortCartridge;
  static const _showRifleListedeYok = _ProfileDialogState._showRifleListedeYok;
  static const _trimDot = _ProfileDialogState._trimDot;
  static const _variantLabel = _ProfileDialogState._variantLabel;

  double? _caliberItem(double mm) {
    final list = platform == WeaponPlatform.firearm
        ? [for (final (_, d) in _firearmCartridges) (d, '')]
        : _pcpCalibers;
    for (final (v, _) in list) {
      if ((v - mm).abs() < 0.005) return v;
    }
    return null;
  }

  /// Select key of the current caliber: the cartridge name (firearm) or
  /// "mm:<value>"; a saved value not on the list stays selectable.
  String? get _caliberKey {
    final variants = _caliberFromModel
        ? _rifleVariants
        : const <LibraryRifle>[];
    if (variants.isNotEmpty) {
      final i = _rifleVariant == null ? -1 : variants.indexOf(_rifleVariant!);
      return i < 0 ? null : 'v:$i';
    }
    if (platform == WeaponPlatform.firearm && _caliberByDiameter) {
      return _noCartridgeKey;
    }
    final cal = _parse(rifleCaliber);
    if (cal == null) return null;
    if (platform == WeaponPlatform.firearm) {
      final c = _cartridge;
      if (c != null && _firearmCartridges.any((e) => e.$1 == c)) {
        return c;
      }
      return _cartridgeFor(cal) ?? 'mm:${_trimDot(cal)}';
    }
    return 'mm:${_trimDot(_caliberItem(cal) ?? cal)}';
  }

  /// Kalibre shows the chosen model's calibers (owner, 2026-10-11) until
  /// "Diğer kalibre" opens the whole list.
  bool get _caliberFromModel =>
      !_rifleManual && !_caliberAll && _rifleVariants.isNotEmpty;

  /// Kalibre entries with the text of the closed box: [full] when it fits
  /// the half-width box, [short] when it would have to shrink too much
  /// (owner, 2026-10-13: Namlu çıkış hızı | Kalibre on one row).
  List<({DropdownMenuItem<String> item, String full, String short})>
  get _caliberChoices {
    final cal = _parse(rifleCaliber);
    final out =
        <({DropdownMenuItem<String> item, String full, String short})>[];
    void add(
      String value,
      Widget child,
      String full, {
      String? short,
      bool enabled = true,
    }) => out.add((
      item: DropdownMenuItem(value: value, enabled: enabled, child: child),
      full: full,
      short: short ?? full,
    ));
    if (_caliberFromModel) {
      final variants = _rifleVariants;
      for (final (i, r) in variants.indexed) {
        final label = _variantLabel(r, variants);
        add(
          'v:$i',
          Text(label, maxLines: 2),
          label,
          short: _shortCartridge(r.cartridge),
        );
      }
      add(_otherCaliberKey, const Text('Diğer kalibre'), 'Diğer kalibre');
      return out;
    }
    if (platform == WeaponPlatform.firearm) {
      void header(String key, String text) => add(
        key,
        Text(text, style: const TextStyle(fontSize: 12)),
        text,
        enabled: false,
      );
      header('#popular', 'EN ÇOK KULLANILAN');
      for (final (i, (name, d)) in _firearmCartridges.indexed) {
        if (i == _popularCount) {
          header('#all', 'DİĞERLERİ (A-Z)');
        }
        add(
          name,
          // The list is as wide as the half box (owner, 2026-10-13): the
          // mm goes under the name when both do not fit on one line, so a
          // narrow list or large text never overflows.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MenzilSpace.xs,
              children: [
                Text(name),
                Text(
                  '${d.toStringAsFixed(2).replaceAll('.', ',')} mm',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          name,
          short: _shortCartridge(name),
        );
      }
      if (cal != null && !_caliberByDiameter && _cartridgeFor(cal) == null) {
        final mm = _trimDot(cal);
        add(
          'mm:$mm',
          Text('$mm mm (kayıtlı)'),
          '$mm mm (kayıtlı)',
          short: '$mm mm',
        );
      }
      add(
        _noCartridgeKey,
        const Text('Fişeğim listede yok'),
        'Fişeğim listede yok',
        short: 'Listede yok',
      );
      return out;
    }
    for (final (mm, name) in _pcpCalibers) {
      add('mm:${_trimDot(mm)}', Text(name), name);
    }
    if (cal != null && _caliberItem(cal) == null) {
      final mm = _trimDot(cal);
      add(
        'mm:$mm',
        Text('$mm mm (kayıtlı)'),
        '$mm mm (kayıtlı)',
        short: '$mm mm',
      );
    }
    return out;
  }

  void _onCaliberKey(String? key) {
    if (key == null || key.startsWith('#')) return;
    if (key == _otherCaliberKey) {
      _caliberAll = true;
      _rifleVariant = null;
      return;
    }
    if (key.startsWith('v:')) {
      _applyRifleVariant(_rifleVariants[int.parse(key.substring(2))]);
      return;
    }
    if (key == _noCartridgeKey) {
      _caliberByDiameter = true;
      _cartridge = null;
      final cal = _parse(rifleCaliber);
      if (cal != null &&
          !_bulletDiameters.any((d) => (d - cal).abs() < 0.005)) {
        rifleCaliber.text = '';
      }
      return;
    }
    _caliberByDiameter = false;
    if (key.startsWith('mm:')) {
      _cartridge = null;
      rifleCaliber.text = key.substring(3);
      return;
    }
    _cartridge = key;
    final mm = _firearmCartridges.firstWhere((e) => e.$1 == key).$2;
    rifleCaliber.text = _trimDot(mm);
  }

  List<LibraryRifle> get _rifleLib => [
    for (final r in RifleLibrary.all)
      if (r.platform == platform &&
          (_domestic == null || _domesticBrands.contains(r.brand) == _domestic))
        r,
  ];

  List<String> get _rifleBrands =>
      {for (final r in _rifleLib) r.brand}.toList()..sort(_byName);

  List<String> _rifleModels(String brand) => {
    for (final r in _rifleLib)
      if (r.brand == brand) r.model,
  }.toList()..sort(_byName);

  List<LibraryRifle> get _rifleVariants => [
    for (final r in _rifleLib)
      if (r.brand == rifleBrand.text && r.model == rifleModel.text) r,
  ];

  void _applyRifleVariant(LibraryRifle r) {
    _rifleVariant = r;
    _caliberAll = false;
    _caliberByDiameter = false;
    rifleCaliber.text = _trimDot(r.diameterMm);
    _cartridge = r.platform == WeaponPlatform.firearm ? r.cartridge : null;
    if (r.twistRateIn != null) {
      rifleTwist.text = _trimDot(r.twistRateIn!);
    }
    if (r.twistDirection != null) twistDirection = r.twistDirection;
  }

  /// The rifle variant a saved Marka / Model / caliber points to, if any.
  LibraryRifle? _variantFor(String brand, String model, double? cal) {
    final list = [
      for (final r in _rifleLib)
        if (r.brand == brand && r.model == model) r,
    ];
    if (list.isEmpty) return null;
    if (cal == null) return null;
    final c = _cartridge;
    return list
            .where(
              (r) =>
                  (r.diameterMm - cal).abs() < 0.005 &&
                  (c == null || r.cartridge == c) &&
                  (r.twistRateIn == null ||
                      r.twistRateIn == _parse(rifleTwist)),
            )
            .firstOrNull ??
        list.where((r) => (r.diameterMm - cal).abs() < 0.005).firstOrNull;
  }

  /// A listed ammunition belongs to its caliber: another caliber empties
  /// it (a typed one stays).
  void _keepAmmoInCaliber((String, String?) before) {
    if (before == (rifleCaliber.text, _cartridge)) return;
    if (!_ammoManual && ammoBrand.text.isNotEmpty) _clearAmmo();
  }

  /// Empties the rifle part chosen from the lists.
  void _clearRifleChoice() {
    _rifleVariant = null;
    _caliberAll = false;
    _caliberByDiameter = false;
    _cartridge = null;
    rifleCaliber.text = '';
  }

  /// Namlu çıkış hızı, a half box beside Sıfırlama mesafesi on the last
  /// Tüfek row (owner, 2026-10-14 18:58; it sat left of Kalibre before).
  Widget _velocityField() => MenzilInput(
    key: const Key('profile-velocity-fps'),
    controller: velocity,
    label: 'Namlu çıkış hızı',
    unit: 'fps',
    info: platform == WeaponPlatform.firearm
        ? ProfileFieldInfo.velocityFirearm
        : ProfileFieldInfo.velocity,
    onChanged: (_) => _update(() {}),
    errorText: _shown(_velocityError, velocity),
  );

  /// Kalibre, full width and alone on its row under Marka and Model (owner,
  /// 2026-10-14 18:56–18:58: an exception to "two boxes per row" for Marka,
  /// Model and Kalibre). A long choice keeps its size and wraps; the box
  /// grows (like the Model boxes, #308).
  Widget _caliberField() {
    final choices = _caliberChoices;
    return MenzilFullWidth(
      child: KeyedSubtree(
        key: const Key('rifle-caliber'),
        child: MenzilSelect<String>(
          key: ValueKey(
            'rifle-caliber-${platform.name}-${rifleCaliber.text}-'
            '$_cartridge-${rifleBrand.text}-${rifleModel.text}-'
            '$_caliberAll-$_caliberByDiameter',
          ),
          info: platform == WeaponPlatform.firearm
              ? ProfileFieldInfo.caliberFirearm
              : ProfileFieldInfo.caliber,
          label: 'Kalibre',
          hint: 'Seçiniz',
          initialValue: _caliberKey,
          items: [for (final c in choices) c.item],
          wrapSelected: true,
          // The open list is as wide as the box, never wider (owner,
          // 2026-10-13: "kutudan dışarı çıkmasın"), so a long cartridge may
          // wrap there: its entry grows with it instead of keeping 48 pt and
          // spilling over the next one (a tap on its lower half chose
          // nothing).
          itemHeight: null,
          selectedLabels: [for (final c in choices) c.full],
          // Kept for the box's short form; unused while the text wraps.
          shortSelectedLabels: [for (final c in choices) c.short],
          onChanged: (v) => _update(() {
            final before = (rifleCaliber.text, _cartridge);
            _onCaliberKey(v);
            _keepAmmoInCaliber(before);
          }),
        ),
      ),
    );
  }

  /// Opens the typed rifle entry ("Aradığın tüfek listede yok mu?", and the
  /// hidden "Listede yok" item): Marka and Model start empty; a listed
  /// ammunition of another caliber goes as before.
  void _openRifleManual() {
    final before = (rifleCaliber.text, _cartridge);
    rifleModel.text = '';
    _clearRifleChoice();
    _keepAmmoInCaliber(before);
    _rifleManual = true;
    rifleBrand.text = '';
  }

  /// Marka | Model of the rifle: two lists side by side; typed boxes after
  /// "Aradığın tüfek listede yok mu?" (owner, 2026-10-11, 2026-10-14).
  List<Widget> _rifleNameFields() {
    final brands = _rifleBrands;
    if (_rifleManual || brands.isEmpty) {
      return [
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('rifle-brand'),
            controller: rifleBrand,
            label: 'Marka',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => _update(() {}),
            errorText: _shown(_brandError, rifleBrand),
          ),
        ),
        MenzilFullWidth(
          child: MenzilInput(
            key: const Key('rifle-model'),
            controller: rifleModel,
            label: 'Model',
            keyboardType: TextInputType.text,
            maxLength: 100,
            onChanged: (_) => _update(() {}),
            errorText: _shown(_modelError, rifleModel),
          ),
        ),
        if (brands.isNotEmpty)
          MenzilFullWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('rifle-back-to-list'),
                onPressed: () => _update(() {
                  _rifleManual = false;
                  rifleBrand.text = '';
                  rifleModel.text = '';
                  _clearRifleChoice();
                }),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Listeden seç'),
              ),
            ),
          ),
      ];
    }
    final brand = brands.contains(rifleBrand.text) ? rifleBrand.text : null;
    final models = brand == null ? const <String>[] : _rifleModels(brand);
    final model = models.contains(rifleModel.text) ? rifleModel.text : null;
    return [
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('rifle-brand-select'),
          child: MenzilSelect<String>(
            key: ValueKey('rifle-brand-select-${platform.name}-$brand'),
            label: 'Marka',
            hint: 'Seçiniz',
            initialValue: brand,
            // A long brand keeps its size and wraps; the box grows (owner,
            // 2026-10-14 18:58, like Model).
            wrapSelected: true,
            items: [
              for (final b in brands)
                DropdownMenuItem(value: b, child: Text(b)),
              if (_showRifleListedeYok)
                const DropdownMenuItem(
                  value: _manualKey,
                  child: Text('Listede yok'),
                ),
            ],
            onChanged: (v) => _update(() {
              if (v == _manualKey) {
                _openRifleManual();
                return;
              }
              final before = (rifleCaliber.text, _cartridge);
              rifleModel.text = '';
              _clearRifleChoice();
              _keepAmmoInCaliber(before);
              rifleBrand.text = v ?? '';
            }),
          ),
        ),
      ),
      MenzilFullWidth(
        child: KeyedSubtree(
          key: const Key('rifle-model-select'),
          child: MenzilSelect<String>(
            key: ValueKey('rifle-model-select-$brand-$model'),
            label: 'Model',
            hint: 'Seçiniz',
            initialValue: model,
            // A long model keeps its size and wraps; the box grows (owner,
            // 2026-10-14: like Mühimmat Model).
            wrapSelected: true,
            items: [
              for (final m in models)
                DropdownMenuItem(value: m, child: Text(m, maxLines: 2)),
            ],
            onChanged: (v) => _update(() {
              final before = (rifleCaliber.text, _cartridge);
              rifleModel.text = v ?? '';
              _clearRifleChoice();
              final variants = _rifleVariants;
              // One caliber: it is chosen right away.
              if (variants.length == 1) _applyRifleVariant(variants.first);
              _keepAmmoInCaliber(before);
            }),
          ),
        ),
      ),
      // Owner, 2026-10-14: the typed entry opens from this link instead of
      // a "Listede yok" item in the Marka list (Ateşli and PCP).
      MenzilFullWidth(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('rifle-not-listed'),
            onPressed: () => _update(_openRifleManual),
            child: const Text('Aradığın tüfek listede yok mu?'),
          ),
        ),
      ),
    ];
  }

  /// "Tüfek" heading and card.
  List<Widget> _rifleSection() => [
    const MenzilSectionHeader(
      'Tüfek',
      padding: EdgeInsets.only(top: MenzilSpace.xxs, bottom: MenzilSpace.sm),
    ),
    MenzilCard(
      key: const Key('profile-rifle-form'),
      padding: const EdgeInsets.fromLTRB(
        MenzilSpace.lg,
        MenzilSpace.lg,
        MenzilSpace.lg,
        MenzilSpace.xxs,
      ),
      child: MenzilFieldGrid(
        children: [
          // Owner, 2026-10-11: Marka, Model and Kalibre are picked
          // from lists. Order (owner, 2026-10-14 18:56–18:58): Marka,
          // Model, Kalibre each alone on a full row; then Yiv oranı |
          // Namlu yiv yönü, Sight height | Mesafe birimi, Sıfırlama
          // mesafesi | Namlu çıkış hızı.
          ..._rifleNameFields(),
          _caliberField(),
          if (platform == WeaponPlatform.firearm && _caliberByDiameter)
            MenzilFullWidth(
              child: KeyedSubtree(
                key: const Key('rifle-bullet-diameter'),
                child: MenzilSelect<double>(
                  key: ValueKey('rifle-diameter-${rifleCaliber.text}'),
                  info: ProfileFieldInfo.bulletDiameter,
                  label: 'Mermi çapı',
                  hint: 'Seçiniz',
                  initialValue: _bulletDiameters
                      .where(
                        (d) => (d - (_parse(rifleCaliber) ?? -1)).abs() < 0.005,
                      )
                      .firstOrNull,
                  items: [
                    for (final d in _bulletDiameters)
                      DropdownMenuItem(
                        value: d,
                        child: Text(_diameterLabel(d)),
                      ),
                  ],
                  onChanged: (v) => _update(() {
                    final before = (rifleCaliber.text, _cartridge);
                    if (v != null) {
                      rifleCaliber.text = _trimDot(v);
                    }
                    _keepAmmoInCaliber(before);
                  }),
                ),
              ),
            ),
          MenzilInput(
            key: const Key('rifle-twist-rate'),
            info: ProfileFieldInfo.twistRate,
            controller: rifleTwist,
            label: 'Yiv oranı',
            onChanged: (_) => _update(() {}),
            errorText: _shown(_twistError, rifleTwist),
          ),
          KeyedSubtree(
            key: const Key('rifle-twist-direction'),
            child: MenzilSelect<TwistDirection>(
              // Rebuilt when a listed rifle fills the direction.
              key: ValueKey('rifle-twist-direction-$twistDirection'),
              info: ProfileFieldInfo.twistDirection,
              label: 'Namlu yiv yönü',
              initialValue: twistDirection,
              items: const [
                DropdownMenuItem(
                  value: TwistDirection.right,
                  child: Text('Sağ'),
                ),
                DropdownMenuItem(
                  value: TwistDirection.left,
                  child: Text('Sol'),
                ),
              ],
              onChanged: (v) => _update(() => twistDirection = v),
            ),
          ),
          if (_showErrors && twistDirection == null)
            const MenzilFullWidth(
              child: MenzilNotice(
                tone: MenzilNoticeTone.danger,
                message: 'Namlu yiv yönünü seçin (Sağ / Sol).',
              ),
            ),
          MenzilInput(
            key: const Key('scope-sight-height'),
            info: platform == WeaponPlatform.firearm
                ? ProfileFieldInfo.sightHeightFirearm
                : ProfileFieldInfo.sightHeight,
            controller: sight,
            label: 'Sight height',
            unit: 'mm',
            onChanged: (_) => _update(() {}),
            errorText: sight.text.isNotEmpty && !_validSight
                ? '0–300 mm arasında geçerli bir değer girin.'
                : null,
          ),
          MenzilSelect<DistanceUnit>(
            key: const Key('profile-distance-unit'),
            info: ProfileFieldInfo.distanceUnit,
            label: 'Mesafe birimi',
            initialValue: _distanceUnitSet ? distanceUnit : null,
            items: const [
              DropdownMenuItem(value: DistanceUnit.meter, child: Text('Metre')),
              DropdownMenuItem(value: DistanceUnit.yard, child: Text('Yard')),
            ],
            onChanged: (v) => _update(() {
              _distanceUnitSet = v != null;
              final next = v ?? DistanceUnit.meter;
              // The typed zero keeps its real distance.
              final typed = _parse(zero);
              if (typed != null && next != distanceUnit) {
                final v = _round1(
                  next.fromMeters(distanceUnit.toMeters(typed)),
                );
                // Same style as the prefilled value ("27.3").
                zero.text = v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
              }
              distanceUnit = next;
            }),
          ),
          MenzilInput(
            key: const Key('profile-zero'),
            controller: zero,
            label: 'Sıfırlama mesafesi',
            // Follows Mesafe birimi; "m" while it is not chosen yet.
            unit: distanceUnit.symbol,
            info: platform == WeaponPlatform.firearm
                ? ProfileFieldInfo.zeroFirearm
                : ProfileFieldInfo.zero,
            onChanged: (_) => _update(() {}),
            errorText: _shown(_zeroError, zero),
          ),
          _velocityField(),
        ],
      ),
    ),
  ];
}
