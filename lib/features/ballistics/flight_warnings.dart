import 'package:flutter/material.dart';

import '../../core/stability.dart';
import '../../ui/menzil_widgets.dart';

/// Kararlılık ve transonik uyarıları (Ö5, owner, 2026-10-11) as
/// [MenzilNotice]s for the shot panel. Explanations live in the ⓘ.
abstract final class FlightWarnings {
  static const unstableInfo =
      'Sg, merminin dönerek ne kadar kararlı uçtuğunu gösterir. Namlu '
      'ağzında Miller formülüyle hesaplanır: mermi ağırlığı, çapı, uzunluğu, '
      'yiv oranı, hız, sıcaklık ve basınç. 1.0 altında mermi yalpalar ve '
      'takla atabilir; isabet beklenmez. Çözüm: daha hızlı yivli namlu veya '
      'daha kısa mermi.';

  static const marginalInfo =
      'Sg 1.5 altında mermi biraz yalpalı uçar ve sürüklenmesi artar. Litz '
      'ölçümlerine göre 1.5 altındaki her 0.1 düşüş BC değerini yaklaşık %3 '
      'azaltır. Uygulama BC değerini kendiliğinden düşürmez; uzak mesafede '
      'mermi beklenenden alçak düşerse Hız Doğrulama ile düzelt. 1.5 ve üstü '
      'tam kararlıdır.';

  static const transonicInfo =
      'Mermi hedefe Mach 1.2 altında varıyor, yani ses hızına yaklaşıyor. Bu '
      'bölgede sürüklenme hızla değişir, mermi sarsılabilir ve hesap daha '
      'belirsizdir. Mach o günkü sıcaklık ve basınçla hesaplanır. Daha kısa '
      'mesafe veya daha yüksek BC değerli mermi riski azaltır.';

  /// Notices for muzzle stability [sg] (null when bullet length, twist or
  /// calibre is missing) and the transonic check ([muzzleMach] and
  /// [targetMach], null when unknown). Empty when nothing to warn about.
  static List<Widget> notices({
    double? sg,
    double? muzzleMach,
    double? targetMach,
  }) {
    final out = <Widget>[];
    if (sg != null && sg.isFinite && sg > 0) {
      switch (Stability.classify(sg)) {
        case StabilityLevel.unstable:
          out.add(
            MenzilNotice(
              key: const Key('shot-stability-unstable'),
              tone: MenzilNoticeTone.danger,
              message:
                  'Mermi kararsız: Sg ${sg.toStringAsFixed(2)}. Yiv bu mermi '
                  'için yavaş; mermi takla atabilir.',
              infoTitle: 'Kararlılık',
              info: unstableInfo,
            ),
          );
        case StabilityLevel.marginal:
          final loss = Stability.bcLossPercent(sg).round().clamp(1, 15);
          out.add(
            MenzilNotice(
              key: const Key('shot-stability-marginal'),
              tone: MenzilNoticeTone.warning,
              message:
                  'Kararlılık sınırda: Sg ${sg.toStringAsFixed(2)}. BC katalog '
                  'değerinin altında kalabilir, yaklaşık %$loss.',
              infoTitle: 'Kararlılık',
              info: marginalInfo,
            ),
          );
        case StabilityLevel.stable:
          break;
      }
    }
    if (muzzleMach != null &&
        targetMach != null &&
        Stability.transonicAtTarget(
          muzzleMach: muzzleMach,
          targetMach: targetMach,
        )) {
      out.add(
        MenzilNotice(
          key: const Key('shot-transonic'),
          tone: MenzilNoticeTone.warning,
          message:
              'Hedefte ses hızına yakın: Mach ${targetMach.toStringAsFixed(2)}. '
              'Dağılım ve sapma artabilir.',
          infoTitle: 'Transonik bölge',
          info: transonicInfo,
        ),
      );
    }
    return out;
  }
}
