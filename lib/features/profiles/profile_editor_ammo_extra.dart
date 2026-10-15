part of 'profiles_screen.dart';

/// "Ek mühimmat bilgileri" of the profile editor: Barut katsayısı | Hız
/// ölçüm sıcaklığı and Hıza göre BC (moved out of profiles_screen.dart,
/// behaviour unchanged).
extension _AmmoExtraSection on _ProfileDialogState {
  /// Ek mühimmat bilgileri has something to show: Barut katsayısı | Hız
  /// ölçüm sıcaklığı (firearms) or the Hıza göre BC rows (same conditions
  /// as before the move).
  bool get _ammoExtraShown =>
      platform == WeaponPlatform.firearm ||
      (!_customCurve &&
          platform != WeaponPlatform.pcp &&
          (!_typedFirearmAmmo || _ProfileDialogState._showTypedBands));

  /// "Ek mühimmat bilgileri  isteğe bağlı ⓘ", left-aligned and always open
  /// (owner, 2026-10-14 18:07–18:20): no chevron, one ⓘ with the long
  /// "Nedir? / Neden önemli?" text.
  Widget _ammoExtraHeader(MenzilColors c) => MenzilFullWidth(
    child: Padding(
      key: const Key('ammo-extra-header'),
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Row(
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Ek mühimmat bilgileri',
                      style: MenzilType.heading(c.ink, size: 17),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: 'isteğe bağlı',
                      style: MenzilType.caption(c.ink2),
                    ),
                  ],
                ),
                key: const Key('ammo-extra-title'),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          const MenzilInfoButton(
            key: Key('ammo-extra-info'),
            title: 'Ek mühimmat bilgileri',
            text: ProfileFieldInfo.ammoExtra,
          ),
        ],
      ),
    ),
  );

  /// Barut katsayısı / Hız ölçüm sıcaklığı as a list (owner, 2026-10-14).
  /// Starts on "Seçiniz" (empty = no correction; "Seçiniz" in the list
  /// empties it again). A value not in [options] (an older profile, a
  /// maker figure) is listed as "(kayıtlı)" / "(üretici)" and kept.
  Widget _powderSelect({
    required String key,
    required TextEditingController controller,
    required String label,
    String? unit,
    required String info,
    required List<double> options,
    required String? error,
  }) {
    final cur = _ProfileDialogState._parse(controller);
    final extra = cur != null && !options.contains(cur);
    final values = [...options, if (cur != null && extra) cur]..sort();
    final tag = _powderAutoFilled ? 'üretici' : 'kayıtlı';
    return KeyedSubtree(
      key: Key(key),
      child: MenzilSelect<String>(
        key: ValueKey('$key-${controller.text}'),
        label: label,
        unit: unit,
        info: info,
        hint: 'Seçiniz',
        initialValue: cur == null ? null : _trimNum(cur),
        items: [
          const DropdownMenuItem(value: '', child: Text('Seçiniz')),
          for (final v in values)
            DropdownMenuItem(
              value: _trimNum(v),
              child: Text(
                extra && v == cur ? '${_trimNum(v)} ($tag)' : _trimNum(v),
              ),
            ),
        ],
        errorText: _shownSelect(error, controller),
        onChanged: (v) => _update(() {
          controller.text = v ?? '';
          _powderAutoFilled = false;
        }),
      ),
    );
  }

  /// The optional powder and BC-band fields (same conditions as before).
  List<Widget> _ammoExtraFields(MenzilColors c) => [
    // Ek mühimmat bilgileri (owner, 2026-10-14 18:07–18:20): the
    // optional powder and BC-band fields as their own always-open
    // sub-section at the end of Mühimmat; fields, keys, checks
    // and saving unchanged.
    if (_ammoExtraShown) _ammoExtraHeader(c),
    // Barut sıcaklığı: firearms only, never on PCP (owner,
    // 2026-10-11). Katsayı | Ölçüm sıcaklığı side by side.
    // Own row pair, so BC modeli above keeps its place (2026-10-13).
    if (platform == WeaponPlatform.firearm)
      MenzilFullWidth(
        child: MenzilFieldGrid(
          children: [
            // Lists, also for listed rounds (owner,
            // 2026-10-14); empty = no temperature correction.
            _powderSelect(
              key: 'profile-powder-coef',
              controller: powderCoef,
              // Short label: "Barut sıcaklık katsayısı" next to
              // its unit and ⓘ was cut ("…") on 375–393 pt
              // phones; the ⓘ text starts with the full name.
              // No unit beside it (owner, 2026-10-14): "%/15 °C"
              // is in the ⓘ; the label stays on one line.
              label: 'Barut katsayısı',
              info: ProfileFieldInfo.powderCoef,
              options: _ProfileDialogState._powderCoefOptions,
              error: _powderCoefError,
            ),
            _powderSelect(
              key: 'profile-powder-temp',
              controller: powderTemp,
              label: 'Hız ölçüm sıcaklığı',
              unit: '°C',
              info: ProfileFieldInfo.powderTemp,
              options: _ProfileDialogState._powderTempOptions,
              error: _powderTempError,
            ),
          ],
        ),
      ),
    // Hıza göre BC: hidden on PCP (owner, 2026-10-13: only Tip,
    // Ağırlık, BC).
    // Typed firearm round: hidden behind AMMO_BC_BANDS_TYPED
    // (owner, 2026-10-14); saved bands stay in the record.
    if (!_customCurve &&
        platform != WeaponPlatform.pcp &&
        (!_typedFirearmAmmo || _ProfileDialogState._showTypedBands)) ...[
      MenzilFullWidth(
        child: Text(
          'Hıza göre BC',
          key: const Key('ammo-bands-title'),
          style: MenzilType.body(c.ink),
        ),
      ),
      for (var i = 0; i < 2; i++) ...[
        MenzilInput(
          key: Key('ammo-band-fps-$i'),
          info: platform == WeaponPlatform.firearm
              ? ProfileFieldInfo.bandSpeedFirearm
              : ProfileFieldInfo.bandSpeed,
          controller: ammoBandFps[i],
          label: '${i + 1}. eşik hızı',
          onChanged: (_) => _update(() {}),
          errorText: _shown(_bandFpsError(i), ammoBandFps[i]),
        ),
        MenzilInput(
          key: Key('ammo-band-bc-$i'),
          info: ProfileFieldInfo.bandBc,
          controller: ammoBandBc[i],
          label: 'Eşik altı BC',
          onChanged: (_) => _update(() {}),
          errorText: _shown(_bandBcError(i), ammoBandBc[i]),
        ),
      ],
    ],
  ];
}
