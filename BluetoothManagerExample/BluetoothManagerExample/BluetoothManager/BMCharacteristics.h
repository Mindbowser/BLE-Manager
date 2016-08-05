//
//  BMCharacteristics.h
//  BluetoothManagerExample
//
//  Created by Mindbowser on 23/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BMCharacteristics : NSObject
typedef void (^characteristicReadCallback)  (NSData *data, NSError *error);
typedef void (^characteristicNotifyCallback)(NSError *error);
typedef void (^characteristicWriteCallback) (NSError *error);


@property (strong, nonatomic, readonly) CBCharacteristic *cbCharacteristic;

@property (weak, nonatomic, readonly) NSString *UUIDString;
@property (strong, nonatomic) NSMutableArray *notifyOperationArray;

@property (strong, nonatomic) NSMutableArray *readOperationArray;

@property (strong, nonatomic) NSMutableArray *writeOperationArray;

@property (strong, nonatomic) characteristicReadCallback updateCallback;

- (instancetype)initWithCharacteristic:(CBCharacteristic *)aCharacteristic;

- (void)setNotifyValue:(BOOL)notifyValue
            completion:(characteristicNotifyCallback)aCallback;

- (void)setNotifyValue:(BOOL)notifyValue
            completion:(characteristicNotifyCallback)aCallback
              onUpdate:(characteristicReadCallback)uCallback;

- (void)writeValue:(NSData *)data
        completion:(characteristicWriteCallback)aCallback;

- (void)writeByte:(int8_t)aByte
       completion:(characteristicWriteCallback)aCallback;

- (void)readValueWithBlock:(characteristicReadCallback)aCallback;

- (void)handleSetNotifiedWithError:(NSError *)anError;

- (void)handleReadValue:(NSData *)aValue error:(NSError *)anError;

- (void)handleWrittenValueWithError:(NSError *)anError;


@end
