// NATO standart mermi BC'si (owner, 2026-10-12): "MKE çok büyük olasılıkla
// NATO standartlarında mermi üretiyor. NATO verilerini kullan; ⓘ alanında
// veriyi nasıl eklediğimizi açıkla; kullanıcı isterse değiştirsin."
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

Future<void> _openNew(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
}

String _bcText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('ammo-bc')),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

String _bcInfo(WidgetTester tester) =>
    tester.widget<MenzilInput>(find.byKey(const Key('ammo-bc'))).info!;

const _m855Note =
    "ABD Ordusu bu fişeğin BC'sini yayımlamıyor. Değer, aynı NATO standart "
    'mermisinin (M855) resmi test raporundan alındı (ARL-TR-5182). Kendi '
    'tüfeğinizde fark olabilir; kutudaki ya da ölçtüğünüz değeri girebilir, '
    'Doğrulama ekranıyla düzeltebilirsiniz.';

void main() {
  group('NATO standart mermi BC', () {
    test('M855 has the ARL-TR-5182 G7 BC and its source', () {
      final m855 = FactoryAmmoLibrary.all.singleWhere(
        (a) => a.brand == 'ABD Ordusu' && a.name == 'M855',
      );
      expect(m855.cartridge, '5.56x45 NATO');
      expect(m855.bc, 0.154);
      expect(m855.model, BallisticModel.g7);
      expect(m855.muzzleVelocityFps, 3113);
      expect(m855.testBarrelIn, 20);
      expect(m855.bcSource, 'nato-standard');
      expect(m855.bcStandard, 'M855');
      expect(m855.bcReport, 'ARL-TR-5182');
      expect(
        m855.bcSourceUrl,
        'https://apps.dtic.mil/sti/tr/pdf/ADA530895.pdf',
      );
    });

    test('every NATO-sourced round names standard, report and URL', () {
      final nato = FactoryAmmoLibrary.all.where(
        (a) => a.bcSource == 'nato-standard',
      );
      expect(nato, isNotEmpty);
      for (final a in nato) {
        expect(a.bc, isNotNull, reason: a.name);
        expect(a.model, isNotNull, reason: a.name);
        expect(a.bcStandard, isNotEmpty, reason: a.name);
        expect(a.bcReport, isNotEmpty, reason: a.name);
        expect(a.bcSourceUrl, startsWith('https://'), reason: a.name);
      }
    });

    test('other rounds carry no NATO mark', () {
      for (final a in FactoryAmmoLibrary.all) {
        if (a.bcSource != null) continue;
        expect(a.bcStandard, isNull, reason: a.name);
        expect(a.bcReport, isNull, reason: a.name);
        expect(a.bcSourceUrl, isNull, reason: a.name);
      }
      final m80 = FactoryAmmoLibrary.all.singleWhere(
        (a) => a.brand == 'MKE' && a.name.contains('M80'),
      );
      expect(m80.bc, 0.45);
      expect(m80.bcSource, isNull);
    });

    test('the ⓘ note: who does not publish, which standard, which report', () {
      expect(
        ProfileFieldInfo.bcNatoStandard(
          brand: 'ABD Ordusu',
          standard: 'M855',
          report: 'ARL-TR-5182',
        ),
        _m855Note,
      );
      expect(
        ProfileFieldInfo.bcNatoStandard(
          brand: 'MKE',
          standard: 'M80',
          report: 'X',
          probable: true,
        ),
        contains('muhtemel eşdeğeri olan NATO standart mermisinin (M80)'),
      );
    });

    testWidgets('picking M855 fills BC, ⓘ explains, the box stays editable', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '5.56x45 NATO');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'ABD Ordusu');
      await chooseInSelect(tester, 'ammo-model-select', 'M855 · 62 gr');
      expect(_bcText(tester), '0,154');
      expect(_bcInfo(tester), '${ProfileFieldInfo.bcFirearm}\n\n$_m855Note');
      // No helper text under the box: the note lives only in ⓘ.
      expect(find.textContaining('NATO standart'), findsNothing);
      await enterRifleField(tester, 'ammo-bc', '0,151');
      expect(_bcText(tester), '0,151');
    });

    testWidgets('another round: the BC ⓘ is as before', (tester) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '5.56x45 NATO');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await chooseInSelect(tester, 'ammo-brand-select', 'ABD Ordusu');
      await chooseInSelect(tester, 'ammo-model-select', 'M855 · 62 gr');
      await chooseInSelect(tester, 'ammo-brand-select', 'MKE');
      await chooseInSelect(
        tester,
        'ammo-model-select',
        '5.56×45 Fişek Normal (SS109) · 61.7 gr',
      );
      final ss109 = FactoryAmmoLibrary.all.singleWhere(
        (a) => a.brand == 'MKE' && a.name.contains('SS109'),
      );
      expect(
        _bcInfo(tester),
        '${ProfileFieldInfo.bcFirearm}\n\nBu fişek: ${ss109.note}',
      );
      expect(_bcInfo(tester), isNot(contains('NATO standart')));
    });
  });
}
