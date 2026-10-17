part of 'ballistics_screen.dart';

/// Hava Durumu sayfası: Hava kartı, Basınç Ölçer, İrtifa, Rüzgâr ve Hava
/// özeti. Profil yokken gösterilen Hava Durumu da burada.
///
/// Modül ayrımı (owner, 2026-10-15): ballistics_screen.dart'tan aynen
/// taşındı; durum ve hesap ballistics_screen.dart'ta kalır.
extension _HavaDurumuView on _BallisticsScreenState {
  /// The Hava Durumu page (BallisticsView.environment).
  Widget _havaDurumuPage(BuildContext context) {
    // Hava Durumu and Pro Ayarlar only: compact boxes (label above a
    // 44 pt box, unit inside, ⓘ at the label row's right; owner "Fikir 4",
    // 2026-10-13, ⓘ moved 2026-10-17).
    return MenzilCompactFields(
      reserveInfo: false,
      child: MenzilPage(
        key: const PageStorageKey('ballistics-environment'),
        children: [
          // The read-only "Konumdan canlı hava verisi" button was removed
          // (owner, 2026-10-12); the page stays in Araçlar. The fetch
          // buttons sit under the Hava Durumu boxes.
          ..._environmentInputs(
            context,
            collapseShotInputs: true,
            sectionGaps: true,
          ),
          if (widget.onContinueToPro != null)
            MenzilPrimaryButton(
              key: const Key('environment-continue-pro'),
              label: 'Pro Ayarlar\'a geç',
              onPressed: () {
                _quietSolve();
                widget.onContinueToPro!();
              },
            )
          else
            MenzilPrimaryButton(label: 'Hesapla', onPressed: solve),
          // Hava özeti 20 pt under the button, like every section title on
          // this page (owner, 2026-10-17).
          _atmosphereResult(context, gapAbove: MenzilSpace.xl),
        ],
      ),
    );
  }

