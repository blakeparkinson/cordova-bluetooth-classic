#import "BluetoothClassicPlugin.h"
#import <Cordova/CDV.h>

@interface BluetoothClassicPlugin(){
    bool connected;
}

@end

@implementation BluetoothClassicPlugin
- (void)pluginInitialize {
    NSLog(@"Cordova Bluetooth Classic Plugin");
    NSLog(@"(c)2016 Sam Musso");

    connected = NO;

    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accessoryNotification:)
                                                 name:nil
                                               object:[EAAccessoryManager sharedAccessoryManager]];

    _activeConnections = [[NSMutableArray alloc] init];

    [super pluginInitialize];
}

- (void)onAppTerminate{
    connected = NO;
}

- (void)connect: (CDVInvokedUrlCommand*)command {
    _timer = [NSTimer scheduledTimerWithTimeInterval: 30
                                              target: self
                                            selector:@selector(onTick:)
                                            userInfo: nil repeats:NO];

    _connectCallback = command;
    [self initialConnectToAccessory];
}

//return connection status
- (void)isConnected:(CDVInvokedUrlCommand*)command{

    CDVPluginResult *pluginResult = nil;

    if(connected){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

    }

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

- (void)accessoryNotification:(NSNotification *)notification{
    // if accessory has connected try to open data session
    if ([[notification name] isEqualToString:@"EAAccessoryDidConnectNotification"])
        [self connectToAccessoryMulti];
    // if accessory has disconnected, tell user and release data session
    if ([[notification name] isEqualToString:@"EAAccessoryDidDisconnectNotification"]){
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];
        [self setConnectionStatus:NO];
    }
}

- (BOOL)isNewAccessory:(EAAccessory *)btAcc{
    BOOL isNew = YES;
    for (EAAccessory *obj in _activeConnections){
        if(obj == btAcc){
            isNew = NO;
        }
    }
    return isNew;
}

- (void)connectToAccessoryMulti{
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
    NSString *protocolString = @"com.alpinelabs.pulse";
    EAAccessory *accessory = nil;

    // search for accessory supporting our protocol
    for (EAAccessory *obj in accessories){
        if ([[obj protocolStrings] containsObject:protocolString]){
            // Need to make sure we have not already connected to this accessory
            if([self isNewAccessory:obj])
                accessory = obj;
            break;
        }
    }

    if(accessory){ // This is a new accessory i.e. not in the dictionary
        NSLog(@"New accessory found. Serial number: %@", accessory.serialNumber);
        ConnectionData *cd = [[ConnectionData alloc] init];
        cd.btAccessory = accessory;
        cd.btStreamHandler = [[StreamDelegate alloc] init];
        cd.btStreamHandler.parent = cd;
        cd.btSession = [[EASession alloc] initWithAccessory:cd.btAccessory forProtocol:protocolString];

        if(cd.btSession){
            [[cd.btSession inputStream] setDelegate:cd.btStreamHandler];
            [[cd.btSession inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[cd.btSession inputStream] open];

            cd.btBuffer = [[NSMutableData alloc] init];

            [_activeConnections addObject:cd];

            NSLog(@"Accessory %@ added to active connections list.", accessory.serialNumber);

            CDVPluginResult *pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];

            return;
        }
    }

    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];
}

- (void)initialConnectToAccessory{
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

    if (accessory){
        [self connectToAccessoryMulti];
    }else {
        [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:nil];
        [self setConnectionStatus:NO];
    }

}

- (void)setConnectionStatus:(BOOL)status{
    connected = status;
}

- (void)onTick:(NSTimer*)t{
    if(connected == NO){
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];
    }
}

@end
