#import "BluetoothClassicPlugin.h"
#import <Cordova/CDV.h>

@interface BluetoothClassicPlugin(){
  uint8_t*   rxBuffer;
  uint32_t  rxBytes;
}

@property (nonatomic, strong) EAAccessory*          myAccessory;
@property (nonatomic, strong) EASession*            dataSession;
@property (nonatomic, strong) NSMutableData*        readData;
@property (nonatomic, strong) NSMutableDictionary*  connectCallbacks;
@property (nonatomic, strong) NSMutableDictionary*  disconnectCallbacks;

@end

@implementation BluetoothClassicPlugin
- (void)pluginInitialize {
  NSLog(@"Cordova Bluetooth Classic Plugin");
  NSLog(@"(c)2016 Sam Musso");
  rxBuffer = (uint8_t*) malloc(1024 * 25);
  [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(accessoryNotification:)
                                               name:nil
                                             object:[EAAccessoryManager sharedAccessoryManager]];

  [super pluginInitialize];
}

- (void)onAppTerminate
{
    free(rxBuffer);
    _dataSession = nil;
    _readData = nil;
}

- (void)connect: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;

  [self connectToAccessory];

  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)write: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)read: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;

  if(_readData != nil){
    NSData *data = [NSData dataWithData:_readData];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }else{
      // We either have not received data. Possibly disconnected
  }

  _readData = nil;
}

- (void)disconnect: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;

  [[_dataSession inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [[_dataSession inputStream] setDelegate:nil];
  [[_dataSession inputStream] close];

 // _myAccessory = nil;
  _dataSession = nil;
 // _readData = nil;

  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)readReceivedData{

  NSInteger bytesRead = [[_dataSession inputStream] read:rxBuffer maxLength:(1024)];

  if(_readData == nil){
    _readData = [[NSMutableData alloc] init];
  }

  [_readData appendBytes:(void *)rxBuffer length:bytesRead];
    uint8_t *s = (uint8_t*)self.readData.bytes;

    NSString *debugString = [[NSString alloc] init];

    /*for(unsigned int i = 0; i < _readData.length; i++){
        debugString = [debugString stringByAppendingFormat:@"%02x", s[i]];
        debugString = [debugString stringByAppendingFormat:@""];
    }*/

    //NSLog(@"Data: %@", debugString);

  NSLog(@"Buffered in %zd bytes", bytesRead);
}

- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent{
  switch(streamEvent){
    case NSStreamEventHasBytesAvailable:
      [self readReceivedData];
      break;
    default:
      break;
  }
}

- (void)accessoryNotification:(NSNotification *)notification{
    // if accessory has connected try to open data session
    if ([[notification name] isEqualToString:@"EAAccessoryDidConnectNotification"])
        [self connectToAccessory];
    // if accessory has disconnected, tell user and release data session
    if ([[notification name] isEqualToString:@"EAAccessoryDidDisconnectNotification"]){
        [self setConnectionStatus:NO];
    }
}

- (void)connectToAccessory{

  NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
  NSString *protocolString = @"com.alpinelabs.pulse";
  EAAccessory *accessory = nil;

  // search for accessory supporting our protocol
  for (EAAccessory *obj in accessories){
      if ([[obj protocolStrings] containsObject:protocolString]){
          accessory = obj;
          break;
      }
  }
  // create data session if we found a matching accessory
  if (accessory){
      _myAccessory = accessory;
      _dataSession = [[EASession alloc] initWithAccessory:accessory
                                              forProtocol:protocolString];
      if (_dataSession){
          [[_dataSession inputStream] setDelegate:self];
          [[_dataSession inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                                  forMode:NSDefaultRunLoopMode];
          [[_dataSession inputStream] open];

          [self setConnectionStatus:YES];
      }else{
          [self setConnectionStatus:NO];
      }
  }else{
    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:nil];
    [self setConnectionStatus:NO];
  }
}

- (void)setConnectionStatus:(BOOL)connected{
  if(connected){
   // Report connection to plugin
  }else{
   // Report disconnection to plugin
  }
}

@end
