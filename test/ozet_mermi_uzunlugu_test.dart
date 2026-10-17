// Profil summary, Mühimmat card, firearm only (owner, 2026-10-17 18:13–
// 18:26): "Mermi 31.2 mm yazalım." — the bullet length next to the type
// in the Tip box ("Tip / uzunluk", joined by a space like "BC / model"
// "0,243 G7"); "Fabrika fişeği ve el dolumu ise aşağı yaz." — a last
// "Mühimmat türü" box; "PCP'yi boşver şimdi." — PCP card unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/home/home_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/active_profile_store.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mu',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Tikka',
  'model': 'T3x TAC A1',
  'caliberMm': 7.82,
  'barrelLengthMm': 610,
  'twistDirection': 'right',
  'twistRateIn': 11,
};

/// A listed factory round (Barnes, factory_ammo_library.dart).
Map<String, dynamic> _factory({double? length}) => {
  'id': 'manual_ammo_mu',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Barnes',
  'model': 'Harvest Collection 165 gr Sierra TGK',
  'caliberMm': 7.82,
  'grain': 165,
  'ammoType': 'bullet',
  'bc': 0.517,
  'bcModel': 'g1',
  if (length != null) 'lengthMm': length,
};

/// A listed bullet (Hornady, bullet_library.dart): El dolumu.
const _handload = <String, dynamic>{
  'id': 'manual_ammo_mu',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Hornady',
  'model': '30 Cal .308 168 gr ELD Match',
  'caliberMm': 7.82,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.263,
  'bcModel': 'g7',
  'lengthMm': 31.2,
};

const _scope = <String, dynamic>{
  'id': 'manual_scope_mu',
  'kind': 'scope',
  'platform': 'firearm',
  'brand': 'GaziSniper',
  'model': '6-36x56 FFP',
  'objectiveMm': 56,
  'click': 0.1,
  'clickUnit': 'mrad',
  'focal': 'ffp',
  'minMag': 6,
  'maxMag': 36,
  'elevationRangeMrad': 26,
};

// PCP (same records as profile_summary_order_test.dart, plus a length).
const _pcpRifle = <String, dynamic>{
  'id': 'manual_rifle_mu',
  'kind': 'rifle',
  'platform': 'pcp',
  'brand': 'Hatsan',
  'model': 'Hercules',
  'caliberMm': 6.35,
  'barrelLengthMm': 800,
  'twistDirection': 'right',
  'twistRateIn': 6,
};
const _pcpAmmo = <String, dynamic>{
  'id': 'manual_ammo_mu',
  'kind': 'ammo',
  'platform': 'pcp',
  'brand': 'Engin Sak',
  'model': '',
  'caliberMm': 6.35,
  'grain': 50,
  'ammoType': 'pellet',
  'bc': 0.165,
  'bcModel': 'g1',
  'lengthMm': 10.5,
};
final _pcpScope = <String, dynamic>{..._scope, 'platform': 'pcp'};

const _profile = RifleProfile(
  id: 'p-mu',
  name: 'Tikka',
  rifleId: 'manual_rifle_mu',
  ammunitionId: 'manual_ammo_mu',
  scopeId: 'manual_scope_mu',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 50,
);

const _cardKey = Key('profile-summary-ammo');

