// Mühimmat sıcaklığı kendi bölümünde (owner, 2026-10-16): "Hava" kartından
// çıkarıldı, Hava kartının hemen altında kendi başlığı (ⓘ + "isteğe bağlı")
// ve kendi kartıyla. Anahtar, kayıt ve barut düzeltmesi değişmedi.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_mb',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_mb',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

const _firearm = RifleProfile(
  id: 'p-mb',
  name: 'MB',
  rifleId: 'manual_rifle_mb',
  ammunitionId: 'manual_ammo_mb',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 15,
);

const _pcp = RifleProfile(
  id: 'p-mb-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _ammoKey = Key('env-ammo-temp');
const _header = Key('environment-ammo-temp-header');
const _card = Key('environment-ammo-temp-card');

Widget _app(
  RifleProfile p,
  BallisticsView view, {
  double scale = 1,
  bool dark = false,
}) => MaterialApp(
  theme: dark ? MenzilTheme.dark() : MenzilTheme.light(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

Future<void> _size(WidgetTester tester, double width, [double h = 3000]) async {
  tester.view.physicalSize = Size(width, h) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder _textField(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(
      UserCatalog.fromManualEntries([_rifle, _ammo]),
    );
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  testWidgets('firearm: not in the Hava card; own section under it', (
    tester,
  ) async {
    await _size(tester, 430);
    await tester.pumpWidget(
      _app(_firearm, BallisticsView.environment, dark: true),
    );
    await tester.pumpAndSettle();

    // Hava card: Sıcaklık | Bağıl nem on one row.
    final air = tester.getRect(_textField(BallisticsFieldKeys.temperature));
    final hum = tester.getRect(_textField(BallisticsFieldKeys.humidity));
    expect(hum.top, moreOrLessEquals(air.top, epsilon: 0.01));
    expect(hum.left, greaterThan(air.right));

    // The box sits in its own card, below the Hava card and above
    // Basınç Ölçer.
    expect(
      find.descendant(of: find.byKey(_card), matching: find.byKey(_ammoKey)),
      findsOneWidget,
    );
    final header = tester.getRect(find.byKey(_header));
    final card = tester.getRect(find.byKey(_card));
    final weatherButton = tester.getRect(
      find.byKey(const Key('environment-fill-weather')),
    );
    final barometer = tester.getRect(
      find.byKey(const Key('environment-barometer-card')),
    );
    expect(header.top, greaterThan(weatherButton.bottom));
    expect(card.top, greaterThanOrEqualTo(header.bottom));
    expect(barometer.top, greaterThan(card.bottom));
    expect(tester.getRect(find.byKey(_ammoKey)).top, greaterThan(hum.bottom));

    // Title, its ⓘ right after it, "isteğe bağlı" at the right end in
    // the secondary colour #9CB1C0.
    final title = find.descendant(
      of: find.byKey(_header),
      matching: find.text('Mühimmat sıcaklığı'),
    );
    expect(title, findsOneWidget);
    final info = find.byKey(const Key('environment-ammo-temp-info'));
    expect(info, findsOneWidget);
    expect(
      tester.getRect(info).left,
      greaterThanOrEqualTo(tester.getRect(title).right - 0.01),
    );
    final optional = find.byKey(const Key('environment-ammo-temp-optional'));
    expect(tester.widget<Text>(optional).data, 'isteğe bağlı');
    expect(tester.widget<Text>(optional).style!.color, const Color(0xFF9CB1C0));
    expect(
      tester.getRect(optional).right,
      moreOrLessEquals(header.right, epsilon: 0.5),
    );
    expect(
      tester.getRect(optional).left,
      greaterThan(tester.getRect(info).right),
    );
    // Title left-aligned with the card.
    expect(tester.getRect(title).left, moreOrLessEquals(card.left, epsilon: 1));

    // The header ⓘ opens the same text as the box ⓘ.
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('katsayı'),
      ),
      findsWidgets,
    );
  });

  testWidgets('PCP: no Mühimmat sıcaklığı section', (tester) async {
    await _size(tester, 430);
    await tester.pumpWidget(_app(_pcp, BallisticsView.environment));
    await tester.pumpAndSettle();
    expect(find.byKey(_header), findsNothing);
    expect(find.byKey(_card), findsNothing);
    expect(find.byKey(_ammoKey), findsNothing);
    expect(find.text('Mühimmat sıcaklığı'), findsNothing);
    expect(find.text('isteğe bağlı'), findsNothing);
  });

  testWidgets('a saved value loads into the moved box and gives the same '
      'solution as typing it', (tester) async {
    SharedPreferences.setMockInitialValues({
      ShotSettingsStore.keyFor(_firearm.id): jsonEncode(
        const ShotSettings(ammoTempText: '35').toJson(),
      ),
    });
    await _size(tester, 430);

    Future<double> up600() async {
      await tester.pumpWidget(_app(_firearm, BallisticsView.pro));
      await tester.pumpAndSettle();
      final range = _textField(const Key('pro-shot-range'));
      await tester.ensureVisible(range);
      await tester.enterText(range, '600');
      await tester.pump();
      await tester.pumpWidget(_app(_firearm, BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredUp!;
    }

    Future<void> typeAmmo(String v) async {
      await tester.pumpWidget(_app(_firearm, BallisticsView.environment));
      await tester.pumpAndSettle();
      final f = _textField(_ammoKey);
      await tester.ensureVisible(f);
      await tester.enterText(f, v);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(_app(_firearm, BallisticsView.environment));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_textField(_ammoKey)).controller!.text,
      '35',
    );
    final saved = await up600();

    // Empty: the air temperature (the behaviour on main).
    await typeAmmo('');
    final plain = await up600();
    expect(saved, lessThan(plain));

    // Typed again: exactly the saved result.
    await typeAmmo('35');
    expect(await up600(), saved);

    // Saved under the same key as before.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ShotSettingsStore.keyFor(_firearm.id))!;
    expect((jsonDecode(raw) as Map)['ammoTemp'], '35');
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('no overflow at $width pt, text scale 1.3', (tester) async {
      await _size(tester, width, 844);
      await tester.pumpWidget(
        _app(_firearm, BallisticsView.environment, scale: 1.3),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(_card));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(_header), findsOneWidget);
      expect(
        find.byKey(const Key('environment-ammo-temp-optional')),
        findsOneWidget,
      );
      final header = tester.getRect(find.byKey(_header));
      expect(header.right, lessThanOrEqualTo(width + 0.01));
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'scroll step $i');
      }
    });
  }
}
