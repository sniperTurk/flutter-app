import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=(ROOT/'lib/features/ballistics/ballistics_screen.dart').read_text(encoding='utf-8')

class V197AtomicUnitPreferenceConversion(unittest.TestCase):
    def _conversion_body(self):
        start=SRC.index('  void _convertControllersToImperial() {')
        end=SRC.index('\n  void solve() {', start)
        return SRC[start:end]

    def test_all_source_values_are_parsed_before_first_controller_write(self):
        body=self._conversion_body()
        # V381: Namlu çıkış hızı is fps in every unit system (owner rule), so
        # the velocity field is no longer converted; zero is the first write.
        self.assertNotIn('velocity.text =', body)
        first_write=body.index('zero.text =')
        for marker in (
            'final zeroM = value(zero);',
            'final sightMm = value(sight);', 'final windMps = value(wind);',
            'final temperatureC = value(temperature);', 'final pressureHpa = value(pressure);',
            'final altitudeM = value(altitude);', 'final metricRanges = DopeRanges.parse(ranges.text);'):
            self.assertIn(marker, body)
            self.assertLess(body.index(marker), first_write, marker)

    def test_locale_decimal_comma_is_accepted_during_async_conversion(self):
        body=self._conversion_body()
        self.assertIn("c.text.trim().replaceAll(',', '.')", body)

    def test_metric_flag_changes_only_after_conversion_returns(self):
        load_start=SRC.index('  Future<void> _loadUnitPreference() async {')
        load_end=SRC.index('\n  void _convertControllersToImperial()', load_start)
        load=SRC[load_start:load_end]
        self.assertLess(load.index('_convertControllersToImperial();'), load.index('setState(() => metric = loadedMetric);'))

if __name__=='__main__': unittest.main()
