// Dürbün ürün bildirimi (owner, 2026-10-17 22:09–22:15 Istanbul): a profile
// saved with a typed scope ("Aradığın dürbün listede yok mu?") sends that
// scope's entered values once to the Cloudflare product box. The save never
// waits for or depends on it; an unchanged scope is not sent again; a
// catalog scope is never sent; the returned id is kept on the device.
//
// No test talks to the real worker: the adapter is tested with
// package:http's MockClient, the screens with a fake service.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/services/product_report_ledger.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/tools/adapters/cloudflare_product_report_service.dart';
import 'package:sniper_turk/tools/ports/product_report_service.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';
import 'support/tool_fakes.dart';

class _FakeReports implements ProductReportService {
  final List<ProductReport> sent = [];

  /// Thrown by [send] when set (network failure).
  Object? error;

  /// When set, [send] never answers (a request that hangs).
  Completer<String>? hold;

  @override
  Future<String> send(ProductReport report) async {
    sent.add(report);
    if (error != null) throw error!;
    if (hold != null) return hold!.future;
    return 'kayit-${sent.length}';
  }
}

/// The values [fillScopeForm] enters, plus Retikül and Üst kule klik sayısı.
const _expectedFields = <String, Object>{
  'marka': 'Test Optik',
  'model': 'X1',
  'birim': 'MRAD',
  'odakDuzlemi': 'FFP',
  'minBuyutme': 6,
  'maxBuyutme': 24,
  'mercekCapi': 56,
  'klikDegeri': 0.1,
  'ustKuleKlikSayisi': 200,
  'retikul': 'Duplex',
};

Future<void> _pump(
  WidgetTester tester,
  ProfileStore store,
  _FakeReports reports,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      // Above the Navigator, as in lib/main.dart.
      builder: (context, child) => ToolsServicesScope(
        services: testServices(productReports: reports),
        child: child!,
      ),
      home: ProfilesScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
}

Future<MemoryProfileStore> _openNew(
  WidgetTester tester,
  _FakeReports reports,
) async {
  tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemoryProfileStore();
  await _pump(tester, store, reports);
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  expect(find.text('Profil Oluştur'), findsOneWidget);
  return store;
}

Future<void> _fillTypedProfile(WidgetTester tester) async {
  await fillScopeForm(tester);
  await chooseInSelect(tester, 'scope-reticle', 'Duplex');
  await enterRifleField(tester, 'scope-travel-elevation', '200');
  await fillRifleForm(tester);
  await fillAmmoForm(tester);
  await fillShotValues(tester);
}

Future<void> _press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(MenzilPrimaryButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(tester.widget<MenzilPrimaryButton>(button).onPressed, isNotNull);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openEdit(WidgetTester tester, String name) async {
  final row = find.text(name).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('Profili Düzenle'), findsOneWidget);
}

