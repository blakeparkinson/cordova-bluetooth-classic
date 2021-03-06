#import "BluetoothClassicPlugin.h"
#import <Cordova/CDV.h>

@interface BluetoothClassicPlugin (){
        uint8_t*   rxBuffer;
        uint32_t rxBytes;
        bool connected;
}

@property (nonatomic, strong) CDVInvokedUrlCommand* connectCallback;
@property (nonatomic, strong) CDVInvokedUrlCommand* pickerCallback;

@end

@implementation BluetoothClassicPlugin
- (void)pluginInitialize {
        NSLog(@"Cordova Bluetooth Classic Plugin");
        NSLog(@"(c)2016 Sam Musso");

        connected = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(connectNotification:)
         name:EAAccessoryDidConnectNotification
         object:[EAAccessoryManager sharedAccessoryManager]];

        [[NSNotificationCenter defaultCenter] addObserver:self
         selector:@selector(disconnectNotification:)
         name:EAAccessoryDidDisconnectNotification
         object:[EAAccessoryManager sharedAccessoryManager]];

        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];



        _activeConnections = [[NSMutableArray alloc] init];
        _callbackDictionary = [[NSMutableDictionary alloc] init];

        [super pluginInitialize];
}

- (void)onAppTerminate {
        free(rxBuffer);
}

- (void)connectNotification:(NSNotification *)notification {
        NSLog(@"Received an EAAccessory connection notification");
        // [self connectToAccessoryMulti];
}

- (void)disconnectNotification:(NSNotification *)notification {
        NSLog(@"Received an EAAcessory disconnection notification");
        EAAccessory* accessory = [notification.userInfo objectForKey:EAAccessoryKey];
        for(ConnectionData* cd in _activeConnections) {
                if([cd.btAccessory.serialNumber isEqualToString:accessory.serialNumber]) {
                        [_activeConnections removeObject:cd];
                        NSLog(@"Sucessfully removed accessory %@ from active connections list", accessory.serialNumber);
                        CDVPluginResult *pluginResult = nil;
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:cd.connectCallback.callbackId];
                }
        }
}

- (BOOL)isNewAccessory:(EAAccessory *)btAcc {
        BOOL isNew = YES;
        for (ConnectionData *obj in _activeConnections) {
                if(obj.btAccessory == btAcc) {
                        isNew = NO;
                }
        }
        return isNew;
}

- (NSString *)serialToMAC:(NSString *)serial {
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

        for(ConnectionData* cd in _activeConnections) {
                if([cd.btMAC isEqualToString:[command.arguments objectAtIndex:0]]) {
                        CDVPluginResult *pluginResult = nil;
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        return;
                }
        }

        [_callbackDictionary setObject:command forKey:[command.arguments objectAtIndex:0] ];
        _connectCallback = command;
        [self connectToAccessoryMulti];
}

//return connection status
- (void)isConnected:(CDVInvokedUrlCommand*)command {
        NSString* mac = [command.arguments objectAtIndex:0];

        CDVPluginResult *pluginResult = nil;

        bool isConnected = NO;

        for (ConnectionData *cd in _activeConnections) {

                if([cd.btMAC isEqualToString:mac]) {
                        isConnected = YES;
                }
        }

        if(isConnected) {
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

        NSString* mac = [command.arguments objectAtIndex:0];

        for (ConnectionData *cd in _activeConnections) {
                if([cd.btMAC isEqualToString:mac]) {
                        if(cd.btBuffer != nil) {
                                NSData *data = [NSData dataWithData:cd.btBuffer];
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:data];
                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }else{
                                // There is no data, handle it
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }

                        cd.btBuffer = nil;
                        return;
                }
        }

        // If we get down here then we didn't find the device
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect: (CDVInvokedUrlCommand*)command {
        CDVPluginResult *pluginResult = nil;

        // [[_dataSession inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        // [[_dataSession inputStream] setDelegate:nil];
        // [[_dataSession inputStream] close];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)showPicker: (CDVInvokedUrlCommand*)command {
        // CDVPluginResult *pluginResult = nil;

        _pickerCallback = command;

        EABluetoothAccessoryPickerCompletion pickerResult = ^void (NSError *error){
                CDVPluginResult *pluginResult = nil;
                if(error == nil) { // no error
                  [self connectToAccessoryMulti];
                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                }else{
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                }
                [self.commandDelegate sendPluginResult:pluginResult callbackId:_pickerCallback.callbackId];
        };

        [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:pickerResult];

        // pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        // [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)connectToAccessoryMulti {
        NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                                connectedAccessories];
        NSString *protocolString = @"com.alpinelabs.pulse";
        EAAccessory *accessory = nil;

        // search for accessory supporting our protocol
        for (EAAccessory *obj in accessories) {
                if ([[obj protocolStrings] containsObject:protocolString]) {
                        // Need to make sure we have not already connected to this accessory
                        if([self isNewAccessory:obj]) {
                                // Need to do more checking to see if this is a valid serial number
                                accessory = obj;
                                break;
                        }
                }
        }

        if(accessory) { // This is a new accessory i.e. not in the dictionary
                NSLog(@"New accessory found. Serial number: %@", accessory.serialNumber);

                NSString *macAddress = [ self serialToMAC:accessory.serialNumber ];
                NSLog(@"MAC from serial is: %@", macAddress);

                ConnectionData *cd = [[ConnectionData alloc] init];
                cd.btMAC = macAddress;
                cd.btAccessory = accessory;

                cd.btStreamHandler = [[StreamDelegate alloc] init];
                cd.btStreamHandler.parent = cd;

                cd.btSession = [[EASession alloc] initWithAccessory:cd.btAccessory forProtocol:protocolString];

                if(cd.btSession) {
                        [[cd.btSession inputStream] setDelegate:cd.btStreamHandler];
                        [[cd.btSession inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                        [[cd.btSession inputStream] open];

                        cd.btBuffer = [[NSMutableData alloc] init];

                        [_activeConnections addObject:cd];

                        NSLog(@"Accessory %@ added to active connections list.", accessory.serialNumber);

                        // Need to grab the correct callback from the dictionary
                        cd.connectCallback = [_callbackDictionary objectForKey:cd.btMAC];

                        CDVPluginResult *pluginResult = nil;
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:cd.connectCallback.callbackId];

                        return;
                }
        }else{
                NSString* errorMessage = @"Need to show picker";
                CDVPluginResult *pluginResult = nil;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallback.callbackId];
        }
}

- (void)setConnectionStatus:(BOOL)connected {
}


// close the session with the accessory.
- (void)closeSession:(CDVInvokedUrlCommand *)command {
        for(ConnectionData* cd in _activeConnections) {
            [[cd.btSession inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[cd.btSession inputStream] close];
            [_activeConnections removeObject:cd];
        }

        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
