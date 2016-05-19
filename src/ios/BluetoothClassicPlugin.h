#ifndef BLECentralPlugin_h
#define BLECentralPlugin_h

#import <Cordova/CDV.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface BluetoothClassicPlugin : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate>

- (void)connect: (CDVInvokedUrlCommand*)command;
- (void)write: (CDVInvokedUrlCommand*)command;
- (void)read: (CDVInvokedUrlCommand*)command;
- (void)disconnect: (CDVInvokedUrlCommand*)command;
@end

#endif
