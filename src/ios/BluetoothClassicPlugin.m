@interface BluetoothClassicPlugin ()
{
    EASession* _dataSession;
    uint8_t _rxBuffer[1024 * 25];
    uint32_t _rxBytes;
}

- (void)pluginInitialize {
  NSLog(@"Cordova Bluetooth Classic Plugin");
  NSLog(@"(c)2016 Sam Musso");

  [super pluginInitialize];
}

- (void)connect: (CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult = nil;
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
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
