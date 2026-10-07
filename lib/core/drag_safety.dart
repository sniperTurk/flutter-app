import '../models/domain.dart';
import 'atmosphere.dart';

/// How seriously a drag-model warning should be taken.
enum DragWarningLevel {
  /// Worth knowing; the result is still usable.
  info,

  /// The result may be materially wrong. Confirm with live fire.
  caution,
}

enum DragWarningKind {
  /// Muzzle speed is at or above Mach 0.8: drag rises steeply and pellets
  /// can destabilise, so a G1/G7 curve is not trustworthy (O13).
  transonicMuzzle,

  /// Muzzle speed is at or above Mach 1.0 (O13).
  supersonicMuzzle,

  /// The ballistic coefficient is outside what airgun projectiles use (O14).
  bcOutOfRange,

  /// An airgun projectile paired with a G7 coefficient (O14): published
  /// airgun coefficients are almost always G1.
  airgunWithG7,
}

class DragWarning {
  final DragWarningKind kind;
  final DragWarningLevel level;
  final String message;
  const DragWarning(this.kind, this.level, this.message);
}

/// Pure checks that must run before a drag-model result is shown.
///
/// They never block a calculation; they tell the shooter when the result
/// stands on assumptions the app cannot verify. Each rule has a stated limit
/// so it can be tested and changed in one place.
abstract final class DragSafety {
  /// Mach number from which a G1/G7 curve is no longer trusted for pellets.
  static const double transonicMach = 0.8;

  /// Mach number of sound.
  static const double supersonicMach = 1.0;

  /// Plausible G1 coefficient range for airgun projectiles (pellets and
  /// slugs). Values outside it usually mean a rifle-bullet coefficient or a
  /// typing error.
  static const double airgunBcMin = 0.005;
  static const double airgunBcMax = 0.25;

  static List<DragWarning> assess({
    required double muzzleVelocityMps,
    required EnvironmentData environment,
    required double? ballisticCoefficient,
    required BallisticModel? ballisticModel,
    required WeaponPlatform platform,
  }) {
    final warnings = <DragWarning>[];
    final mach = Atmosphere.machNumber(
      velocityMps: muzzleVelocityMps,
      environment: environment,
    );
    if (mach >= supersonicMach) {
      warnings.add(
        DragWarning(
          DragWarningKind.supersonicMuzzle,
          DragWarningLevel.caution,
          'Namlu hızı ses hızının üstünde (Mach ${_d(mach)}). Havalı silah '
          'mermisi bu hızda kararsızlaşır; hesap güvenilir değil.',
        ),
      );
    } else if (mach >= transonicMach) {
      warnings.add(
        DragWarning(
          DragWarningKind.transonicMuzzle,
          DragWarningLevel.caution,
          'Namlu hızı Mach ${_d(mach)} (Mach 0,8 ve üstü). Bu bölgede sürtünme '
          'hızla değişir ve G1/G7 eğrisi mermiyi doğru tarif etmez; hesap '
          'güvenilir değil. Gerçek atışla doğrulayın.',
        ),
      );
    }

    final bc = ballisticCoefficient;
    final model = ballisticModel;
    if (bc != null && model != null && platform == WeaponPlatform.pcp) {
      if (bc < airgunBcMin || bc > airgunBcMax) {
        warnings.add(
          DragWarning(
            DragWarningKind.bcOutOfRange,
            DragWarningLevel.caution,
            'BC ${_d(bc, 3)} havalı silah mermileri için alışılmadık '
            '(genelde ${_d(airgunBcMin, 3)}–${_d(airgunBcMax, 2)}). Değeri ve '
            'sürtünme yasasını (G1/G7) kontrol edin.',
          ),
        );
      }
      if (model == BallisticModel.g7) {
        warnings.add(
          const DragWarning(
            DragWarningKind.airgunWithG7,
            DragWarningLevel.info,
            'Havalı silah mermileri için yayımlanan BC değerleri çoğunlukla G1 '
            'yasasına göredir. Bu BC gerçekten G7 ise kullanın; G1 değerini '
            'G7 olarak girmek sonucu bozar.',
          ),
        );
      }
    }
    return warnings;
  }

  static String _d(double v, [int digits = 2]) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');
}
