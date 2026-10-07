// Converted from a source-string match to a real widget/semantics test.
// The previous version only checked that certain literal substrings existed
// in home_screen.dart's source text; it would pass even if the semantics
// were wired to the wrong widget, or fail on a harmless reformat. This
// version renders the real widget tree and reads the semantics it produces.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';

void main() {
  testWidgets(
    'active profile dropdown exposes a labelled, actionable semantics node',
    (tester) async {
      final profiles = MemoryProfileStore();
      const p1 = RifleProfile(
        id: 'p1',
        name: 'Bir',
        rifleId: 'hatsan-hercules-635',
        ammunitionId: 'gmaz-51',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 270,
        zeroRangeM: 25,
        sightHeightMm: 60,
        pressureBar: 200,
      );
      await profiles.save(p1);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            profileStore: profiles,
            activeProfileStore: MemoryActiveProfileStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.bySemanticsLabel('Aktif tüfek profili'),
      );
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    },
  );

  testWidgets(
    'home loading state announces progress via a live semantics region',
    (tester) async {
      // A store whose Future never resolves keeps HomeScreen in its loading state
      // for the duration of the pump, so the loading semantics can be inspected.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(profileStore: _NeverResolvingProfileStore()),
        ),
      );
      await tester.pump();

      final loadingNode = tester.getSemantics(
        find.bySemanticsLabel('Profiller yükleniyor'),
      );
      expect(loadingNode.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    },
  );
}

class _NeverResolvingProfileStore implements ProfileStore {
  const _NeverResolvingProfileStore();
  @override
  Future<List<RifleProfile>> all() => Completer<List<RifleProfile>>().future;
  @override
  Future<void> save(RifleProfile profile) async {}
  @override
  Future<void> remove(String id) async {}
}
