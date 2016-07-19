#include "StreamDelegate.h"
#include "ConnectionData.h"

@implementation StreamDelegate
- (void)bufferRXData{
    // Grab the inputStream from the session in the ConnectionData
    // Read the bytes from it and put it in the buffer in the ConnectionData
    NSInteger bytesRead = [[_parent.btSession inputStream] read:rxBuffer maxLength:(2048)];
    [_parent.btBuffer appendBytes:(void *)rxBuffer length:bytesRead];

    NSLog(@"Buffered in %zd bytes from accessory %s", bytesRead, [_parent.btAccessory.serialNumber UTF8String]);
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode){
        case NSStreamEventHasBytesAvailable:
            [self bufferRXData];
            break;
        default:
            break;
    }
}
@end
