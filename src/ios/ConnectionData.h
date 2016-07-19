#ifndef ConnectionData_h
#define ConnectionData_h

@class StreamDelegate;

#import <ExternalAccessory/ExternalAccessory.h>
#import <Cordova/CDV.h>

@interface ConnectionData : NSObject{
    
}

@property (nonatomic, strong) EAAccessory*          btAccessory;
@property (nonatomic, strong) EASession*            btSession;
@property (nonatomic, strong) NSMutableData*        btBuffer;
@property (nonatomic, strong) StreamDelegate*       btStreamHandler;

@property (nonatomic, strong) CDVInvokedUrlCommand* connectCallback;
@property (nonatomic, strong) NSTimer*              connectTimer;

@end

#endif
