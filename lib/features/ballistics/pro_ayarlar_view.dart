part of 'ballistics_screen.dart';

/// Pro Ayarlar sayfası: kutular (Açı, Rüzgâr düzeltmesi, Coriolis,
/// Yerçekimi, Hareketli hedef, Tüfek düzeltmeleri), özet yazıları ve
/// köprülü sürümlerde en sonda Garmin saati satırı.
///
/// Modül ayrımı (owner, 2026-10-15): ballistics_screen.dart'tan aynen
/// taşındı; durum ve hesap ballistics_screen.dart'ta kalır.
extension _ProAyarlarView on _BallisticsScreenState {
  /// The Pro Ayarlar page (BallisticsView.pro).
  Widget _proAyarlarPage(BuildContext context) {
    return MenzilCompactFields(
      reserveInfo: false,
      child: MenzilPage(
        key: const PageStorageKey('ballistics-pro'),
        children: _proSection(context),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Pro Ayarlar
  // -------------------------------------------------------------------------

  /// One Pro Ayarlar box: a tappable header with a short summary; the
  /// content shows only while it is the open box (owner, 2026-10-09: all
  /// boxes start closed, one open at a time). The box's Ne? / Neden önemli?
  /// / Nasıl? explanations ([info]) open from the ⓘ next to the title in a
  /// bottom sheet (owner, 2026-10-13: "alttan açılan sayfa"), followed by
  /// "Kutular": each of the box's [fields] with its explanation. The boxes
  /// inside have no ⓘ of their own (owner, 2026-10-16 21:17: "zaten
  /// başlıklarda info var"), so [fields] must list every one of them.
  Widget _proBox({
    required String id,
    required String title,
    required String summary,
    required List<Widget> children,
    List<ProInfoEntry> info = const [],
    List<ProInfoField> fields = const [],
  }) {
    final c = MenzilColors.of(context);
    final open = _proOpen == id;
    return MenzilCard(
      key: Key('pro-box-$id'),
      margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              key: Key('pro-section-$id'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _update(() {
                _proOpen = open ? null : id;
              }),
              // 44 pt minimum tap target (VoiceOver / HIG).
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                // [title][ⓘ][space][summary][⌄] (owner, 2026-10-16): the ⓘ
                // right after the title with its own 44 pt target, which
                // opens only the explanation; the rest of the line toggles.
                child: ProRowHeader(
                  title: title,
                  // No bold box titles (owner, 2026-10-11): regular.
                  titleStyle: MenzilType.heading(
                    c.ink,
                    size: 18,
                  ).copyWith(fontWeight: FontWeight.w400),
                  info: info.isEmpty
                      ? null
                      : proRowInfoButton(
                          key: Key('pro-info-$id'),
                          title: title,
                          onPressed: () => showProInfoSheet(
                            context,
                            title: title,
                            entries: info,
                            fields: fields,
                          ),
                        ),
                  value: summary,
                  showValue: !open,
                  valueKey: Key('pro-summary-$id'),
                  valueStyle: MenzilType.caption(c.ink2),
                  chevron: open ? Icons.expand_less : Icons.expand_more,
                  chevronColor: c.ink2,
                ),
              ),
            ),
          ),
          if (open) ...[
            const SizedBox(height: MenzilSpace.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ],
        ],
      ),
    );
  }

  String _summaryAngle() {
    final i = _inclineDeg.round(), k = _cantDeg.round();
    return i == 0 && k == 0 ? 'düz' : '$i° / $k°';
  }

  String _summaryWind() {
    if (_windZones != null) return 'bölgeli';
    final m = _windMaxMps;
    return m == null
        ? 'kapalı'
        : 'en çok ${_windLabel(m)} ${metric ? 'm/s' : 'mph'}';
  }

  String _summaryTarget() {
    final on = [
      if (_targetSpeedMps != null) 'hareketli',
      if ((_parsed(groupCtl) ?? 0) > 0) 'isabet',
    ];
    return on.isEmpty ? 'kapalı' : on.join(' · ');
  }

