// "Aradığın mühimmat listede yok mu?" (owner, 2026-10-17 21:33–21:51
// Istanbul): the request body and the best-effort weight reading. The
// network adapter is tested with a mock HTTP client; nothing reaches the
// real worker from tests.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sniper_turk/features/profiles/ammo_report.dart';
import 'package:sniper_turk/tools/adapters/cloudflare_product_report.dart';
import 'package:sniper_turk/tools/ports/product_report.dart';

void main() {
  group('readWeightGrain: the last number + unit', () {
    for (final (text, grain, unit) in const [
      ('50gr', 50.0, 'gr'),
      ('H&N Slug HP 50 gr', 50.0, 'gr'),
      ('50 grain', 50.0, 'gr'),
      ('50 grains', 50.0, 'gr'),
      ('50 grn', 50.0, 'gr'),
      ('JSB 18,13 gr.', 18.13, 'gr'),
      ('25.39 GR', 25.39, 'gr'),
      ('3,24 g', 50.0, 'g'),
      ('3.24 gram', 50.0, 'g'),
      ('3,24g', 50.0, 'g'),
      ('5,5 mm 1,17 gram', 18.06, 'g'),
      ('JSB 5,5 mm 18,13 gr', 18.13, 'gr'),
    ]) {
      test('"$text" → $grain $unit', () {
        final r = readWeightGrain(text);
        expect(r.unit, unit);
        expect(r.grain, closeTo(grain, 0.01));
      });
    }
    for (final text in const [
      'abc',
      '',
      'H&N Baracuda 50',
      '5,5 mm',
      '50 grx',
      'gr 50',
    ]) {
      test('"$text" → null', () {
        final r = readWeightGrain(text);
        expect(r.grain, isNull);
        expect(r.unit, isNull);
      });
    }
  });

  group('ammoReportBody', () {
    test('exact JSON for a PCP report', () {
      final body = ammoReportBody(
        text: '  H&N Slug HP 50 gr ',
        firearm: false,
        caliber: '6.35 mm (.25)',
        appVersion: '1.0.0+113',
      );
      expect(
        jsonEncode(body),
        jsonEncode({
          'tur': 'muhimmat',
          'platform': 'ios',
          'uygulamaSurumu': '1.0.0+113',
          'kurulumKimligi': null,
          'alanlar': {
            'metin': '  H&N Slug HP 50 gr ',
            'silah': 'pcp',
            'kalibre': '6.35 mm (.25)',
            'okunanAgirlikGr': 50.0,
            'okunanBirim': 'gr',
          },
        }),
      );
    });

    test('firearm, no caliber, unreadable weight', () {
      final body = ammoReportBody(
        text: 'abc',
        firearm: true,
        caliber: null,
        appVersion: '1.0.0+dev',
      );
      final f = body['alanlar']! as Map<String, Object?>;
      expect(f['silah'], 'atesli');
      expect(f['kalibre'], isNull);
      expect(f['okunanAgirlikGr'], isNull);
      expect(f['okunanBirim'], isNull);
      expect(f['metin'], 'abc');
    });

    test('worker limits: ≤ 30 keys, values ≤ 200 chars, body ≤ 8 KB', () {
      final body = ammoReportBody(
        text: 'x' * ammoReportMaxLength,
        firearm: true,
        caliber: '.338-378 Weatherby Mag',
        appVersion: '1.0.0+113',
      );
      final f = body['alanlar']! as Map<String, Object?>;
      expect(f.length, lessThanOrEqualTo(30));
      for (final k in f.keys) {
        expect(RegExp(r'^[A-Za-z0-9_]+$').hasMatch(k), isTrue, reason: k);
      }
      for (final v in f.values.whereType<String>()) {
        expect(v.length, lessThanOrEqualTo(200));
      }
      expect(utf8.encode(jsonEncode(body)).length, lessThan(8 * 1024));
      // No profile data, location or device identifiers.
      expect(body.keys, {
        'tur',
        'platform',
        'uygulamaSurumu',
        'kurulumKimligi',
        'alanlar',
      });
      expect(body['kurulumKimligi'], isNull);
    });
  });

  group('CloudflareProductReport', () {
    test('POSTs JSON over HTTPS to the worker; 201 ok = success', () async {
      late http.Request seen;
      final client = MockClient((r) async {
        seen = r;
        return http.Response('{"ok":true,"id":"abc"}', 201);
      });
      final body = ammoReportBody(
        text: '50gr',
        firearm: false,
        caliber: null,
        appVersion: '1.0.0+1',
      );
      await CloudflareProductReport(client: client).send(body);
      expect(seen.method, 'POST');
      expect(
        seen.url.toString(),
        'https://sniper-turk-urun-kutusu.sekerbirol76.workers.dev/urun',
      );
      expect(seen.url.scheme, 'https');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), body);
    });

    for (final (code, text) in const [
      (400, '{"ok":false,"error":"bad"}'),
      (500, 'oops'),
      (201, '{"ok":false}'),
      (200, 'not json'),
    ]) {
      test('$code "$text" → server failure', () async {
        final client = MockClient((_) async => http.Response(text, code));
        await expectLater(
          CloudflareProductReport(client: client).send(const {}),
          throwsA(
            isA<ProductReportFailure>().having(
              (e) => e.kind,
              'kind',
              ProductReportFailureKind.server,
            ),
          ),
        );
      });
    }

    test('offline → offline failure', () async {
      final client = MockClient((_) async => throw const SocketException('x'));
      await expectLater(
        CloudflareProductReport(client: client).send(const {}),
        throwsA(
          isA<ProductReportFailure>().having(
            (e) => e.kind,
            'kind',
            ProductReportFailureKind.offline,
          ),
        ),
      );
    });

    test('no answer within the timeout → timeout failure', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      await expectLater(
        CloudflareProductReport(
          client: client,
          timeout: const Duration(milliseconds: 20),
        ).send(const {}),
        throwsA(
          isA<ProductReportFailure>().having(
            (e) => e.kind,
            'kind',
            ProductReportFailureKind.timeout,
          ),
        ),
      );
    });

    test('default timeout is 10 s', () {
      expect(
        CloudflareProductReport.defaultTimeout,
        const Duration(seconds: 10),
      );
    });
  });
}
