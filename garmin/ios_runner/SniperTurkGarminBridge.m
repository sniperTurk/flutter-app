// SNIPER TÜRK — telefon tarafı Garmin köprüsü (iOS Runner).
//
// Dart `sniper_turk/garmin` kanalı ile Garmin Connect IQ Mobile SDK arasında
// aracı. Sözleşme Apple Watch köprüsüyle (`sniper_turk/watch`) aynıdır:
//   Telefon → saat: `publish(map)` → bağlı her Garmin saatindeki SNIPER TÜRK
//     uygulamasına ConnectIQ sendMessage. En az bir bağlı saat varsa YES.
//   Saat → telefon: saatin Communications.transmit'i → Dart'a `fromWatch(map)`.
//   `selectDevice`: Garmin Connect uygulamasını açar; kullanıcı saatini seçer,
//     Garmin Connect bu uygulamayı `sniperturk-ciq://` adresiyle geri açar.
//
// Seçilen saatler cihazda saklanır (Application Support); her seçimde liste
// baştan yazılır. Saat seçilmemişse, bağlı değilse veya Garmin Connect kurulu
// değilse `publish` sessizce NO döner; hiçbir şey atılmaz.
//
// Bu dosya iskelete yalnızca tools/configure_ios_garmin_bridge.py + .rb ile
// eklenir (elle tetiklenen garmin-sim.yml). TestFlight iskeleti içermez.

#import "SniperTurkGarminBridge.h"

#import <ConnectIQ/ConnectIQ.h>
#import <UIKit/UIKit.h>

static NSString *const kChannelName = @"sniper_turk/garmin";
// Garmin Connect'in cihaz listesini geri gönderdiği adres şeması. Info.plist
// CFBundleURLTypes ile aynı olmalı (tools/configure_ios_garmin_bridge.py).
static NSString *const kURLScheme = @"sniperturk-ciq";
// garmin/manifest.xml içindeki uygulama kimliği (tireli biçim).
static NSString *const kWatchAppUUID = @"4dde1aef-12b6-4a15-b5a6-209c2c5944b0";
static NSString *const kDevicesFileName = @"sniperturk-garmin-devices";

@interface SniperTurkGarminBridge () <IQDeviceEventDelegate, IQAppMessageDelegate>
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, strong) NSMutableDictionary<NSUUID *, IQDevice *> *devices;
@property(nonatomic, strong) NSUUID *watchAppUUID;
// Son çözüm: saat sonradan bağlanırsa ona da gönderilir (yalnızca son durum).
@property(nonatomic, copy, nullable) NSDictionary *lastMessage;
@end

@implementation SniperTurkGarminBridge

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kChannelName
                                  binaryMessenger:[registrar messenger]];
  SniperTurkGarminBridge *instance = [[SniperTurkGarminBridge alloc] initWithChannel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
  // Garmin Connect'ten dönüş: uygulama yaşam döngüsü ve (varsa) sahne
  // yaşam döngüsü. Sahne API'si eski Flutter sürümlerinde yoktur.
  [registrar addApplicationDelegate:instance];
  SEL addScene = NSSelectorFromString(@"addSceneDelegate:");
  if ([registrar respondsToSelector:addScene]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [registrar performSelector:addScene withObject:instance];
#pragma clang diagnostic pop
  }
  [instance start];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  if ((self = [super init])) {
    _channel = channel;
    _devices = [NSMutableDictionary dictionary];
    _watchAppUUID = [[NSUUID alloc] initWithUUIDString:kWatchAppUUID];
  }
  return self;
}

- (void)start {
  // UI override delegate nil: Garmin Connect kurulu değilse SDK kendi
  // uyarısını gösterir (yalnızca kullanıcı saat seçmek istediğinde).
  [[ConnectIQ sharedInstance] initializeWithUrlScheme:kURLScheme uiOverrideDelegate:nil];
  [self restoreDevices];
  [self listenToDevices];
}

