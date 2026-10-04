import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/catalog/catalog_screen.dart';
import 'package:sniper_turk/models/domain.dart';

/// The catalog is a lazy list: on the default 800x600 surface only the first
/// few tiles are built, so finders for deeper records would find nothing.
void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 150000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('catalog defaults to PCP and does not mix firearm rifle/ammunition', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    expect(find.text('PCP Tüfekler'), findsWidgets);
    expect(find.textContaining('HATSAN Factor Sniper Long'), findsOneWidget);
    expect(find.textContaining('Manuel Ateşli Tüfek'), findsNothing);
    expect(find.textContaining('Manuel Ateşli Mühimmat'), findsNothing);
  });

  testWidgets('switching to firearm filters rifles and ammunition together', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    await tester.tap(find.text('Ateşli Tüfekler').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Manuel Ateşli Tüfek'), findsOneWidget);
    expect(find.textContaining('Manuel Ateşli Mühimmat'), findsOneWidget);
    expect(find.textContaining('HATSAN Factor Sniper Long'), findsNothing);
  });

  testWidgets('explicit firearm initial platform is honored', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen(initialPlatform: WeaponPlatform.firearm)));
    expect(find.textContaining('Manuel Ateşli Tüfek'), findsOneWidget);
    expect(find.textContaining('HATSAN Factor Sniper Long'), findsNothing);
  });
  testWidgets('catalog search filters visible records without crossing platform', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    await tester.enterText(find.byKey(const Key('catalog-search')), 'HATSAN');
    await tester.pump();
    expect(find.textContaining('HATSAN Factor Sniper Long'), findsOneWidget);
    expect(find.textContaining('AirMaks Arms Krait PRO X HP'), findsNothing);
    expect(find.textContaining('ATA Arms'), findsNothing);
  });

  testWidgets('catalog search can be cleared', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    await tester.enterText(find.byKey(const Key('catalog-search')), 'zzzz-no-match');
    await tester.pump();
    expect(find.text('Aramaya uygun tüfek kaydı yok.'), findsOneWidget);
    await tester.tap(find.byTooltip('Aramayı temizle'));
    await tester.pump();
    expect(find.textContaining('HATSAN Factor Sniper Long'), findsOneWidget);
  });

  testWidgets('catalog exposes provenance for ammunition and optics', (tester) async {
    _tallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    expect(find.textContaining('Kaynak: JSB Match Diabolo'), findsWidgets);
    expect(find.textContaining('Kaynak: Arken Optics USA'), findsWidgets);
    expect(find.textContaining('Kaynak doğrulanmadı'), findsWidgets);
  });

}

// v103 regression coverage: search must filter all visible catalog sections
// without bypassing the active PCP/firearm platform boundary.
