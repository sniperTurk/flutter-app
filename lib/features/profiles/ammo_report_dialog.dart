import 'package:flutter/material.dart';

import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'ammo_report.dart';

/// "Aradığın mühimmat listede yok mu?" (owner, 2026-10-17 21:33–21:51
/// Istanbul): one box for marka, model, ağırlık; Gönder sends it to our
/// catalog inbox through [send]. Pops `true` once sent; a failure keeps the
/// text for another try. It never changes the profile.
class AmmoReportDialog extends StatefulWidget {
  /// Sends the typed text exactly as written; throws on failure.
  final Future<void> Function(String text) send;
  const AmmoReportDialog({super.key, required this.send});

  static const title = 'Aradığın mühimmat listede yok mu?';
  static const body =
      'Şu an Marka kutusundaki "Diğer marka" seçeneğiyle devam edebilirsin. '
      'Listede olmayan mühimmatı bize yaz: marka, model, ağırlık. Üreticinin '
      'bilgileriyle listeye en kısa zamanda eklemeye çalışacağız.';

  /// ⓘ of the box (CLAUDE.md: every typed value has one).
  static const textInfo =
      'Listede bulamadığın mühimmatın markası, modeli ve ağırlığı, kutunun '
      'üstünde yazdığı gibi. Ağırlığı gr veya g ile yaz. Örnek: H&N Slug HP '
      '50 gr.';
  static const failure =
      'Şu an gönderilemedi. İnternet bağlantını kontrol edip tekrar dene.';

  @override
  State<AmmoReportDialog> createState() => _AmmoReportDialogState();
}

class _AmmoReportDialogState extends State<AmmoReportDialog> {
  final TextEditingController _text = TextEditingController();
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _text.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await widget.send(_text.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failed = true;
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('ammo-report-dialog'),
    title: const Text(AmmoReportDialog.title, textAlign: TextAlign.left),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          AmmoReportDialog.body,
          key: Key('ammo-report-body'),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: MenzilSpace.md),
        MenzilInput(
          key: const Key('ammo-report-text'),
          controller: _text,
          label: 'Marka, model, ağırlık',
          hintText: 'örn. H&N Slug HP 50 gr',
          info: AmmoReportDialog.textInfo,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          maxLength: ammoReportMaxLength,
          enabled: !_sending,
          onChanged: (_) => setState(() => _failed = false),
        ),
        if (_failed)
          const MenzilNotice(
            key: Key('ammo-report-failure'),
            tone: MenzilNoticeTone.danger,
            message: AmmoReportDialog.failure,
          ),
      ],
    ),
    actions: [
      TextButton(
        key: const Key('ammo-report-cancel'),
        onPressed: _sending ? null : () => Navigator.pop(context, false),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        key: const Key('ammo-report-send'),
        onPressed: _canSend ? _send : null,
        child: const Text('Gönder'),
      ),
    ],
  );
}
