#ifndef BLECentralPlugin_h
#define BLECentralPlugin_h

#import <Cordova/CDV.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "ConnectionData.h"
#import "StreamDelegate.h"

@interface BluetoothClassicPlugin : CDVPlugin <EAAccessoryDelegate, NSStreamDelegate>

- (void)connect: (CDVInvokedUrlCommand*)command;
- (void)write: (CDVInvokedUrlCommand*)command;
- (void)read: (CDVInvokedUrlCommand*)command;

@property (nonatomic, strong) NSMutableArray*       activeConnections;
@property (nonatomic, strong) NSMutableDictionary*       callbackDictionary;

@end

#endif
