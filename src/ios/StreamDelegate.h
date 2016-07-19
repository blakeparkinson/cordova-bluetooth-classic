#ifndef StreamDelegate_h
#define StreamDelegate_h

@class ConnectionData;

@interface StreamDelegate: NSStream <NSStreamDelegate>{
    uint8_t rxBuffer[2048];
    uint32_t rxBytes;
}

@property (nonatomic, strong) ConnectionData* parent;

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode;
- (void)bufferRXData;

@end

#endif
