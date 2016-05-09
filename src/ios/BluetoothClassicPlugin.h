#ifndef BLECentralPlugin_h
#define BLECentralPlugin_h

#import <Cordova/CDV.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface BluetoothClassicPlugin : CDVPlugin <CBCentralManagerDelegate, CBPeripheralDelegate, DFUOperationsDelegate>{

}

- (void)connect: (CDVInvokedUrlCommand*)command;
- (void)write: (CDVInvokedUrlCommand*)command;
- (void)read: (CDVInvokedUrlCommand*)command;

#endif
