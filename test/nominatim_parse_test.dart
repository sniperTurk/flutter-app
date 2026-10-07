import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/tools/adapters/nominatim_place_search.dart';
import 'package:sniper_turk/tools/ports/place_search.dart';

void main() {
  test('parses jsonv2 results and skips invalid entries', () {
    final r = NominatimPlaceSearch.parse(
      '[{"display_name":"Seydiköy, İzmir","lat":"38.07","lon":"26.93"},'
      '{"display_name":"Bad","lat":"x","lon":"1"},'
      '{"display_name":"Out","lat":"95","lon":"1"}]',
    );
    expect(r, hasLength(1));
    expect(r.first.name, 'Seydiköy, İzmir');
    expect(r.first.latitude, closeTo(38.07, 1e-9));
    expect(r.first.longitude, closeTo(26.93, 1e-9));
  });

  test('a non-list body is a server failure', () {
    expect(
      () => NominatimPlaceSearch.parse('{"error":"x"}'),
      throwsA(isA<PlaceSearchFailure>()),
    );
    expect(
      () => NominatimPlaceSearch.parse('not json'),
      throwsA(isA<PlaceSearchFailure>()),
    );
  });

  test('queries shorter than 3 characters return nothing without a request',
      () async {
    expect(await NominatimPlaceSearch().search('ab'), isEmpty);
  });
}
