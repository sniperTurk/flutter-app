// SNIPER TÜRK — telefon tarafı Garmin köprüsü (iOS Runner).
//
// Dart `sniper_turk/garmin` kanalı ile Garmin Connect IQ Mobile SDK arasında
// aracı. Ayrıntılar SniperTurkGarminBridge.m dosyasında.
//
// İskelete yalnızca tools/configure_ios_garmin_bridge.py + .rb ile eklenir
// (elle tetiklenen .github/workflows/garmin-sim.yml). TestFlight iskeleti bu
// dosyayı içermez.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SniperTurkGarminBridge : NSObject <FlutterPlugin>
@end

NS_ASSUME_NONNULL_END
