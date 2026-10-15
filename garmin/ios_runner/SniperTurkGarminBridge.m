// SNIPER TÜRK — telefon tarafı Garmin köprüsü (iOS Runner).
//
// Dart `sniper_turk/garmin` kanalı ile Garmin Connect IQ Mobile SDK arasında
// aracı. Sözleşme Apple Watch köprüsüyle (`sniper_turk/watch`) aynıdır:
//   Telefon → saat: `publish(map)` → bağlı her Garmin saatindeki SNIPER TÜRK
//     uygulamasına ConnectIQ sendMessage (isTransient: yalnızca son durum,
//     saatin posta kutusunda birikme yok). YES "en az bir bağlı saate
//     teslim için verildi" demektir, "saate ulaştı" değil: gönderim
//     sonucu beklenmez, telefon her dakika yeniden gönderir.
//   Saat → telefon: saatin Communications.transmit'i → Dart'a `fromWatch(map)`.
//   `selectDevice`: Garmin Connect uygulamasını açar; kullanıcı saatini seçer,
//     Garmin Connect bu uygulamayı `sniperturk-ciq://` adresiyle geri açar
//     (uygulama açıkken, arka plandayken veya soğuk açılışta).
//   `sniper_turk/garmin/devices` olay kanalı: dinlemeye başlarken ve her
//     başarılı Garmin Connect dönüşünden sonra seçili saat sayısı (NSNumber).
//
// ConnectIQ SDK'sı tembel başlatılır (Bluetooth izni sorusu yalnızca Garmin
// kullananlara): kayıtta yalnızca saklı saat listesi varsa; aksi halde ilk
// `selectDevice` veya Garmin Connect dönüşünde. Saat yokken `publish` ve
// `deviceCount` SDK'yı başlatmaz.
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
static NSString *const kDevicesChannelName = @"sniper_turk/garmin/devices";
// Garmin Connect'in cihaz listesini geri gönderdiği adres şeması. Info.plist
// CFBundleURLTypes ile aynı olmalı (tools/configure_ios_garmin_bridge.py).
static NSString *const kURLScheme = @"sniperturk-ciq";
// garmin/manifest.xml içindeki uygulama kimliği (tireli biçim).
static NSString *const kWatchAppUUID = @"4dde1aef-12b6-4a15-b5a6-209c2c5944b0";
static NSString *const kDevicesFileName = @"sniperturk-garmin-devices";

@interface SniperTurkGarminBridge () <IQDeviceEventDelegate, IQAppMessageDelegate,
                                      FlutterStreamHandler>
@property(nonatomic, strong) FlutterMethodChannel *channel;
// Dart dinliyorsa saat sayısı olaylarının gideceği yer.
@property(nonatomic, copy, nullable) FlutterEventSink devicesSink;
// ConnectIQ initializeWithUrlScheme: çağrıldı mı (yalnızca bir kez).
@property(nonatomic, assign) BOOL started;
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
  FlutterEventChannel *devicesChannel =
      [FlutterEventChannel eventChannelWithName:kDevicesChannelName
                                binaryMessenger:[registrar messenger]];
  [devicesChannel setStreamHandler:instance];
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
  // Saklı liste SDK'sız okunur (IQDevice düz NSSecureCoding). Liste yoksa
  // SDK başlatılmaz: Bluetooth izni Garmin kullanmayanlara hiç sorulmaz.
  [instance restoreDevices];
  if (instance.devices.count > 0) {
    [instance ensureStarted];
  }
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  if ((self = [super init])) {
    _channel = channel;
    _devices = [NSMutableDictionary dictionary];
    _watchAppUUID = [[NSUUID alloc] initWithUUIDString:kWatchAppUUID];
  }
  return self;
}

