import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/profile_catalog_integrity.dart';
import '../../models/domain.dart';
import '../../services/active_profile_store.dart';
import '../../services/profile_store.dart';
import '../../tools/domain/preshot_checklist.dart';
import '../../ui/menzil_theme.dart';
import '../../ui/menzil_widgets.dart';
import 'tool_support.dart';

/// Ö11 Atış öncesi kontrol listesi. Starts empty every time it opens: a
/// tick from an earlier shot must not vouch for this one. Nothing is
/// stored; the Su Terazisi screen is not touched, the list only reminds.
class PreShotChecklistScreen extends StatefulWidget {
  final ProfileStore? profileStore;
  final ActiveProfileStore? activeProfileStore;
  const PreShotChecklistScreen({
    super.key,
    this.profileStore,
    this.activeProfileStore,
  });

  @override
  State<PreShotChecklistScreen> createState() => _PreShotChecklistScreenState();
}

class _PreShotChecklistScreenState extends State<PreShotChecklistScreen> {
  bool _loading = true;
  RifleProfile? _profile;
  ScopeOptic? _scope;
  final Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final p = await loadActiveToolProfile(
      widget.profileStore ?? PersistentProfileStore(),
      widget.activeProfileStore ?? PersistentActiveProfileStore(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = p;
      _scope = p == null
          ? null
          : const ProfileCatalogIntegrity().resolve(p)?.scope;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    final items = PreShotChecklist.items(
      profileName: _profile?.name,
      unit: _profile?.angularUnit,
      firstFocalPlane: _scope?.firstFocalPlane,
    );
    final done = items.where((i) => _done.contains(i.id)).length;
    return Scaffold(
      appBar: const MenzilSubPageBar(title: 'Atış Öncesi Kontrol'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : MenzilPage(
              children: [
                for (final item in items)
                  _CheckRow(
                    key: Key('check-${item.id}'),
                    item: item,
                    checked: _done.contains(item.id),
                    onChanged: (v) => setState(
                      () => v ? _done.add(item.id) : _done.remove(item.id),
                    ),
                  ),
                const SizedBox(height: MenzilSpace.sm),
                Text(
                  '$done / ${items.length} tamam',
                  key: const Key('check-count'),
                  style: MenzilType.body(c.ink2),
                ),
                if (done == items.length) ...[
                  const SizedBox(height: MenzilSpace.sm),
                  const MenzilNotice(
                    key: Key('check-ready'),
                    tone: MenzilNoticeTone.info,
                    message: 'Hazır. Kaba hata kontrolü tamam.',
                  ),
                ],
                const SizedBox(height: MenzilSpace.md),
                MenzilSecondaryButton(
                  key: const Key('check-clear'),
                  label: 'Temizle',
                  expand: true,
                  onPressed: _done.isEmpty
                      ? null
                      : () => setState(_done.clear),
                ),
              ],
            ),
    );
  }
}

/// One tick box with its text and ⓘ; the whole row toggles.
class _CheckRow extends StatelessWidget {
  final ChecklistItem item;
  final bool checked;
  final ValueChanged<bool> onChanged;
  const _CheckRow({
    super.key,
    required this.item,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = MenzilColors.of(context);
    return MenzilCard(
        margin: const EdgeInsets.only(bottom: MenzilSpace.sm),
        padding: EdgeInsets.zero,
        child: Semantics(
          checked: checked,
          child: InkWell(
            onTap: () => onChanged(!checked),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                  Expanded(
                    child: Text(item.title, style: MenzilType.body(c.ink)),
                  ),
                  MenzilInfoButton(title: item.title, text: item.info),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
