import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/profile_store.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';

/// User-initiated recovery for unreadable profile storage. Offers exactly two
/// actions and writes nothing until the user explicitly confirms the second:
///  1. "Ham veriyi göster / kopyala": read-only, shows the stored text.
///  2. "Boş başla": preserves both unreadable records under separate keys
///     (verified) and only then opens an empty profile list.
/// Returns true when storage was reset to an empty list.
Future<bool> showProfileRecoveryDialog(
  BuildContext context,
  ProfileRecovery recovery,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _RecoveryDialog(recovery: recovery),
  );
  return result ?? false;
}

class _RecoveryDialog extends StatefulWidget {
  final ProfileRecovery recovery;
  const _RecoveryDialog({required this.recovery});

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  CorruptProfileData? _data;
  String? _message;
  bool _busy = false;
  bool _confirmingEmpty = false;

  Future<void> _showRaw() async {
    try {
      final data = await widget.recovery.readCorruptData();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _message = 'Kayıt okunamadı.');
    }
  }

  String get _rawText {
    final d = _data!;
    return 'ANA KAYIT:\n${d.primary ?? '(yok)'}\n\n'
        'YEDEK KAYIT:\n${d.backup ?? '(yok)'}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _rawText));
    if (mounted) setState(() => _message = 'Ham veri panoya kopyalandı.');
  }

  Future<void> _startEmpty() async {
    setState(() => _busy = true);
    try {
      await widget.recovery.startEmptyKeepingCorruptCopy();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirmingEmpty = false;
          _message =
              'Bozuk kayıtlar güvenle saklanamadı. Hiçbir şey değiştirilmedi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return AlertDialog(
      title: const Text('Kayıtları kurtar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil kayıtları okunamıyor. Hiçbir kayıt otomatik silinmez veya değiştirilmez.',
              style: MenzilType.body(c.ink),
            ),
            if (_data != null) ...[
              const SizedBox(height: MenzilSpace.md),
              Container(
                key: const Key('recovery-raw'),
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(MenzilSpace.sm),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(MenzilRadius.button),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _rawText,
                    style: MenzilType.caption(c.ink),
                  ),
                ),
              ),
            ],
            if (_confirmingEmpty) ...[
              const SizedBox(height: MenzilSpace.md),
              MenzilNotice(
                tone: MenzilNoticeTone.warning,
                message:
                    '${_data?.totalLength ?? 0} karakterlik bozuk kayıt ayrı bir yerde saklanacak, '
                    'yeni boş bir profil listesi açılacak. Mevcut profilleriniz bu listede görünmeyecek.',
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: MenzilSpace.md),
              Text(_message!, style: MenzilType.caption(c.ink2)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Kapat'),
        ),
        if (_data == null)
          TextButton(
            key: const Key('recovery-show-raw'),
            onPressed: _busy ? null : _showRaw,
            child: const Text('Ham veriyi göster'),
          )
        else
          TextButton(
            key: const Key('recovery-copy'),
            onPressed: _busy ? null : _copy,
            child: const Text('Ham veriyi kopyala'),
          ),
        if (!_confirmingEmpty)
          FilledButton(
            key: const Key('recovery-start-empty'),
            onPressed: _busy
                ? null
                : () async {
                    if (_data == null) await _showRaw();
                    if (mounted) setState(() => _confirmingEmpty = true);
                  },
            child: const Text('Boş başla'),
          )
        else
          FilledButton(
            key: const Key('recovery-confirm-empty'),
            onPressed: _busy ? null : _startEmpty,
            child: const Text('Saklayıp boş başla'),
          ),
      ],
    );
  }
}