  /// Counts only what is entered in this box's own fields (owner,
  /// 2026-10-15): spin drift has no switch any more and the powder values
  /// come from Profil > Mühimmat, so neither is counted here.
  String _summaryRifle() {
    final zero = _zeroOffsetMrad;
    final n = [
      turretScaleCtl.text.trim().isNotEmpty,
      zero.up != 0 || zero.right != 0,
      // Mühimmat sıcaklığı is in this box since 2026-10-16 (owner): an
      // entered value is one setting on.
      _isFirearm && ammoTempCtl.text.trim().isNotEmpty,
    ].where((x) => x).length;
    return n == 0 ? 'kapalı' : '$n ayar açık';
  }

  /// Rüzgâr düzeltmesi (en yüksek rüzgâr, rüzgâr bölgeleri): back on Pro
  /// Ayarlar after Açı (owner, 2026-10-12; it was on Hava Durumu since
  /// 2026-10-11).
  Widget _windCorrectionBox(BuildContext context) {
    final windUnit = metric ? 'm/s' : 'mph';
    return _proBox(
      id: 'wind',
      title: 'Rüzgâr düzeltmesi',
      summary: _summaryWind(),
      info: const [
        ProInfoEntry(ProSectionInfo.windMax),
        ProInfoEntry(ProSectionInfo.windZones),
      ],
      fields: const [
        ProInfoField('En çok rüzgâr', EnvironmentFieldInfo.windMax),
        ProInfoField('Yol ortası', EnvironmentFieldInfo.windMid),
        ProInfoField('Hedefte', EnvironmentFieldInfo.windFar),
      ],
      // Owner, 2026-10-14: En çok rüzgâr | Düzeltme al, then date |
      // Sıfırla; the two zone boxes follow (their texts in the title ⓘ
      // sheet; no ⓘ in the boxes, owner 2026-10-16).
      children: [
        _boxButtonRow(
          box: MenzilInput(
            key: const Key('pro-wind-max'),
            controller: windMaxCtl,
            label: 'En çok rüzgâr',
            unit: windUnit,
            onChanged: (v) {
              if (_windMaxFilled || _windMaxWasReset) {
                _update(() => _windMaxFilled = _windMaxWasReset = false);
              }
              _windMaxAtMs = null;
              _coriolisChanged();
            },
          ),
          button: MenzilSecondaryButton(
            key: const Key('pro-wind-max-fill'),
            label: _windMaxFilled ? 'Düzeltme alındı' : 'Düzeltme al',
            expand: true,
            active: _windMaxFilled,
            twoLines: true,
            maxLabelLines: 1,
            onPressed: _fillWindMax,
          ),
        ),
        _dateResetRow(
          dateKey: const Key('pro-wind-max-date'),
          date: _whenText(_windMaxFilled ? _windMaxAtMs : null),
          wasReset: _windMaxWasReset,
          resetKey: const Key('pro-wind-max-reset'),
          onReset: _resetWindMax,
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilFieldGrid(
          children: [
            MenzilInput(
              key: const Key('pro-wind-mid'),
              controller: windMidCtl,
              label: 'Yol ortası',
              unit: windUnit,
              onChanged: (_) => _coriolisChanged(),
            ),
            MenzilInput(
              key: const Key('pro-wind-far'),
              controller: windFarCtl,
              label: 'Hedefte',
              unit: windUnit,
              onChanged: (_) => _coriolisChanged(),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _proSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final effect = _coriolisEffect();
    final windUnit = metric ? 'm/s' : 'mph';
    final lenUnit = metric ? 'cm' : 'in';
    const signed = TextInputType.numberWithOptions(decimal: true, signed: true);
    String len(double m) => metric
        ? '${(m.abs() * 100).toStringAsFixed(1).replaceAll('.', ',')} cm'
        : '${UnitSystem.millimetersToInches(m.abs() * 1000).toStringAsFixed(1).replaceAll('.', ',')} in';
    return [
      MenzilCard(
        key: const Key('pro-range-card'),
        margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenzilInput(
              key: const Key('pro-shot-range'),
              controller: proRangeCtl,
              label: 'Atış mesafesi',
              unit: _distanceUnit,
              info: EnvironmentFieldInfo.proShotRange,
              errorText:
                  proRangeCtl.text.trim().isNotEmpty && _proRangeM == null
                  ? '1 ile ${_displayMaxRange.toStringAsFixed(0)} '
                        '$_distanceUnit arasında olmalı.'
                  : null,
              onChanged: (_) => _update(() {}),
            ),
            if (profileResolution?.rifle.platform == WeaponPlatform.pcp)
              Row(
                children: [
                  Expanded(
                    child: MenzilSecondaryButton(
                      key: const Key('pro-range-map'),
                      label: 'Haritadan ölç',
                      expand: true,
                      onPressed: _proRangeFromMap,
                    ),
                  ),
                  const SizedBox(width: MenzilSpace.sm),
                  Expanded(
                    child: MenzilSecondaryButton(
                      key: const Key('pro-range-parallax'),
                      label: 'Paralakstan',
                      expand: true,
                      onPressed: _proRangeFromParallax,
                    ),
                  ),
                ],
              )
            else
              MenzilSecondaryButton(
                key: const Key('pro-range-map'),
                label: 'Haritadan ölç',
                expand: true,
                onPressed: _proRangeFromMap,
              ),
          ],
        ),
      ),
      _proBox(
        id: 'angle',
        title: 'Açı',
        summary: _summaryAngle(),
        info: const [
          ProInfoEntry(ProSectionInfo.incline),
          ProInfoEntry(ProSectionInfo.cant),
        ],
        fields: [
          ProInfoField(
            'Tüfek eğimi',
            EnvironmentFieldInfo.inclineFor(firearm: _isFirearm),
          ),
          ProInfoField(
            'Dürbün eğimi',
            EnvironmentFieldInfo.cantFor(firearm: _isFirearm),
          ),
        ],
        children: [_angleTiles(context)],
      ),
      _windCorrectionBox(context),
      _proBox(
        id: 'coriolis',
        title: 'Coriolis',
        summary: _coriolisOn ? 'açık' : 'kapalı',
        info: const [ProInfoEntry(ProSectionInfo.coriolis)],
        fields: [
          if (_coriolisOn) ...const [
            ProInfoField('Enlem', EnvironmentFieldInfo.latitude),
            ProInfoField('Atış yönü', EnvironmentFieldInfo.azimuth),
          ],
        ],
        children: [
          if (_coriolisOn) ...[
            const SizedBox(height: MenzilSpace.sm),
            MenzilInput(
              key: const Key('pro-latitude'),
              controller: latitudeCtl,
              label: 'Enlem',
              unit: '°',
              errorText: latitudeCtl.text.isNotEmpty && _latitude == null
                  ? '−90 ile 90 arasında olmalı.'
                  : null,
              keyboardType: signed,
              onChanged: (_) {
                if (_latFilled || _latWasReset) {
                  _update(() => _latFilled = _latWasReset = false);
                }
                _coriolisChanged();
              },
            ),
            _filledRow(
              filled: _latFilled,
              wasReset: _latWasReset,
              button: MenzilSecondaryButton(
                key: const Key('pro-latitude-gps'),
                label: _latFilled ? 'Konumdan alındı' : 'Konumdan al',
                expand: true,
                active: _latFilled,
                twoLines: true,
                maxLabelLines: 2,
                onPressed: _latitudeFromGps,
              ),
              resetKey: const Key('pro-latitude-reset'),
              onReset: _resetLatitude,
            ),
            const SizedBox(height: MenzilSpace.md),
            MenzilInput(
              key: const Key('pro-azimuth'),
              controller: azimuthCtl,
              label: 'Atış yönü',
              unit: '°',
              errorText: azimuthCtl.text.isNotEmpty && _azimuth == null
                  ? '0 ile 360 arasında olmalı.'
                  : null,
              onChanged: (_) {
                if (_aziFilled || _aziWasReset) {
                  _update(() => _aziFilled = _aziWasReset = false);
                }
                _coriolisChanged();
              },
            ),
            _filledRow(
              filled: _aziFilled,
              wasReset: _aziWasReset,
              button: MenzilSecondaryButton(
                key: const Key('pro-azimuth-compass'),
                label: _aziFilled ? 'Pusuladan alındı' : 'Pusuladan al',
                expand: true,
                active: _aziFilled,
                twoLines: true,
                maxLabelLines: 2,
                onPressed: _azimuthFromCompass,
              ),
              resetKey: const Key('pro-azimuth-reset'),
              onReset: _resetAzimuth,
            ),
            if (_coriolisStatus != null) ...[
              const SizedBox(height: MenzilSpace.xs),
              Text(_coriolisStatus!, style: MenzilType.caption(c.ink2)),
            ],
            const SizedBox(height: MenzilSpace.sm),
            Text(
              effect == null
                  ? !_dragMode
                        ? 'Coriolis, BC değeri olan mühimmatla hesaplanır.'
                        : 'Etkiyi görmek için enlem ve atış yönünü girin.'
                  : '$_shotDisplay $_distanceUnit\'de Coriolis: '
                        '${len(effect.up)} ${effect.up >= 0 ? 'yukarı' : 'aşağı'} · '
                        '${len(effect.right)} ${effect.right >= 0 ? 'sağa' : 'sola'}. '
                        'Kule klikleri bunu içerir.',
              key: const Key('pro-coriolis-effect'),
              style: MenzilType.body(c.ink),
            ),
          ],
        ],
      ),
      _proBox(
        id: 'gravity',
        title: 'Yerçekimi',
        summary: _gravityOn ? 'açık' : 'kapalı',
        info: const [ProInfoEntry(ProSectionInfo.gravity)],
        fields: [
          if (_gravityOn)
            const ProInfoField('Yerçekimi', EnvironmentFieldInfo.gravity),
        ],
        children: [
          if (_gravityOn) ...[
            const SizedBox(height: MenzilSpace.sm),
            MenzilInput(
              key: const Key('pro-gravity'),
              controller: gravityCtl,
              label: 'Yerçekimi',
              unit: 'm/s²',
              errorText: gravityCtl.text.isNotEmpty && _gravityTyped == null
                  ? '9,7 ile 9,9 arasında olmalı.'
                  : null,
              onChanged: (_) {
                if (_gravFilled || _gravWasReset) {
                  _update(() => _gravFilled = _gravWasReset = false);
                }
                _gravityChanged();
              },
            ),
            _filledRow(
              filled: _gravFilled,
              wasReset: _gravWasReset,
              button: MenzilSecondaryButton(
                key: const Key('pro-gravity-gps'),
                label: _gravFilled ? 'Konumdan hesaplandı' : 'Konumdan hesapla',
                expand: true,
                active: _gravFilled,
                twoLines: true,
                maxLabelLines: 2,
                onPressed: _gravityFromLocation,
              ),
              resetKey: const Key('pro-gravity-reset'),
              onReset: _resetGravity,
            ),
            if (_gravityStatus != null) ...[
              const SizedBox(height: MenzilSpace.xs),
              Text(_gravityStatus!, style: MenzilType.caption(c.ink2)),
            ],
            const SizedBox(height: MenzilSpace.sm),
            Builder(
              builder: (context) {
                final e = _gravityEffect();
                final mm = e == null ? null : e * 1000;
                String mmText(double v) =>
                    v.abs().toStringAsFixed(1).replaceAll('.', ',');
                return Text(
                  mm == null
                      ? 'Etkiyi görmek için "Konumdan hesapla"ya dokunun.'
                      : mm.abs() < 0.05
                      ? '$_shotDisplay $_distanceUnit\'de yerçekimi farkı '
                            'yok denecek kadar az (sıfır mesafesinde etkisi '
                            'sıfırdır; uzak mesafede büyür).'
                      : '$_shotDisplay $_distanceUnit\'de yerçekimi: mermi '
                            '${mmText(mm)} mm '
                            '${mm >= 0 ? 'daha az' : 'daha çok'} düşer '
                            '(standart 9,80665 m/s²\'ye göre). Kule klikleri '
                            'bunu içerir.',
                  key: const Key('pro-gravity-effect'),
                  style: MenzilType.body(c.ink),
                );
              },
            ),
          ],
        ],
      ),
      _proBox(
        id: 'target',
        title: 'Hareketli hedef',
        summary: _summaryTarget(),
        info: const [
          ProInfoEntry(ProSectionInfo.movingTarget),
          ProInfoEntry(ProSectionInfo.hitProbability),
        ],
        fields: const [
          ProInfoField('Hedef hızı', EnvironmentFieldInfo.targetSpeed),
          ProInfoField('Hedefin yönü', EnvironmentFieldInfo.targetDirection),
          ProInfoField('Grup çapı', EnvironmentFieldInfo.group),
          ProInfoField('Hız farkı', EnvironmentFieldInfo.sd),
          ProInfoField('Hedef çapı', EnvironmentFieldInfo.targetSize),
          ProInfoField('Mesafe hatası', EnvironmentFieldInfo.rangeError),
          ProInfoField('BC hatası', EnvironmentFieldInfo.bcError),
          ProInfoField('Atış sayısı', EnvironmentFieldInfo.wezShotCount),
        ],
        children: [
          // Owner, 2026-10-12: boxes first, Verileri sil under them; the
          // explanations are only in the title ⓘ bottom sheet (owner,
          // 2026-10-13; no ⓘ in the boxes since 2026-10-16).
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-target-speed'),
                controller: targetSpeedCtl,
                label: 'Hedef hızı',
                unit: windUnit,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilSelect<bool>(
                key: ValueKey('pro-target-direction-$_targetMovesRight'),
                label: 'Hedefin yönü',
                initialValue: _targetMovesRight,
                // "Seçiniz" stays in the list so a choice can be taken back
                // (owner, 2026-10-10).
                items: const [
                  DropdownMenuItem<bool>(child: Text('Seçiniz')),
                  DropdownMenuItem(value: true, child: Text('Soldan sağa')),
                  DropdownMenuItem(value: false, child: Text('Sağdan sola')),
                ],
                onChanged: (v) {
                  _targetMovesRight = v;
                  _coriolisChanged();
                },
              ),
            ],
          ),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-group'),
                controller: groupCtl,
                label: 'Grup çapı',
                unit: lenUnit,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-sd'),
                controller: sdCtl,
                label: 'Hız farkı',
                unit: 'fps',
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-target-size'),
                controller: targetSizeCtl,
                label: 'Hedef çapı',
                unit: lenUnit,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-range-error'),
                controller: rangeErrorCtl,
                label: 'Mesafe hatası',
                unit: _distanceUnit,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-bc-error'),
                controller: bcErrorCtl,
                label: 'BC hatası',
                unit: '%',
                onChanged: (_) => _coriolisChanged(),
              ),
              KeyedSubtree(
                key: ValueKey('pro-wez-shots-$_targetClearToken'),
                child: MenzilSelect<int>(
                  key: const Key('pro-wez-shots'),
                  label: 'Atış sayısı',
                  initialValue: _wezShotChosen ? _wezShotCount : null,
                  hint: 'Seçiniz',
                  // "Seçiniz" stays in the list (owner, 2026-10-12).
                  items: [
                    const DropdownMenuItem<int>(child: Text('Seçiniz')),
                    for (final n in Wez.shotCounts)
                      DropdownMenuItem(value: n, child: Text('$n atış')),
                  ],
                  onChanged: (v) {
                    _update(() {
                      _wezShotChosen = v != null;
                      _wezShotCount = v ?? Wez.defaultShotCount;
                    });
                    _saveShotSettings();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: MenzilSpace.sm),
          MenzilSecondaryButton(
            key: const Key('pro-target-clear'),
            label: 'Verileri sil',
            icon: Icons.delete_outline,
            destructive: true,
            expand: true,
            onPressed: _clearTargetBox,
          ),
        ],
      ),
      _proBox(
        id: 'rifle',
        title: 'Tüfek düzeltmeleri',
        summary: _summaryRifle(),
        info: [
          const ProInfoEntry(ProSectionInfo.turretScale),
          const ProInfoEntry(ProSectionInfo.zeroOffset),
          ProInfoEntry(
            ProSectionInfo.spinDrift,
            note: _isFirearm ? null : ProSectionInfo.spinDriftPcpNote,
          ),
          if (_isFirearm) const ProInfoEntry(ProSectionInfo.powder),
        ],
        fields: [
          const ProInfoField(
            'Gerçek / yazan',
            EnvironmentFieldInfo.turretScale,
          ),
          const ProInfoField('Yukarı + / aşağı −', EnvironmentFieldInfo.zeroUp),
          const ProInfoField('Sağ + / sol −', EnvironmentFieldInfo.zeroRight),
          if (_spinDriftOn)
            const ProInfoField(
              'Mermi uzunluğu',
              EnvironmentFieldInfo.bulletLength,
            ),
          if (_isFirearm)
            const ProInfoField(
              'Mühimmat sıcaklığı',
              EnvironmentFieldInfo.ammoTemperature,
            ),
        ],
        children: [
          // Owner, 2026-10-12: boxes first; the explanations are only in the
          // title ⓘ bottom sheet (2026-10-13; no ⓘ in the boxes, 2026-10-16).
          MenzilInput(
            key: const Key('pro-turret-scale'),
            controller: turretScaleCtl,
            label: 'Gerçek / yazan',
            errorText:
                turretScaleCtl.text.trim().isNotEmpty &&
                    (_parsed(turretScaleCtl) == null ||
                        _parsed(turretScaleCtl)! < 0.8 ||
                        _parsed(turretScaleCtl)! > 1.2)
                ? '0,80 ile 1,20 arasında olmalı.'
                : null,
            onChanged: (_) => _coriolisChanged(),
          ),
          MenzilFieldGrid(
            children: [
              MenzilInput(
                key: const Key('pro-zero-up'),
                controller: zeroUpCtl,
                label: 'Yukarı + / aşağı −',
                unit: lenUnit,
                keyboardType: signed,
                onChanged: (_) => _coriolisChanged(),
              ),
              MenzilInput(
                key: const Key('pro-zero-right'),
                controller: zeroRightCtl,
                label: 'Sağ + / sol −',
                unit: lenUnit,
                keyboardType: signed,
                onChanged: (_) => _coriolisChanged(),
              ),
            ],
          ),
          if (_spinDriftOn) ...[
            MenzilInput(
              key: const Key('pro-bullet-length'),
              controller: bulletLengthCtl,
              label: 'Mermi uzunluğu',
              unit: 'mm',
              onChanged: (_) => _coriolisChanged(),
            ),
            if (profileResolution?.rifle.twistRateIn == null ||
                profileResolution?.rifle.twistDirection == null)
              const MenzilNotice(
                tone: MenzilNoticeTone.warning,
                message:
                    'Profilde yiv yönü veya yiv oranı yok; spin drift '
                    'hesaplanamaz.',
              ),
          ],
          if (_isFirearm) ...[
            // Mühimmat sıcaklığı (owner, 2026-10-16, design PR #366): moved
            // here from Hava Durumu, next to the powder correction it feeds.
            // Same box, saved value and calculation (empty = the air
            // temperature); box in the left half, "isteğe bağlı" right. No ⓘ
            // in the box (owner, 2026-10-16 21:17, #373): its text is listed
            // in this section's title ⓘ sheet (ProInfoField above).
            Row(
              key: const Key('pro-ammo-temp-row'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: MenzilInput(
                    key: const Key('env-ammo-temp'),
                    controller: ammoTempCtl,
                    label: 'Mühimmat sıcaklığı',
                    onChanged: (_) => _coriolisChanged(),
                    unit: metric ? '°C' : '°F',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    // Level with the middle of the 46 pt box (the box keeps
                    // MenzilSpace.md under it).
                    padding: const EdgeInsets.only(bottom: MenzilSpace.md),
                    // At least the box height; taller when large text
                    // wraps "isteğe bağlı" (never cut off).
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: MenzilSpace.control,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'isteğe bağlı',
                          key: const Key('pro-ammo-temp-optional'),
                          textAlign: TextAlign.start,
                          style: MenzilType.caption(c.ink2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // The values are entered on Profil > Mühimmat (2026-10-11); here
            // only what is used and today's velocity.
            Builder(
              builder: (context) {
                final p = _powder;
                String n(double v) => v % 1 == 0
                    ? v.toStringAsFixed(0)
                    : v.toString().replaceAll('.', ',');
                final k = p.coef, t0 = p.referenceC;
                final where = p.fromProfile
                    ? 'Profil > Mühimmat\'tan değiştirilir.'
                    : 'Önceki sürümde burada girildi; Profil > Mühimmat\'ta '
                          'girin.';
                return Text(
                  k != null && t0 != null
                      ? 'Katsayı %${n(k)} / 15 °C, hız ölçüm sıcaklığı '
                            '${n(t0)} °C. $where'
                      : 'Barut sıcaklık katsayısı ve hız ölçüm sıcaklığı '
                            'Profil > Mühimmat\'ta girilir; girilmezse hız '
                            'düzeltilmez.',
                  key: const Key('pro-powder-source'),
                  style: MenzilType.body(c.ink),
                );
              },
            ),
            Builder(
              builder: (context) {
                final v0 = widget.profile?.muzzleVelocityMps;
                final t = _parsed(temperature);
                if (v0 == null || t == null) return const SizedBox.shrink();
                final today = _powderAdjusted(
                  v0,
                  metric ? t : UnitSystem.fahrenheitToCelsius(t),
                );
                if (today == v0) return const SizedBox.shrink();
                return Text(
                  'Bugünkü hız: ${UnitSystem.mpsToFps(today).toStringAsFixed(0)} '
                  'fps (profil ${UnitSystem.mpsToFps(v0).toStringAsFixed(0)} fps).',
                  key: const Key('pro-powder-today'),
                  style: MenzilType.body(c.ink),
                );
              },
            ),
          ],
        ],
      ),
      // Garmin saati (owner, 2026-10-16: moved from Araçlar, "isteğe
      // bağlı"): only in builds with the iOS Garmin bridge; elsewhere it
      // builds nothing and takes no space. Not a setting: no summary counts
      // it and no calculation reads it.
      const GarminPairTile(),
      const SizedBox(height: MenzilSpace.md),
      if (widget.onContinueToShot != null)
        MenzilPrimaryButton(
          key: const Key('pro-continue-shot'),
          label: 'Hedef\'e geç',
          onPressed: widget.onContinueToShot,
        ),
    ];
  }

  /// Tüfek eğimi and Dürbün eğimi, side by side (Pro Ayarlar).
  Widget _angleTiles(BuildContext context) {
    final c = MenzilColors.of(context);
    Widget tile({
      required Key key,
      required String title,
      required String value,
      required IconData icon,
      required VoidCallback onTap,
    }) => Expanded(
      child: MenzilCard(
        margin: EdgeInsets.zero,
        background: c.surface2,
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.md,
          MenzilSpace.xs,
          MenzilSpace.xxs,
          MenzilSpace.sm,
        ),
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: c.ink2),
                  const SizedBox(width: MenzilSpace.xxs),
                  Expanded(
                    child: Text(title, style: MenzilType.caption(c.ink2)),
                  ),
                ],
              ),
              Text(value, style: MenzilType.number(c.ink, size: 22)),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        tile(
          key: const Key('shot-incline'),
          title: 'Tüfek eğimi',
          value: '∠ ${ShotAngleMath.degrees(_inclineDeg)}',
          icon: Icons.terrain_outlined,
          onTap: _editIncline,
        ),
        const SizedBox(width: MenzilSpace.sm),
        tile(
          key: const Key('shot-cant'),
          title: 'Dürbün eğimi',
          value: _cantDeg == 0
              ? 'Yok'
              : '${ShotAngleMath.degrees(_cantDeg)} '
                    '${_cantDeg > 0 ? 'sağa' : 'sola'}',
          icon: Icons.rotate_right,
          onTap: _editCant,
        ),
      ],
    );
  }
}