  Widget _weatherFillCard(BuildContext context) {
    final status = _weatherStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full width, one line (owner, 2026-10-14).
        MenzilSecondaryButton(
          key: const Key('environment-fill-weather'),
          label: _weatherBusy
              ? 'Alınıyor…'
              : _weatherOrange
              ? 'Hava verisi alındı'
              : _weatherStale
              // Older than 30 minutes: the values stay, the button asks
              // for a new fetch (owner, 2026-10-14).
              ? 'Veriyi yenile'
              : _weatherWasReset
              ? 'Tekrar canlı konum verisi al'
              : 'Konumdan canlı hava verisi al',
          // No icons in buttons; only "Hava verisi alındı" keeps its ✓
          // (owner, 2026-10-15).
          icon: _weatherOrange ? Icons.check : null,
          expand: true,
          active: _weatherOrange,
          twoLines: true,
          maxLabelLines: 1,
          onPressed: _weatherBusy ? null : () => _fillWeather(overwrite: true),
        ),
        _dateResetRow(
          dateKey: const Key('environment-weather-date'),
          date: _whenText(_weatherFilled ? _weatherFetchedAtMs : null),
          wasReset: _weatherWasReset,
          resetKey: const Key('environment-weather-reset'),
          onReset: _resetWeather,
        ),
        if (status != null) ...[
          const SizedBox(height: MenzilSpace.xs),
          MenzilNotice(
            key: const Key('environment-weather-status'),
            tone: _weatherFailed
                ? MenzilNoticeTone.warning
                : MenzilNoticeTone.info,
            message: status,
          ),
        ],
      ],
    );
  }

  Widget _environmentWithoutProfile(BuildContext context) {
    final c = MenzilColors.of(context);
    // Compact boxes on Hava Durumu (owner "Fikir 4", 2026-10-13).
    return MenzilCompactFields(
      reserveInfo: false,
      child: MenzilPage(
        key: const PageStorageKey('ballistics-environment-empty'),
        children: [
          MenzilCard(
            key: const Key('environment-no-profile'),
            // Plain card, thin orange edge (owner, 2026-10-12).
            borderColor: c.amber,
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: c.amber, size: 28),
                const SizedBox(width: MenzilSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hava hazır, sıra tüfekte',
                        style: MenzilType.heading(c.ink, size: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Profil oluşturunca bu değerler her atışın hesabına '
                        'otomatik girer.',
                        style: MenzilType.caption(c.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MenzilSpace.md),
          ..._environmentInputs(
            context,
            collapseShotInputs: true,
            sectionGaps: true,
          ),
          MenzilPrimaryButton(
            key: const Key('environment-create-profile'),
            label: 'Profil oluştur',
            amber: true,
            onPressed: widget.onCreateProfile,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Ortam
  // -------------------------------------------------------------------------

  /// [sectionGaps] (the Hava Durumu pages, owner 2026-10-17 20:02/20:03):
  /// a card's edge → the next section title's text 20 pt, the title's text
  /// → its card 8 pt; the cards before a title drop their 10 pt margin and
  /// the title holds the whole gap (its ⓘ's 44 pt target fits inside it).
  /// The Rüzgâr card has no empty padding above its field labels. Balistik /
  /// DOPE keeps the old layout.
  List<Widget> _environmentInputs(
    BuildContext context, {
    required bool collapseShotInputs,
    bool sectionGaps = false,
  }) {
    // Only the full "Balistik / DOPE" view shows (and edits) these; the
    // shell takes them from Profil.
    final shotInputs = MenzilFieldGrid(
      children: [
        MenzilInput(
          key: BallisticsFieldKeys.velocity,
          controller: velocity,
          label: 'Namlu çıkış hızı',
          unit: 'fps',
          info: _isFirearm
              ? ProfileFieldInfo.velocityFirearm
              : ProfileFieldInfo.velocity,
        ),
        MenzilInput(
          key: BallisticsFieldKeys.grain,
          controller: grain,
          label: 'Mühimmat ağırlığı',
          unit: 'grain',
          info: _isFirearm
              ? ProfileFieldInfo.grainFirearm
              : ProfileFieldInfo.grain,
          onChanged: (_) => _update(() {}),
        ),
        MenzilInput(
          key: BallisticsFieldKeys.zero,
          controller: zero,
          label: 'Sıfırlama mesafesi',
          unit: _distanceUnit,
          info: _isFirearm
              ? ProfileFieldInfo.zeroFirearm
              : ProfileFieldInfo.zero,
        ),
        MenzilInput(
          key: BallisticsFieldKeys.sight,
          controller: sight,
          label: 'Sight height',
          unit: metric ? 'mm' : 'in',
          info: _isFirearm
              ? ProfileFieldInfo.sightHeightFirearm
              : ProfileFieldInfo.sightHeight,
        ),
      ],
    );

    // The card before a section title: no margin with [sectionGaps].
    const beforeTitle = EdgeInsets.zero;
    const cardMargin = EdgeInsets.only(bottom: MenzilSpace.md);
    final gap = sectionGaps ? MenzilSpace.xl : null;
    final warning = _pressureWarning;
    return [
      // No "Hava" title over the top card (owner, 2026-10-16 21:10: the top
      // bar already says "Hava Durumu"). The card is the page's first child,
      // MenzilPage's top padding (MenzilSpace.md, 10 pt) under the top bar,
      // like the first card on Pro Ayarlar.
      MenzilCard(
        margin: sectionGaps ? beforeTitle : cardMargin,
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
        ),
        // The fetch buttons under the boxes (owner, 2026-10-12).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenzilFieldGrid(
              children: [
                MenzilInput(
                  key: BallisticsFieldKeys.temperature,
                  controller: temperature,
                  label: 'Sıcaklık',
                  // A typed value is the user's: auto fill keeps it.
                  onChanged: (_) {
                    _userEdited.add(temperature);
                    if (_weatherFilled || _weatherWasReset) {
                      _update(() => _weatherFilled = _weatherWasReset = false);
                    }
                  },
                  info: EnvironmentFieldInfo.temperatureFor(
                    firearm: _isFirearm,
                  ),
                  unit: metric ? '°C' : '°F',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                MenzilInput(
                  key: BallisticsFieldKeys.humidity,
                  controller: humidity,
                  label: 'Bağıl nem',
                  // A typed value is the user's: auto fill keeps it.
                  onChanged: (_) {
                    _userEdited.add(humidity);
                    if (_weatherFilled || _weatherWasReset) {
                      _update(() => _weatherFilled = _weatherWasReset = false);
                    }
                  },
                  info: EnvironmentFieldInfo.humidity,
                  unit: '%',
                ),
              ],
            ),
            _weatherFillCard(context),
          ],
        ),
      ),
      // Basınç Ölçer (owner, 2026-10-14): one ⓘ right of the title (none in
      // the box), İstasyon basıncı | Basınç al, then date | Sıfırla.
      _headerWithInfo(
        'Basınç Ölçer',
        EnvironmentFieldInfo.barometerCard,
        infoKey: const Key('environment-barometer-info'),
        gapAbove: gap,
      ),
      MenzilCard(
        key: const Key('environment-barometer-card'),
        margin: sectionGaps ? beforeTitle : cardMargin,
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _boxButtonRow(
              box: MenzilInput(
                key: BallisticsFieldKeys.pressure,
                controller: pressure,
                label: 'İstasyon basıncı',
                // A typed value is the user's: auto fill keeps it.
                onChanged: (_) => _update(() {
                  _userEdited.add(pressure);
                  _pressureFilled = false;
                  _pressureWasReset = false;
                }),
                unit: metric ? 'hPa' : 'inHg',
              ),
              button: MenzilSecondaryButton(
                key: const Key('environment-phone-pressure'),
                label: _pressureBusy
                    ? 'Okunuyor…'
                    : _pressureOrange
                    ? 'Basınç alındı'
                    : _pressureStale
                    ? 'Basıncı yenile'
                    : 'Basınç al',
                expand: true,
                active: _pressureOrange,
                twoLines: true,
                // One line, shrinking when it must (owner, 2026-10-14).
                maxLabelLines: 1,
                onPressed: _pressureBusy ? null : _readPhonePressure,
              ),
            ),
            _dateResetRow(
              dateKey: const Key('environment-pressure-date'),
              date: _whenText(_pressureFilled ? _pressureFetchedAtMs : null),
              wasReset: _pressureWasReset,
              resetKey: const Key('environment-pressure-reset'),
              onReset: _resetPressure,
            ),
            if (_pressureStatus != null) ...[
              const SizedBox(height: MenzilSpace.xs),
              MenzilNotice(
                key: const Key('environment-phone-pressure-status'),
                tone: _pressureFailed
                    ? MenzilNoticeTone.warning
                    : MenzilNoticeTone.info,
                message: _pressureStatus!,
              ),
            ],
          ],
        ),
      ),
      // İrtifa (owner, 2026-10-16): one box | "İrtifa al" (map, else phone
      // GPS), one ⓘ in the title.
      _headerWithInfo(
        'İrtifa',
        EnvironmentFieldInfo.altitudeCard,
        infoKey: const Key('environment-altitude-info'),
        gapAbove: gap,
      ),
      MenzilCard(
        key: const Key('environment-altitude-card'),
        // The pressure warning keeps its 10 pt under the card.
        margin: sectionGaps && warning == null ? beforeTitle : cardMargin,
        padding: const EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _boxButtonRow(
              box: MenzilInput(
                key: BallisticsFieldKeys.altitude,
                controller: altitude,
                label: 'İrtifa',
                // A typed value is used as is ("İrtifa alındı" clears).
                onChanged: (_) => _altitudeTyped(),
                unit: metric ? 'm' : 'ft',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              button: MenzilSecondaryButton(
                key: const Key('environment-altitude-fetch'),
                label: _altBusy
                    ? 'Alınıyor…'
                    : _altAtMs != null
                    ? 'İrtifa alındı'
                    : 'İrtifa al',
                expand: true,
                active: _altAtMs != null,
                twoLines: true,
                maxLabelLines: 1,
                onPressed: _altBusy ? null : _readAltitude,
              ),
            ),
            if (_altitudeStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: MenzilSpace.xs),
                child: MenzilNotice(
                  key: const Key('environment-altitude-status'),
                  tone: MenzilNoticeTone.warning,
                  message: _altitudeStatus!,
                ),
              ),
            _dateResetRow(
              dateKey: const Key('environment-altitude-date'),
              date: _whenText(_altAtMs),
              wasReset: _altitudeWasReset,
              resetKey: const Key('environment-altitude-reset'),
              onReset: _resetAltitude,
            ),
          ],
        ),
      ),
      // Outside the field grid on purpose: inserting it between the fields
      // re-parented them and a typed value could be lost.
      if (warning != null)
        MenzilNotice(
          key: const Key('environment-pressure-warning'),
          tone: MenzilNoticeTone.warning,
          message: warning,
          // The Rüzgâr title under it holds the 20 pt gap.
          margin: sectionGaps
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: MenzilSpace.md),
        ),
      // Rüzgâr: its ⓘ opens the "Rüzgâr tahmini nasıl yapılır?" guide
      // (owner, 2026-10-15); the separate link was deleted (HDF-1).
      if (gap == null)
        MenzilSectionHeader(
          'Rüzgâr',
          size: 18,
          padding: const EdgeInsets.only(
            top: MenzilSpace.xxs,
            bottom: MenzilSpace.sm,
          ),
          titleTrailing: MenzilInfoButton(
            key: const Key('environment-wind-info'),
            title: 'Rüzgâr',
            tooltip: WindGuide.linkLabel,
            onPressed: () => WindGuide.show(context, metric: metric),
          ),
        )
      else
        MenzilSectionHeader(
          'Rüzgâr',
          size: 18,
          textGapAbove: gap,
          titleInfo: (alignment, padding) => MenzilInfoButton(
            key: const Key('environment-wind-info'),
            title: 'Rüzgâr',
            tooltip: WindGuide.linkLabel,
            alignment: alignment,
            padding: padding,
            onPressed: () => WindGuide.show(context, metric: metric),
          ),
        ),
      MenzilCard(
        // No empty card padding above the field labels (owner, 2026-10-17):
        // their row starts with the ⓘ's 44 pt tap target.
        padding: EdgeInsets.fromLTRB(
          MenzilSpace.lg,
          sectionGaps ? 0 : MenzilSpace.lg,
          MenzilSpace.lg,
          MenzilSpace.xxs,
        ),
        child: MenzilFieldGrid(
          children: [
            // Ö2: Beaufort over land; long item texts, so a full row.
            // Hidden behind WIND_OBSERVATION (owner, 2026-10-13).
            if (_BallisticsScreenState._showWindObservation)
              MenzilFullWidth(
                child: MenzilSelect<int>(
                  key: ValueKey('wind-observation-$_windObservationToken'),
                  label: 'Rüzgâr gözlemi',
                  hint: 'Seçiniz',
                  info: EnvironmentFieldInfo.windObservation,
                  initialValue: _windObservation,
                  // "Seçiniz" stays in the list so the shooter can look and
                  // leave without choosing (owner, 2026-10-12).
                  items: [
                    const DropdownMenuItem<int>(child: Text('Seçiniz')),
                    for (final b in Beaufort.classes)
                      DropdownMenuItem(
                        value: b.force,
                        child: Text('${b.name}: ${b.land}', maxLines: 2),
                      ),
                  ],
                  selectedLabels: [
                    'Seçiniz',
                    for (final b in Beaufort.classes) b.name,
                  ],
                  onChanged: _pickWindObservation,
                ),
              ),
            MenzilInput(
              key: BallisticsFieldKeys.wind,
              controller: wind,
              label: 'Rüzgâr hızı',
              // A typed value is the user's: auto fill keeps it. It no
              // longer comes from the Rüzgâr gözlemi class.
              onChanged: (_) {
                _userEdited.add(wind);
                _windMaxFollowsWind();
                // The weather button stays orange (owner, 2026-10-13): only
                // a typed Sıcaklık or Bağıl nem means the weather is no
                // longer the fetched one.
                if (_windObservation != null) {
                  _update(() {
                    _windObservation = null;
                    _windObservationToken++;
                  });
                }
              },
              info: EnvironmentFieldInfo.windSpeedFor(firearm: _isFirearm),
              unit: metric ? 'm/s' : 'mph',
            ),
            MenzilInput(
              key: BallisticsFieldKeys.windDirection,
              controller: windHour,
              label: 'Rüzgâr yönü',
              unit: 'saat',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 2,
              // The time it was set shows under the dial (owner,
              // 2026-10-14).
              onChanged: (_) => _update(_windDirectionSet),
              info: EnvironmentFieldInfo.windDirection,
            ),
            // Clock face: nothing pre-selected; a tapped hour fills the box.
            MenzilFullWidth(
              child: WindClockPicker(
                hour: _windHourValue,
                dateText: _whenText(
                  _windHourValue == null ? null : _windDirAtMs,
                ),
                onChanged: (h) => _update(() {
                  windHour.text = '$h';
                  _windDirectionSet();
                }),
              ),
            ),
            // The fetched wind as a note, same box as the Hava note (owner,
            // 2026-10-17 20:40); last in the grid so no field re-parents.
            if (_windSourceNote case final note?)
              MenzilFullWidth(
                child: MenzilNotice(
                  key: const Key('environment-wind-source-note'),
                  message: note,
                ),
              ),
          ],
        ),
      ),
      // Hava Durumu no longer shows "Atış girdileri" (owner, 2026-10-08):
      // they come from Profil and are edited there.
      if (!collapseShotInputs) ...[
        const MenzilSectionHeader(
          'Atış girdileri',
          padding: EdgeInsets.only(
            top: MenzilSpace.xxs,
            bottom: MenzilSpace.sm,
          ),
        ),
        MenzilCard(
          padding: const EdgeInsets.fromLTRB(
            MenzilSpace.lg,
            MenzilSpace.lg,
            MenzilSpace.lg,
            MenzilSpace.xxs,
          ),
          child: shotInputs,
        ),
      ],
    ];
  }

  /// [gapAbove]: Hava Durumu's exact 20 pt / 8 pt title gaps (owner,
  /// 2026-10-17); null keeps the Balistik / DOPE layout.
  Widget _atmosphereResult(BuildContext context, {double? gapAbove}) {
    final c = MenzilColors.of(context);
    if (airDensityKgM3 == null) return const SizedBox.shrink();
    // "Hava özeti" (owner, 2026-10-15): a title above the summary card, like
    // the other Hava Durumu cards.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gapAbove == null)
          const MenzilSectionHeader(
            'Hava özeti',
            key: Key('environment-summary-header'),
            size: 18,
            padding: EdgeInsets.only(
              top: MenzilSpace.xxs,
              bottom: MenzilSpace.sm,
            ),
          )
        else
          MenzilSectionHeader(
            'Hava özeti',
            key: const Key('environment-summary-header'),
            size: 18,
            textGapAbove: gapAbove,
          ),
        MenzilCard(
          key: const Key('environment-summary-card'),
          background: c.surface,
          child: Text(
            'Hava yoğunluğu: ${airDensityKgM3!.toStringAsFixed(4).replaceAll('.', ',')} kg/m³ • '
            'yoğunluk oranı: ${densityRatio!.toStringAsFixed(3).replaceAll('.', ',')} • '
            'ses hızı: ${speedOfSoundMps!.toStringAsFixed(1).replaceAll('.', ',')} m/s • '
            'namlu Mach: ${muzzleMach!.toStringAsFixed(3).replaceAll('.', ',')}',
            style: MenzilType.body(c.ink),
          ),
        ),
      ],
    );
  }
}
