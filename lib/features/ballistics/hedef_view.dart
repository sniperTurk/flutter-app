part of 'ballistics_screen.dart';

/// Hedef sayfası: mesafe seçici, dürbün kartı (kuleler, retikül ve
/// hesap dökümü scope_dial_view.dart'ta) ve sonuç kartları.
///
/// Modül ayrımı (owner, 2026-10-15): ballistics_screen.dart'tan aynen
/// taşındı; durum ve hesap ballistics_screen.dart'ta kalır.
extension _HedefView on _BallisticsScreenState {
  /// The Hedef page (BallisticsView.shot).
  Widget _hedefPage(BuildContext context) {
    return MenzilPage(
      key: const PageStorageKey('ballistics-shot'),
      // The Hedef page is the only justified page (owner, 2026-10-13).
      justify: true,
      children: _shotSection(context),
    );
  }

  /// [dial] is `_scopeDial(shot)`, built once per frame (it publishes to
  /// the watch and arms the auto-dial) and shared with the result row.
  Widget _referenceShotPanel(TrajectoryPoint? shot, Widget dial) {
    // "Atış Çözümü" is the page title in the top bar (owner, 2026-10-08);
    // the Yukarı/Aşağı and Rüzgâr boxes were removed: the scope below shows
    // the clicks and the point of impact.
    return MenzilCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dial,
          ..._extraShotNotes(shot),
          // Ö9: an approved cold-bore suggestion, shown only (not dialled).
          if (widget.profile != null)
            ColdBoreHint(profileId: widget.profile!.id, unit: _scopeUnit),
        ],
      ),
    );
  }

  List<Widget> _shotSection(BuildContext context) {
    final c = MenzilColors.of(context);
    final shot = _shotPoint();
    final display = _shotDisplay;
    final dial = _scopeDial(shot);
    // The shot range may be anything up to the production limit; it is not
    // tied to the last range of the DOPE table (that made the dial stop at
    // the default table's 400 m).
    final sliderMax = math.max(
      display.toDouble(),
      _displayMaxRange.floorToDouble(),
    );

    return [
      // Range dial: −5 −1 [value] +1 +5, slider below. Dark like the rest of
      // the page; numbers in soft grey, not bright white (owner,
      // 2026-10-12: "rakamlar çok beyaz, göz yoruyor"; the field stays dark).
      Builder(
        builder: (context) {
          final c = MenzilColors.of(context);
          return DecoratedBox(
            decoration: const BoxDecoration(),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Row(
                    children: [
                      MenzilStepButton(
                        label: '−5',
                        semanticLabel: '5 azalt',
                        onPressed: () => _setShotDisplay(display - 5),
                      ),
                      const SizedBox(width: MenzilSpace.xs),
                      MenzilStepButton(
                        label: '−1',
                        semanticLabel: '1 azalt',
                        small: true,
                        onPressed: () => _setShotDisplay(display - 1),
                      ),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label:
                              'Atış mesafesi $display $_distanceUnit, değiştirmek için dokunun',
                          child: ExcludeSemantics(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                MenzilRadius.button,
                              ),
                              onTap: _editShotRange,
                              child: SizedBox(
                                height: 64,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$display',
                                        // Stepped live with ±1/±5:
                                        // equal-width figures, no jitter.
                                        style: MenzilType.display(
                                          c.ink,
                                          size: display >= 1000 ? 44 : 52,
                                          live: true,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _distanceUnit,
                                        style: MenzilType.number(
                                          c.ink2,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      MenzilStepButton(
                        label: '+1',
                        semanticLabel: '1 artır',
                        small: true,
                        onPressed: () => _setShotDisplay(display + 1),
                      ),
                      const SizedBox(width: MenzilSpace.xs),
                      MenzilStepButton(
                        label: '+5',
                        semanticLabel: '5 artır',
                        onPressed: () => _setShotDisplay(display + 5),
                      ),
                    ],
                  ),
                  Slider(
                    value: display.toDouble().clamp(1.0, sliderMax).toDouble(),
                    min: 1,
                    max: sliderMax,
                    label: '$display $_distanceUnit',
                    semanticFormatterCallback: (v) =>
                        '${v.round()} $_distanceUnit',
                    onChanged: (v) => _setShotDisplay(v.round()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Sonuç en üstte (owner, 2026-10-15 12:50): the required turret
      // solution, big, right under the slider and above the reticle card.
      // Same numbers as "Kuleleri kur" (the scope view's requiredUp /
      // requiredRight); nothing is computed here.
      if (dial is ScopeDialView && dial.requiredUp != null)
        Padding(
          padding: const EdgeInsets.only(top: MenzilSpace.xs),
          child: TurretSolutionRow(
            requiredUp: dial.requiredUp!,
            requiredRight: dial.requiredRight,
            clickValue: dial.clickValue,
            unit: dial.unit,
            windCalm: (_basis?.environment.windMps ?? 0) == 0,
          ),
        ),
      const SizedBox(height: MenzilSpace.sm),
      if (_pressureEstimated && _basis != null)
        const Padding(
          padding: EdgeInsets.only(bottom: MenzilSpace.sm),
          child: MenzilNotice(
            key: Key('shot-pressure-from-altitude'),
            tone: MenzilNoticeTone.info,
            message: 'Basınç irtifadan tahmin edildi.',
          ),
        ),
      if (shot == null)
        MenzilNotice(
          tone: MenzilNoticeTone.info,
          message: _basis == null
              ? 'Değerler hesaplanamadı. Profil ve Hava Durumu değerlerini kontrol edin.'
              : _dragMode
              ? 'Bu mermi bu mesafeye ulaşamıyor veya değer üretilemedi. Daha kısa bir mesafe deneyin.'
              : 'Bu mesafe için değer üretilemedi. Mesafeyi veya girdileri kontrol edin.',
        ),
      // No Hesapla button (owner, 2026-10-08): Atış is solved automatically
      // whenever it opens, with the Hava Durumu and Pro Ayarlar values.
      const SizedBox(height: MenzilSpace.xs),
      // Without a BC the shot uses the vacuum (no-drag) drop for elevation;
      // wind stays locked — a vacuum model has no aerodynamic coupling, so
      // it cannot produce a real wind value (see BallisticEngine.vacuumDope).
      // With a BC the drag solver (checked against py-ballisticcalc in CI)
      // gives both.
      Padding(
        padding: const EdgeInsets.only(bottom: MenzilSpace.md),
        child: _referenceShotPanel(shot, dial),
      ),
      if (_basis != null)
        Padding(
          padding: const EdgeInsets.only(bottom: MenzilSpace.md),
          child: MenzilSecondaryButton(
            key: const Key('shot-dope-pdf'),
            label: 'DOPE kartını paylaş (PDF)',
            expand: true,
            onPressed: _shareDopeCard,
          ),
        ),
      if (_dragMode) ..._dragNotices(),
      if (!_dragMode)
        const Padding(
          padding: EdgeInsets.only(bottom: MenzilSpace.md),
          child: MenzilNotice(
            tone: MenzilNoticeTone.danger,
            message:
                'Yükseklik kliki, hava direnci YOK sayılan bir vakum düşüşünden hesaplanır — '
                'gerçek mermi menzil arttıkça havadan daha çok yavaşlar, bu nedenle gerçek düşüş '
                'burada gösterilenden FAZLA olur. Rüzgâr düzeltmesi hiç modellenmez (KİLİTLİ). '
                'Bu klik değerini ilk atışta mutlaka canlı atışla (kronograf + deneme atışı) '
                'doğrulayın; tek başına gerçek atış için kullanmayın.',
          ),
        ),
      if (shot != null && _dragMode)
        MenzilMetricGrid(
          metrics: [
            MenzilMetric(
              'Uçuş süresi',
              shot.timeOfFlightS.toStringAsFixed(3).replaceAll('.', ','),
              's',
            ),
            MenzilMetric(
              'Düşüş',
              (metric
                      ? shot.dropM * 100
                      : UnitSystem.millimetersToInches(shot.dropM * 1000))
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
              metric ? 'cm' : 'in',
            ),
            MenzilMetric(
              'Hız',
              (metric
                      ? shot.velocityMps
                      : UnitSystem.mpsToFps(shot.velocityMps))
                  .toStringAsFixed(0)
                  .replaceAll('.', ','),
              metric ? 'm/s' : 'fps',
            ),
            MenzilMetric(
              'Enerji',
              (metric
                      ? shot.energyJ
                      : UnitSystem.joulesToFootPounds(shot.energyJ))
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
              metric ? 'J' : 'ft·lbf',
            ),
            if (muzzleMach != null)
              MenzilMetric(
                'Namlu Mach',
                muzzleMach!.toStringAsFixed(3).replaceAll('.', ','),
              ),
            if (densityRatio != null)
              MenzilMetric(
                'Yoğunluk oranı',
                densityRatio!.toStringAsFixed(3).replaceAll('.', ','),
              ),
          ],
        ),
      if (shot != null && !_dragMode)
        MenzilMetricGrid(
          metrics: [
            MenzilMetric(
              'Uçuş süresi',
              shot.timeOfFlightS.toStringAsFixed(3).replaceAll('.', ','),
              's',
            ),
            MenzilMetric(
              'Vakum düşüşü*',
              (metric
                      ? shot.dropM * 100
                      : UnitSystem.millimetersToInches(shot.dropM * 1000))
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
              metric ? 'cm' : 'in',
            ),
            MenzilMetric(
              'Namlu hızı*',
              (metric
                      ? shot.velocityMps
                      : UnitSystem.mpsToFps(shot.velocityMps))
                  .toStringAsFixed(0)
                  .replaceAll('.', ','),
              metric ? 'm/s' : 'fps',
            ),
            MenzilMetric(
              'Namlu enerjisi*',
              (metric
                      ? shot.energyJ
                      : UnitSystem.joulesToFootPounds(shot.energyJ))
                  .toStringAsFixed(1)
                  .replaceAll('.', ','),
              metric ? 'J' : 'ft·lbf',
            ),
            if (muzzleMach != null)
              MenzilMetric(
                'Namlu Mach',
                muzzleMach!.toStringAsFixed(3).replaceAll('.', ','),
              ),
            if (densityRatio != null)
              MenzilMetric(
                'Yoğunluk oranı',
                densityRatio!.toStringAsFixed(3).replaceAll('.', ','),
              ),
          ],
        ),
      Text(
        _dragMode
            ? 'Sürtünmeli hesap (G1/G7 + girilen BC); sabit rüzgâr tüm menzilde uygulanır. '
                  'Klik değerlerini ilk atışta canlı atışla doğrulayın.'
            : '* Vakum temelli (hava direnci modellenmez); rüzgâr düzeltmesi doğrulanmış sürüklenme '
                  'modeli gelene kadar hiç gösterilmez. Hız ve enerji namlu değeridir.',
        style: MenzilType.caption(c.ink2),
      ),
    ];
  }
}
