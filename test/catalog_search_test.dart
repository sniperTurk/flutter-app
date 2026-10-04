import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/catalog_search.dart';

void main() {
  test('Turkish letters match ASCII keyboard input', () {
    expect(CatalogSearch.matches('Huğlu Spark', 'huglu'), isTrue);
    expect(CatalogSearch.matches('Çığır ÖŞÜ', 'cigir osu'), isTrue);
  });

  test('catalog query terms may be entered in any order', () {
    expect(
      CatalogSearch.matches('HATSAN Hercules 6.35', '6.35 hatsan'),
      isTrue,
    );
    expect(
      CatalogSearch.matches('HATSAN Hercules 6.35', 'hatsan 5.5'),
      isFalse,
    );
  });

  test('empty or whitespace query matches everything', () {
    expect(CatalogSearch.matches('anything', '   '), isTrue);
  });
}