Future<List<SentProductReport>> _storedIds() async =>
    ProductReportLedger.sentReports(await SharedPreferences.getInstance());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogRepository.installUserCatalog(UserCatalog.empty);
  });
  tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

  group('CloudflareProductReportService (MockClient, no real network)', () {
    const report = ProductReport(ProductReportKind.durbun, _expectedFields);

    test('one POST to /urun with exactly the agreed JSON', () async {
      final requests = <http.Request>[];
      final service = CloudflareProductReportService(
        appVersion: '1.0.0+42',
        client: MockClient((r) async {
          requests.add(r);
          return http.Response('{"ok":true,"id":"1792-abc"}', 201);
        }),
      );
      expect(await service.send(report), '1792-abc');
      expect(requests, hasLength(1));
      final r = requests.single;
      expect(r.method, 'POST');
      expect(
        r.url.toString(),
        'https://sniper-turk-urun-kutusu.sekerbirol76.workers.dev/urun',
      );
      expect(r.headers['Content-Type'], startsWith('application/json'));
      expect(
        r.body,
        '{"tur":"durbun","platform":"ios","uygulamaSurumu":"1.0.0+42",'
        '"kurulumKimligi":null,"alanlar":{"marka":"Test Optik",'
        '"model":"X1","birim":"MRAD","odakDuzlemi":"FFP","minBuyutme":6,'
        '"maxBuyutme":24,"mercekCapi":56,"klikDegeri":0.1,'
        '"ustKuleKlikSayisi":200,"retikul":"Duplex"}}',
      );
    });

    test('default timeout is 10 s', () {
      expect(
        CloudflareProductReportService(appVersion: 'x').timeout,
        const Duration(seconds: 10),
      );
    });

    test('server error, bad answer, offline and timeout all throw '
        'ProductReportFailure', () async {
      Future<void> expectFailure(MockClientHandler h, {Duration? t}) async {
        final service = CloudflareProductReportService(
          appVersion: 'x',
          client: MockClient(h),
          timeout: t ?? const Duration(seconds: 10),
        );
        await expectLater(
          service.send(report),
          throwsA(isA<ProductReportFailure>()),
        );
      }

      await expectFailure((_) async => http.Response('{"ok":false}', 400));
      await expectFailure((_) async => http.Response('oops', 500));
      await expectFailure((_) async => http.Response('not json', 201));
      await expectFailure((_) async => http.Response('{"ok":true}', 201));
      await expectFailure((_) async => throw http.ClientException('offline'));
      await expectFailure(
        (_) => Future.delayed(
          const Duration(seconds: 1),
          () => http.Response('{"ok":true,"id":"late"}', 201),
        ),
        t: const Duration(milliseconds: 20),
      );
    });

    test('values outside the worker limits are not sent', () async {
      var calls = 0;
      final service = CloudflareProductReportService(
        appVersion: 'x',
        client: MockClient((_) async {
          calls++;
          return http.Response('{"ok":true,"id":"x"}', 201);
        }),
      );
      for (final fields in <Map<String, Object>>[
        {},
        {'model': 'a' * 201},
        {'bad key': 'x'},
        {for (var i = 0; i < 31; i++) 'k$i': i},
      ]) {
        await expectLater(
          service.send(ProductReport(ProductReportKind.durbun, fields)),
          throwsA(isA<ProductReportFailure>()),
        );
      }
      expect(calls, 0);
    });
  });

  test('test, simulator and CI builds carry no product box', () {
    // SNIPER_TURK_APP_VERSION is set only by ios-testflight.yml.
    expect(ToolsServices.appVersion, isEmpty);
    expect(ToolsServices.production().productReports, isNull);
  });

  testWidgets('typed scope: one request with exactly the entered values; '
      'the id is stored; unchanged save sends nothing; a changed value sends '
      'again', (tester) async {
    final reports = _FakeReports();
    final store = await _openNew(tester, reports);
    await _fillTypedProfile(tester);
    await _press(tester, 'Kaydet');
    final saved = (await store.all()).single;

    expect(reports.sent, hasLength(1));
    expect(reports.sent.single.kind, ProductReportKind.durbun);
    expect(reports.sent.single.fields, equals(_expectedFields));
    // Numbers are numbers (6, 0.1, 200), not text.
    expect(
      jsonEncode(reports.sent.single.fields),
      '{"marka":"Test Optik","model":"X1","birim":"MRAD",'
      '"odakDuzlemi":"FFP","minBuyutme":6,"maxBuyutme":24,"mercekCapi":56,'
      '"klikDegeri":0.1,"ustKuleKlikSayisi":200,"retikul":"Duplex"}',
    );
    final ids = await _storedIds();
    expect(ids, hasLength(1));
    expect(ids.single.id, 'kayit-1');
    expect(ids.single.tur, 'durbun');

    // Saved again unchanged: nothing is sent.
    await _openEdit(tester, saved.name);
    await _press(tester, 'Güncelle');
    expect(reports.sent, hasLength(1));

    // A scope value changed: sent again, with the new value.
    await _openEdit(tester, saved.name);
    await enterRifleField(tester, 'scope-model', 'X2');
    await _press(tester, 'Güncelle');
    expect(reports.sent, hasLength(2));
    expect(reports.sent.last.fields, {..._expectedFields, 'model': 'X2'});
    expect((await _storedIds()).map((r) => r.id), ['kayit-1', 'kayit-2']);

    // And unchanged again after that: nothing.
    await _openEdit(tester, saved.name);
    await _press(tester, 'Güncelle');
    expect(reports.sent, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty optional values are left out', (tester) async {
    final reports = _FakeReports();
    await _openNew(tester, reports);
    // No Retikül, no Üst kule klik sayısı.
    await fillScopeForm(tester);
    await fillRifleForm(tester);
    await fillAmmoForm(tester);
    await fillShotValues(tester);
    await _press(tester, 'Kaydet');
    expect(reports.sent, hasLength(1));
    expect(
      reports.sent.single.fields,
      equals(
        Map.of(_expectedFields)
          ..remove('retikul')
          ..remove('ustKuleKlikSayisi'),
      ),
    );
  });

  testWidgets('catalog scope: nothing is sent', (tester) async {
    final reports = _FakeReports();
    final store = await _openNew(tester, reports);
    await chooseInSelect(tester, 'scope-brand-select', 'Element Optics');
    await chooseInSelect(
      tester,
      'scope-filter-unit-Element Optics-null',
      'MOA',
    );
    await chooseInSelect(tester, 'scope-filter-ffp-Element Optics-null', 'FFP');
    await chooseInSelect(tester, 'scope-model-select', 'Titan 3-18x50 FFP MOA');
    await chooseInSelect(tester, 'scope-reticle', 'APR-2D MOA');
    await chooseInSelect(tester, 'scope-mount', 'Normal (0 MOA)');
    await fillRifleForm(tester);
    await fillAmmoForm(tester);
    await fillShotValues(tester);
    await _press(tester, 'Kaydet');
    expect(await store.all(), hasLength(1));
    expect(reports.sent, isEmpty);
    expect(await _storedIds(), isEmpty);
  });

  testWidgets('network failure: the profile is saved, nothing is shown, '
      'nothing is stored, the next save tries again', (tester) async {
    final reports = _FakeReports()
      ..error = const ProductReportFailure('Bağlantı yok.');
    final store = await _openNew(tester, reports);
    await _fillTypedProfile(tester);
    await _press(tester, 'Kaydet');
    final saved = (await store.all()).single;
    expect(find.text('Profil Oluştur'), findsNothing, reason: 'closed');
    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Bağlantı'), findsNothing);
    expect(reports.sent, hasLength(1));
    expect(await _storedIds(), isEmpty);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ProductReportLedger.hashesKey,
      ),
      isNull,
    );

    reports.error = null;
    await _openEdit(tester, saved.name);
    await _press(tester, 'Güncelle');
    expect(reports.sent, hasLength(2));
    expect((await _storedIds()).single.id, 'kayit-2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a request that never answers does not block saving', (
    tester,
  ) async {
    final reports = _FakeReports()..hold = Completer<String>();
    final store = await _openNew(tester, reports);
    await _fillTypedProfile(tester);
    await _press(tester, 'Kaydet');
    expect(await store.all(), hasLength(1));
    expect(find.text('Profil Oluştur'), findsNothing);
    expect(reports.sent, hasLength(1));
    expect(await _storedIds(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no product box in the app (tests, CI): saving sends nothing '
      'and works as before', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.light(),
        home: ProfilesScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni profil'));
    await tester.pumpAndSettle();
    await _fillTypedProfile(tester);
    await _press(tester, 'Kaydet');
    expect(await store.all(), hasLength(1));
    expect(await _storedIds(), isEmpty);
  });

  group('ProductReportLedger', () {
    test('hash ignores key order and changes with any value', () {
      const a = ProductReport(ProductReportKind.durbun, {'a': 1, 'b': 'x'});
      const b = ProductReport(ProductReportKind.durbun, {'b': 'x', 'a': 1});
      const c = ProductReport(ProductReportKind.durbun, {'a': 2, 'b': 'x'});
      const d = ProductReport(ProductReportKind.muhimmat, {'a': 1, 'b': 'x'});
      expect(ProductReportLedger.hashOf(a), ProductReportLedger.hashOf(b));
      expect(ProductReportLedger.hashOf(a), isNot(ProductReportLedger.hashOf(c)));
      expect(ProductReportLedger.hashOf(a), isNot(ProductReportLedger.hashOf(d)));
    });

    test('per profile: the same scope on two profiles is sent per profile '
        'once; createdAt is stored', () async {
      final reports = _FakeReports();
      final at = DateTime.utc(2026, 10, 17, 19, 30);
      final ledger = ProductReportLedger(reports, now: () => at);
      const r = ProductReport(ProductReportKind.durbun, {'marka': 'A'});
      await ledger.reportOnce('p1', r);
      await ledger.reportOnce('p1', r);
      await ledger.reportOnce('p2', r);
      expect(reports.sent, hasLength(2));
      final ids = await _storedIds();
      expect(ids.map((e) => e.id), ['kayit-1', 'kayit-2']);
      expect(ids.first.createdAt, at);
      final raw = jsonDecode(
        (await SharedPreferences.getInstance()).getString(
          ProductReportLedger.idsKey,
        )!,
      );
      expect(raw.first, {
        'id': 'kayit-1',
        'tur': 'durbun',
        'createdAt': '2026-10-17T19:30:00.000Z',
      });
    });

    test('two saves while the first request is in flight send once', () async {
      final reports = _FakeReports()..hold = Completer<String>();
      final ledger = ProductReportLedger(reports);
      const r = ProductReport(ProductReportKind.durbun, {'marka': 'A'});
      final first = ledger.reportOnce('p1', r);
      await Future<void>.delayed(Duration.zero);
      await ledger.reportOnce('p1', r);
      reports.hold!.complete('kayit-x');
      await first;
      expect(reports.sent, hasLength(1));
      expect((await _storedIds()).single.id, 'kayit-x');
    });

    test('never throws', () async {
      final reports = _FakeReports()..error = StateError('boom');
      await ProductReportLedger(reports).reportOnce(
        'p1',
        const ProductReport(ProductReportKind.durbun, {'marka': 'A'}),
      );
      expect(await _storedIds(), isEmpty);
    });
  });
}
