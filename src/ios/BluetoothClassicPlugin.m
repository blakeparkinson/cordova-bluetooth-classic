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

- (NSString *)serialToMAC:(NSString *)serial{
    NSMutableString *MAC = [NSMutableString stringWithString:@"00:02:"];
    NSMutableString *reversedSerial = [NSMutableString stringWithCapacity:[serial length]];

    [serial enumerateSubstringsInRange:NSMakeRange(0,[serial length])
                               options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                [reversedSerial appendString:substring];
                            }];

    [MAC appendString:reversedSerial];
    [MAC insertString: @":" atIndex:8];
    [MAC insertString: @":" atIndex:11];
    [MAC insertString: @":" atIndex:14];

    return (NSString *)[MAC copy];
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
        EAAccessory* accessory = [notification.userInfo objectForKey:EAAccessoryKey];
        for(ConnectionData* cd in _activeConnections){
            if([cd.btAccessory.serialNumber isEqualToString:accessory.serialNumber]){
                [_activeConnections removeObject:cd];
                NSLog(@"Sucessfully removed accessory %@ from active connections list", accessory.serialNumber);
            }
        }
        // CDVPluginResult *pluginResult = nil;
        // pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        // [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];
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
            if([self isNewAccessory:obj]){
                // Need to do more checking to see if this is a valid serial number
                accessory = obj;
                break;
            }
        }
    }

    if(accessory){ // This is a new accessory i.e. not in the dictionary
        NSLog(@"New accessory found. Serial number: %@", accessory.serialNumber);
        NSString *macAddress = [ self serialToMAC:accessory.serialNumber ];

        NSLog(@"MAC from serial is: %@", macAddress);

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

            // Need to grab the correct callback from the dictionary
            // CDVPluginResult *pluginResult = nil;
            // pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            // [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];

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