Future<void> _pump(
  WidgetTester tester,
  List<Map<String, dynamic>> entries, {
  double width = 390,
  double scale = 1,
}) async {
  CatalogRepository.installUserCatalog(UserCatalog.fromManualEntries(entries));
  addTearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));
  tester.view.physicalSize = Size(width, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await store.save(_profile);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: HomeScreen(
        profileStore: store,
        activeProfileStore: MemoryActiveProfileStore()..value = 'p-mu',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inCard(String text) =>
    find.descendant(of: find.byKey(_cardKey), matching: find.text(text));

Offset _at(WidgetTester tester, String text) =>
    tester.getTopLeft(_inCard(text));

/// Every text of the card, top to bottom, left to right.
List<String> _cardTexts(WidgetTester tester) {
  final all = find.descendant(
    of: find.byKey(_cardKey),
    matching: find.byType(Text),
  );
  final texts = [
    for (final e in all.evaluate())
      (e.widget as Text, tester.getTopLeft(find.byWidget(e.widget))),
  ];
  texts.sort((a, b) {
    final dy = a.$2.dy - b.$2.dy;
    return dy.abs() > 4 ? dy.sign.toInt() : a.$2.dx.compareTo(b.$2.dx);
  });
  return [for (final (t, _) in texts) t.data ?? t.textSpan!.toPlainText()];
}

/// The Tip box of the metric rows: first row, left column, under the lead.
void _expectTipPosition(WidgetTester tester, String label) {
  final tip = _at(tester, label);
  final weight = _at(tester, 'Ağırlık');
  final lead = _at(tester, 'Mühimmat Marka/Model');
  expect(tip.dy, moreOrLessEquals(weight.dy, epsilon: 0.5));
  expect(tip.dx, lessThan(weight.dx));
  expect(tip.dx, moreOrLessEquals(lead.dx, epsilon: 0.5));
  expect(tip.dy, greaterThan(lead.dy));
}

void main() {
  testWidgets('factory round with 31,2 mm: Tip / uzunluk "Mermi 31,2 mm" '
      'and Mühimmat türü "Fabrika fişeği" last', (tester) async {
    await _pump(tester, [_rifle, _factory(length: 31.2), _scope]);
    expect(tester.takeException(), isNull);

    expect(_inCard('Tip / uzunluk'), findsOneWidget);
    expect(_inCard('Mermi 31,2 mm'), findsOneWidget);
    expect(_inCard('Tip'), findsNothing);
    expect(_inCard('Mermi'), findsNothing);
    expect(_inCard('Mermi uzunluğu'), findsNothing);
    _expectTipPosition(tester, 'Tip / uzunluk');

    // Mühimmat türü below the others: after BC / model, nothing after it.
    final bc = _at(tester, 'BC / model');
    final source = _at(tester, 'Mühimmat türü');
    expect(source.dy, moreOrLessEquals(bc.dy, epsilon: 0.5));
    expect(source.dx, greaterThan(bc.dx));
    expect(source.dy, greaterThan(_at(tester, 'Ağırlık').dy));
    expect(_cardTexts(tester), [
      'Mühimmat Marka/Model',
      'Barnes Harvest Collection Sierra TGK',
      'Tip / uzunluk',
      'Ağırlık',
      'Mermi 31,2 mm',
      '165 gr',
      'BC / model',
      'Mühimmat türü',
      '0,517 G1',
      'Fabrika fişeği',
    ]);
  });

  testWidgets('a listed bullet: Mühimmat türü "El dolumu"', (tester) async {
    await _pump(tester, [_rifle, _handload, _scope]);
    expect(_inCard('Tip / uzunluk'), findsOneWidget);
    expect(_inCard('Mermi 31,2 mm'), findsOneWidget);
    expect(_inCard('Mühimmat türü'), findsOneWidget);
    expect(_inCard('El dolumu'), findsOneWidget);
    expect(_inCard('Fabrika fişeği'), findsNothing);
  });

  testWidgets('no saved length: "Tip" / "Mermi" as on main', (tester) async {
    await _pump(tester, [_rifle, _factory(), _scope]);
    expect(_inCard('Tip'), findsOneWidget);
    expect(_inCard('Mermi'), findsOneWidget);
    expect(_inCard('Tip / uzunluk'), findsNothing);
    _expectTipPosition(tester, 'Tip');
    expect(_inCard('Fabrika fişeği'), findsOneWidget);
  });

  testWidgets('PCP: the card is the same as on main', (tester) async {
    await _pump(tester, [_pcpRifle, _pcpAmmo, _pcpScope]);
    expect(_cardTexts(tester), [
      'Mühimmat Marka/Model',
      'Engin Sak',
      'Tip',
      'Ağırlık',
      'Pellet',
      '50 gr',
      'BC / model',
      '0,165 G1',
    ]);
  });

  for (final (width, scale) in const [(320.0, 1.3), (390.0, 1.0)]) {
    testWidgets('$width pt, ×$scale: no overflow', (tester) async {
      await _pump(
        tester,
        [_rifle, _factory(length: 31.2), _scope],
        width: width,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byKey(_cardKey));
      for (final t in ['Mermi 31,2 mm', 'Fabrika fişeği', 'Tip / uzunluk']) {
        final r = tester.getRect(_inCard(t));
        expect(r.left, greaterThanOrEqualTo(card.left), reason: t);
        expect(r.right, lessThanOrEqualTo(card.right + 0.01), reason: t);
      }
    });
  }
}