- (void)ensureStarted {
  if (self.started) {
    return;
  }
  self.started = YES;
  // UI override delegate nil: Garmin Connect kurulu değilse SDK kendi
  // uyarısını gösterir (yalnızca kullanıcı saat seçmek istediğinde).
  [[ConnectIQ sharedInstance] initializeWithUrlScheme:kURLScheme uiOverrideDelegate:nil];
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
    [self ensureStarted];
    [[ConnectIQ sharedInstance] showConnectIQDeviceSelection];
    result(@YES);
  } else if ([call.method isEqualToString:@"deviceCount"]) {
    result(@(self.devices.count));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

// YES: en az bir bağlı saate teslim için verildi (ulaştığı anlamına gelmez).
- (BOOL)publish:(NSDictionary *)message {
  NSDictionary *safe = [self watchSafe:message];
  self.lastMessage = safe;
  if (self.devices.count == 0) {
    // Saat seçilmemiş: SDK başlatılmaz, Bluetooth izni sorulmaz.
    return NO;
  }
  [self ensureStarted];
  BOOL any = NO;
  for (IQDevice *device in self.devices.allValues) {
    if ([[ConnectIQ sharedInstance] getDeviceStatus:device] != IQDeviceStatus_Connected) {
      continue;
    }
    any = YES;
    [self send:safe to:device];
  }
  return any;
}

// Monkey C NSNumber bool'u Char olarak alabilir; `ok` 1/0 tamsayı gider.
- (NSDictionary *)watchSafe:(NSDictionary *)message {
  id ok = message[@"ok"];
  if (ok == nil || CFGetTypeID((__bridge CFTypeRef)ok) != CFBooleanGetTypeID()) {
    return [message copy];
  }
  NSMutableDictionary *copy = [message mutableCopy];
  copy[@"ok"] = [ok boolValue] ? @1 : @0;
  return [copy copy];
}

- (void)send:(NSDictionary *)message to:(IQDevice *)device {
  IQApp *app = [self appOn:device];
  // isTransient:YES: yalnızca son durum önemli; saat kapalıyken mesajlar
  // posta kutusunda birikmez.
  [[ConnectIQ sharedInstance] sendMessage:message
      toApp:app
      progress:^(uint32_t sentBytes, uint32_t totalBytes) {
        // İlerleme kullanılmaz.
      }
      completion:^(IQSendMessageResult result) {
        // Saat uygulaması kurulu değil veya kapalı: sessiz.
        // Telefon her dakika yeniden gönderir.
      }
      isTransient:YES];
}

- (IQApp *)appOn:(IQDevice *)device {
  // storeUuid uygulama kimliğini tekrar kullanır: mağaza / uygulama durumu
  // API'leri (getAppStatus, showAppStore) kullanılmıyor.
  return [IQApp appWithUUID:self.watchAppUUID storeUuid:self.watchAppUUID device:device];
}

#pragma mark - Garmin Connect dönüşü

// Sahnesiz iskelette soğuk açılış: adres launchOptions içinde gelir. YES:
// NO dönmek uygulamanın açılışını Flutter'da başarısız sayar. UIKit aynı
// adresi ayrıca openURL ile de iletebilir; ikinci ayrıştırma aynı listeyi
// yeniden yazar, zararsızdır.
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  id url = launchOptions[UIApplicationLaunchOptionsURLKey];
  if ([url isKindOfClass:[NSURL class]]) {
    [self handleURL:url];
  }
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  return [self handleURL:url];
}

// FlutterSceneLifeCycleDelegate (UIScene kullanan iskelet), soğuk açılış:
// adres bağlantı seçeneklerinde gelir. Eklenti geç kaydolsa da Flutter
// (3.47) saklı bağlantı seçeneklerini motor sahneye bağlanınca yeniden
// iletir. Garmin Connect dönüşünü işlediyse YES döner: aksi halde Flutter
// derin bağlantısı (Info.plist'te kapatılmadıkça açık) `sniperturk-ciq://`
// adresini sayfa yolu olarak açmaya çalışır ve bulamayınca iOS'a geri
// atar. Bizden önce kaydolan eklentiler seçenekleri zaten almıştır; başka
// adres yoksa NO döner, seçenekler sonrakilere de ulaşır.
// Protokol bildirilmez (eski Flutter'da yoktur); imza Flutter'ınkiyle aynı.
- (BOOL)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  BOOL handled = NO;
  for (UIOpenURLContext *context in connectionOptions.URLContexts) {
    handled = [self handleURL:context.URL] || handled;
  }
  return handled;
}

// FlutterSceneLifeCycleDelegate (UIScene kullanan iskelet), açıkken dönüş.
- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
  BOOL handled = NO;
  for (UIOpenURLContext *context in URLContexts) {
    handled = [self handleURL:context.URL] || handled;
  }
  return handled;
}

// Şemamızdaki her adres için YES (ayrıştırılamasa bile): Flutter derin
// bağlantısı onu sayfa yolu olarak açmaya çalışmasın.
- (BOOL)handleURL:(NSURL *)url {
  if (![url.scheme.lowercaseString isEqualToString:kURLScheme]) {
    return NO;
  }
  // Ayrıştırmadan önce SDK başlatılmış olmalı.
  [self ensureStarted];
  NSArray *selected = [[ConnectIQ sharedInstance] parseDeviceSelectionResponseFromURL:url];
  if (selected == nil) {
    return YES;
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
  // Zaten bağlı saatlere son çözüm hemen gider (bağlantı olayı beklenmez).
  NSDictionary *last = self.lastMessage;
  if (last != nil) {
    for (IQDevice *device in self.devices.allValues) {
      if ([[ConnectIQ sharedInstance] getDeviceStatus:device] == IQDeviceStatus_Connected) {
        [self send:last to:device];
      }
    }
  }
  [self emitDeviceCount];
  return YES;
}

#pragma mark - Saat sayısı olayları (FlutterStreamHandler)

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  self.devicesSink = events;
  [self emitDeviceCount];
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  self.devicesSink = nil;
  return nil;
}

- (void)emitDeviceCount {
  NSNumber *count = @(self.devices.count);
  dispatch_async(dispatch_get_main_queue(), ^{
    FlutterEventSink sink = self.devicesSink;
    if (sink != nil) {
      sink(count);
    }
  });
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
