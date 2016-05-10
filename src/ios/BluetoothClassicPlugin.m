#import "BluetoothClassicPlugin.h"
#import <Cordova/CDV.h>

@interface BluetoothClassicPlugin(){
  uint8_t*   rxBuffer;
  uint32_t  rxBytes;
}

@property (nonatomic, strong) EASession     *dataSession;
@property (nonatomic, strong) NSMutableData *readData;

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

- (void)connect: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;
  [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:nil];

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

  NSData *data = [NSData dataWithData:_readData];
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

  _readData = nil;
}

- (void)readReceivedData{

  NSInteger bytesRead = [[_dataSession inputStream] read:rxBuffer maxLength:sizeof(rxBuffer)];

  if(_readData == nil){
    _readData = [[NSMutableData alloc] init];
  }

  [_readData appendBytes:(void *)_rxBuffer length:bytesRead];

  NSLOG(@"Buffered in %@ bytes", bytesRead);
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