#pragma mark - Flutter

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"publish"]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result(@NO);
      return;
    }
    result(@([self publish:call.arguments]));
  } else if ([call.method isEqualToString:@"selectDevice"]) {
    [[ConnectIQ sharedInstance] showConnectIQDeviceSelection];
    result(@YES);
  } else if ([call.method isEqualToString:@"deviceCount"]) {
    result(@(self.devices.count));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (BOOL)publish:(NSDictionary *)message {
  self.lastMessage = message;
  BOOL any = NO;
  for (IQDevice *device in self.devices.allValues) {
    if ([[ConnectIQ sharedInstance] getDeviceStatus:device] != IQDeviceStatus_Connected) {
      continue;
    }
    any = YES;
    [self send:message to:device];
  }
  return any;
}

- (void)send:(NSDictionary *)message to:(IQDevice *)device {
  IQApp *app = [self appOn:device];
  [[ConnectIQ sharedInstance] sendMessage:message
                                    toApp:app
                                 progress:nil
                               completion:^(IQSendMessageResult result) {
                                 // Saat uygulaması kurulu değil veya kapalı: sessiz.
                                 // Telefon her dakika yeniden gönderir.
                               }];
}

- (IQApp *)appOn:(IQDevice *)device {
  return [IQApp appWithUUID:self.watchAppUUID storeUuid:self.watchAppUUID device:device];
}

#pragma mark - Garmin Connect dönüşü

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  return [self handleURL:url];
}

// FlutterSceneLifeCycleDelegate (UIScene kullanan iskelet).
- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
  BOOL handled = NO;
  for (UIOpenURLContext *context in URLContexts) {
    handled = [self handleURL:context.URL] || handled;
  }
  return handled;
}

- (BOOL)handleURL:(NSURL *)url {
  if (![url.scheme isEqualToString:kURLScheme]) {
    return NO;
  }
  NSArray *selected = [[ConnectIQ sharedInstance] parseDeviceSelectionResponseFromURL:url];
  if (selected == nil) {
    return NO;
  }
  // Garmin Connect'in son listesi geçerlidir; eskiler unutulur.
  [[ConnectIQ sharedInstance] unregisterForAllDeviceEvents:self];
  [[ConnectIQ sharedInstance] unregisterForAllAppMessages:self];
  [self.devices removeAllObjects];
  for (id item in selected) {
    if ([item isKindOfClass:[IQDevice class]]) {
      IQDevice *device = item;
      self.devices[device.uuid] = device;
    }
  }
  [self saveDevices];
  [self listenToDevices];
  return YES;
}

#pragma mark - Saatler

- (void)listenToDevices {
  for (IQDevice *device in self.devices.allValues) {
    [[ConnectIQ sharedInstance] registerForDeviceEvents:device delegate:self];
    [[ConnectIQ sharedInstance] registerForAppMessages:[self appOn:device] delegate:self];
  }
}

- (void)deviceStatusChanged:(IQDevice *)device status:(IQDeviceStatus)status {
  if (status != IQDeviceStatus_Connected) {
    return;
  }
  NSDictionary *last = self.lastMessage;
  if (last != nil) {
    [self send:last to:device];
  }
}

- (void)receivedMessage:(id)message fromApp:(IQApp *)app {
  if (![message isKindOfClass:[NSDictionary class]]) {
    return;
  }
  NSDictionary *payload = message;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.channel invokeMethod:@"fromWatch" arguments:payload];
  });
}

#pragma mark - Kalıcı liste

- (NSString *)devicesPath {
  NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                      NSUserDomainMask, YES);
  NSString *dir = dirs.firstObject;
  if (dir == nil) {
    return nil;
  }
  [[NSFileManager defaultManager] createDirectoryAtPath:dir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
  return [dir stringByAppendingPathComponent:kDevicesFileName];
}

- (void)saveDevices {
  NSString *path = [self devicesPath];
  if (path == nil) {
    return;
  }
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.devices
                                       requiringSecureCoding:YES
                                                       error:nil];
  [data writeToFile:path atomically:YES];
}

- (void)restoreDevices {
  NSString *path = [self devicesPath];
  NSData *data = path == nil ? nil : [NSData dataWithContentsOfFile:path];
  if (data == nil) {
    return;
  }
  NSSet *allowed = [NSSet setWithObjects:[NSMutableDictionary class], [NSDictionary class],
                                         [IQDevice class], [NSString class], [NSUUID class],
                                         nil];
  id restored = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowed fromData:data error:nil];
  if (![restored isKindOfClass:[NSDictionary class]]) {
    return;
  }
  for (id key in restored) {
    id device = restored[key];
    if ([key isKindOfClass:[NSUUID class]] && [device isKindOfClass:[IQDevice class]]) {
      self.devices[key] = device;
    }
  }
}

@end
