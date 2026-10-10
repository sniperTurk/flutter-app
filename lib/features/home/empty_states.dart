import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// Pages shown before the first profile exists (owner, 2026-10-10): instead
/// of empty locked cards, each page says what it does and offers the next
/// step — create a profile, or try the ready sample profiles.
abstract final class EmptyStateKeys {
  static const welcome = Key('empty-welcome');
  static const create = Key('empty-create-profile');
  static const sample = Key('empty-try-sample');
  static const shotPreview = Key('empty-shot-preview');
  static const proPreview = Key('empty-pro-preview');
}

/// The two actions every empty page offers.
class _EmptyActions extends StatelessWidget {
  final VoidCallback? onCreate;
  final VoidCallback? onSample;
  final String createLabel;

  const _EmptyActions({
    required this.onCreate,
    required this.onSample,
    this.createLabel = 'Profil oluştur',
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MenzilPrimaryButton(
        key: EmptyStateKeys.create,
        label: createLabel,
        icon: Icons.add,
        amber: true,
        onPressed: onCreate,
      ),
      const SizedBox(height: MenzilSpace.sm),
      MenzilSecondaryButton(
        key: EmptyStateKeys.sample,
        label: 'Örnek profille dene',
        icon: Icons.play_arrow_rounded,
        expand: true,
        onPressed: onSample,
      ),
    ],
  );
}

/// Profil page without profiles: logo, what the app does, how it works.
class WelcomePanel extends StatelessWidget {
  final VoidCallback? onCreate;
  final VoidCallback? onSample;

  const WelcomePanel({super.key, this.onCreate, this.onSample});

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget step(String n, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MenzilSpace.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.amberSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: TextStyle(fontWeight: FontWeight.w800, color: c.amberInk),
            ),
          ),
          const SizedBox(width: MenzilSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MenzilType.heading(c.ink, size: 16)),
                const SizedBox(height: 2),
                Text(text, style: MenzilType.caption(c.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      key: EmptyStateKeys.welcome,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MenzilCard(
          child: Column(
            children: [
              Image.asset(
                dark
                    ? 'assets/branding/logo_line_dark.png'
                    : 'assets/branding/logo_line.png',
                width: 104,
                height: 104,
                semanticLabel: 'SNIPER TÜRK',
              ),
              const SizedBox(height: MenzilSpace.md),
              Text(
                'Mesafeyi gir,\ndürbünün kurulu gelsin.',
                textAlign: TextAlign.center,
                style: MenzilType.heading(c.ink, size: 22),
              ),
              const SizedBox(height: MenzilSpace.xs),
              Text(
                'PCP ve Ateşli Tüfekler için Pro balistik hesaplama',
                textAlign: TextAlign.center,
                style: MenzilType.body(c.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MenzilSpace.xs),
          child: Text('Nasıl çalışır?', style: MenzilType.heading(c.ink, size: 17)),
        ),
        const SizedBox(height: MenzilSpace.sm),
        MenzilCard(
          child: Column(
            children: [
              step(
                '1',
                'Tüfeğini tanıt',
                'Tüfek, mermi ve dürbün bilgilerini bir kez gir.',
              ),
              step(
                '2',
                'Havayı al',
                'Konumundan sıcaklık, basınç ve rüzgâr otomatik gelir.',
              ),
              step(
                '3',
                'Dürbünü kur',
                'Mesafeyi yaz; kaç klik çevireceğini gösterir.',
              ),
            ],
          ),
        ),
        const SizedBox(height: MenzilSpace.md),
        _EmptyActions(
          onCreate: onCreate,
          onSample: onSample,
          createLabel: 'İlk profilimi oluştur',
        ),
        const SizedBox(height: MenzilSpace.xs),
        Text(
          'Hazır bir PCP ve .308 profili açılır; istediğin zaman silebilirsin.',
          textAlign: TextAlign.center,
          style: MenzilType.caption(c.ink2),
        ),
      ],
    );
  }
}

/// Hedef and Pro without a profile: a faded preview of the page behind a
/// short explanation and the two actions.
class LockedPreview extends StatelessWidget {
  final bool shot;
  final VoidCallback? onCreate;
  final VoidCallback? onSample;

  const LockedPreview({
    super.key,
    required this.shot,
    this.onCreate,
    this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final title = shot ? 'Tahmin yok, hesap var.' : 'Hassas atış ayarları';
    final text = shot
        ? 'Hava koşulları ve Pro hesaplamalarla, kaç klik çevireceğin her '
              'mesafe için hassas biçimde hesaplanır. Sonuç doğrudan '
              'retikülünün üzerinde görünür.'
        : 'Açı, rüzgâr bölgeleri, Coriolis, hareketli hedef ve tüfek '
              'düzeltmeleri. Profil oluşturunca açılır.';
    final preview = shot
        ? AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _ReticleSketch(c.ink, c.danger)),
          )
        : Column(
            children: [
              for (final (a, b) in const [
                ('Atış mesafesi', '600 m'),
                ('Açı', 'düz'),
                ('Rüzgâr', 'en çok 4.5 m/s'),
                ('Coriolis', 'kapalı'),
                ('Hareketli hedef', 'kapalı'),
                ('Tüfek düzeltmeleri', 'kapalı'),
              ])
                MenzilCard(
                  margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(a, style: MenzilType.heading(c.ink, size: 18)),
                      ),
                      Text(b, style: MenzilType.caption(c.ink2)),
                    ],
                  ),
                ),
            ],
          );
    return Semantics(
      container: true,
      child: Stack(
        key: shot ? EmptyStateKeys.shotPreview : EmptyStateKeys.proPreview,
        children: [
          ExcludeSemantics(
            child: Opacity(opacity: shot ? 0.25 : 0.35, child: preview),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: shot ? MenzilSpace.xl * 2 : MenzilSpace.xl * 4,
            ),
            child: MenzilCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: MenzilType.heading(c.ink, size: shot ? 22 : 19),
                  ),
                  const SizedBox(height: MenzilSpace.xs),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: MenzilType.body(c.ink2),
                  ),
                  const SizedBox(height: MenzilSpace.md),
                  _EmptyActions(onCreate: onCreate, onSample: onSample),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain reticle drawing for the Hedef preview.
class _ReticleSketch extends CustomPainter {
  final Color ink, red;
  _ReticleSketch(this.ink, this.red);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.46;
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r, line);
    canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), line);
    canvas.drawLine(c - Offset(0, r), c + Offset(0, r), line);
    final dot = Paint()..color = ink;
    for (var i = 1; i <= 6; i++) {
      final y = c.dy + i * r / 7;
      canvas.drawCircle(Offset(c.dx, y), 3, dot);
      final tp = TextPainter(
        text: TextSpan(
          text: '${300 + i * 60}',
          style: TextStyle(color: red, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx + 10, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ReticleSketch old) =>
      old.ink != ink || old.red != red;
}
