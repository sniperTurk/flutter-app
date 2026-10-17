part of 'ballistics_screen.dart';

/// Hava Durumu ve Pro Ayarlar'ın ortak satırları: Sıfırla düğmesi, tarih |
/// Sıfırla satırı, kutu | düğme satırı, ⓘ'li kart başlığı.
///
/// Modül ayrımı (owner, 2026-10-15): ballistics_screen.dart'tan aynen
/// taşındı; durum ve hesap ballistics_screen.dart'ta kalır.
extension _BallisticsSharedRows on _BallisticsScreenState {
  // ---- Shared rows (owner, 2026-10-14) ------------------------------------

  /// "Sıfırla", the same size as the other buttons; after a reset it shows
  /// the done state "Veriler sıfırlandı" (owner, 2026-10-12). No icon
  /// (owner, 2026-10-15: buttons carry no icons).
  Widget _resetButton({
    required bool wasReset,
    required Key resetKey,
    required VoidCallback onReset,
  }) => MenzilSecondaryButton(
    key: resetKey,
    label: wasReset ? 'Veriler sıfırlandı' : 'Sıfırla',
    expand: true,
    active: wasReset,
    twoLines: true,
    maxLabelLines: 2,
    onPressed: onReset,
  );

  /// Always visible from the first frame (no layout jump): the date on the
  /// left (one line, never wraps; shrinks when it must), Sıfırla on the
  /// right.
  Widget _dateResetRow({
    required Key dateKey,
    required String date,
    required bool wasReset,
    required Key resetKey,
    required VoidCallback onReset,
  }) {
    final c = MenzilColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MenzilSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: _oneLineText(date, key: dateKey, color: c.ink2),
          ),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: _resetButton(
              wasReset: wasReset,
              resetKey: resetKey,
              onReset: onReset,
            ),
          ),
        ],
      ),
    );
  }

  /// Left-aligned text on one line that scales down instead of wrapping.
  static Widget _oneLineText(String text, {Key? key, required Color color}) =>
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            key: key,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.start,
            style: MenzilType.caption(color),
          ),
        ),
      );

  /// A box on the left, its fetch button on the right, bottoms aligned.
  /// Always two items, at any width or text size (owner, 2026-10-14).
  Widget _boxButtonRow({required Widget box, required Widget button}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: box),
        const SizedBox(width: MenzilSpace.md),
        Expanded(
          child: Padding(
            // The compact box keeps md below it; the button lines up.
            padding: const EdgeInsets.only(bottom: MenzilSpace.md),
            child: button,
          ),
        ),
      ],
    );
  }

  /// A card title (size 18, like the Profil summary headers) with ONE ⓘ
  /// right after it (owner, 2026-10-14: Basınç Ölçer and İrtifa only).
  ///
  /// With [gapAbove] (Hava Durumu, owner 2026-10-17): the title text sits
  /// exactly [gapAbove] under the previous item and 8 pt over its card.
  Widget _headerWithInfo(
    String title,
    String info, {
    required Key infoKey,
    double? gapAbove,
  }) => gapAbove == null
      ? MenzilSectionHeader(
          title,
          size: 18,
          padding: const EdgeInsets.only(
            top: MenzilSpace.xxs,
            bottom: MenzilSpace.sm,
          ),
          titleTrailing: MenzilInfoButton(
            key: infoKey,
            title: title,
            text: info,
          ),
        )
      : MenzilSectionHeader(
          title,
          size: 18,
          textGapAbove: gapAbove,
          titleInfo: (alignment, padding) => MenzilInfoButton(
            key: infoKey,
            title: title,
            text: info,
            alignment: alignment,
            padding: padding,
          ),
        );

  String _pressureText(double hpa) => metric
      ? hpa.toStringAsFixed(1)
      : UnitSystem.hpaToInHg(hpa).toStringAsFixed(2);

  /// A fetch button with "Sıfırla" always beside it (owner, 2026-10-12):
  /// the fetch button turns orange once its data came, "Sıfırla" turns
  /// orange ("Veriler sıfırlandı") after a reset.
  Widget _filledRow({
    required bool filled,
    required bool wasReset,
    required Widget button,
    required Key resetKey,
    required VoidCallback onReset,
  }) {
    return Row(
      children: [
        Expanded(child: button),
        // Same gap as the boxes above, so the buttons line up with them
        // (owner, 2026-10-12: "turuncu kutular üstteki kutulardan büyük").
        const SizedBox(width: MenzilSpace.md),
        Expanded(
          child: _resetButton(
            wasReset: wasReset,
            resetKey: resetKey,
            onReset: onReset,
          ),
        ),
      ],
    );
  }
}
