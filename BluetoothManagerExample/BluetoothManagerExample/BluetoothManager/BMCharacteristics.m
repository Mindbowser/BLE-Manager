//
//  BMCharacteristics.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 23/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "BMCharacteristics.h"
#import "CBUUID+String.h"
@implementation BMCharacteristics


- (instancetype)initWithCharacteristic:(CBCharacteristic *)aCharacteristic
{
    if (self = [super init]) {
        _cbCharacteristic = aCharacteristic;
    }
    return self;
}

- (NSMutableArray *)notifyOperationStack
{
    if (!_notifyOperationArray) {
        _notifyOperationArray = [NSMutableArray new];
    }
    return _notifyOperationArray;
}

- (NSMutableArray *)readOperationStack
{
    if (!_readOperationArray) {
        _readOperationArray = [NSMutableArray new];
    }
    return _readOperationArray;
}

- (NSMutableArray *)writeOperationStack
{
    if (!_writeOperationArray) {
        _writeOperationArray = [NSMutableArray new];
    }
    return _writeOperationArray;
}

- (NSString *)UUIDString
{
    return [self.cbCharacteristic.UUID representativeString];
}

- (void)setNotifyValue:(BOOL)notifyValue
            completion:(characteristicNotifyCallback)aCallback
{
    [self setNotifyValue:notifyValue completion:aCallback onUpdate:nil];
}

- (void)setNotifyValue:(BOOL)notifyValue
            completion:(characteristicNotifyCallback)aCallback
              onUpdate:(characteristicReadCallback)uCallback
{
    if (!aCallback) {
        aCallback = ^(NSError *error){};
    }
    
    self.updateCallback = uCallback;
    
    [self push:aCallback toArray:self.notifyOperationStack];
    
    [self.cbCharacteristic.service.peripheral setNotifyValue:notifyValue
                                           forCharacteristic:self.cbCharacteristic];
}

- (void)writeValue:(NSData *)data
        completion:(characteristicWriteCallback)aCallback
{
    CBCharacteristicWriteType type =  aCallback ?
    CBCharacteristicWriteWithResponse : CBCharacteristicWriteWithoutResponse;
    
    if (aCallback) {
        [self push:aCallback toArray:self.writeOperationStack];
    }
    [self.cbCharacteristic.service.peripheral writeValue:data
                                       forCharacteristic:self.cbCharacteristic
                                                    type:type];
}

- (void)writeByte:(int8_t)aByte
       completion:(characteristicWriteCallback)aCallback
{
    [self writeValue:[NSData dataWithBytes:&aByte length:1] completion:aCallback];
}

- (void)readValueWithBlock:(characteristicReadCallback)aCallback
{
    if (!aCallback) {
        return;
    }
    [self push:aCallback toArray:self.readOperationStack];
    [self.cbCharacteristic.service.peripheral readValueForCharacteristic:self.cbCharacteristic];
}

- (void)push:(id)anObject toArray:(NSMutableArray *)aArray
{
    [aArray addObject:anObject];
}

- (id)popFromArray:(NSMutableArray *)aArray
{
    id arrayObject = nil;
    if ([aArray count] > 0) {
        arrayObject = [aArray objectAtIndex:0];
        [aArray removeObjectAtIndex:0];
    }
    return arrayObject;
}

#pragma mark - Handle responce

- (void)handleSetNotifiedWithError:(NSError *)anError
{
    NSLog(@"Characteristic - %@ notify changed with error - %@", self.cbCharacteristic.UUID, anError);
    characteristicNotifyCallback callback = [self popFromArray:self.notifyOperationArray];
    if (callback) {
        callback(anError);
    }
}

- (void)handleReadValue:(NSData *)aValue error:(NSError *)anError
{
    NSLog(@"Characteristic - %@ value - %s error - %@",self.cbCharacteristic.UUID, [aValue bytes], anError);
    
    if (self.updateCallback) {
        self.updateCallback(aValue, anError);
    }
    
    characteristicReadCallback callback = [self popFromArray:self.readOperationArray];
    if (callback) {
        callback(aValue, anError);
    }
}

- (void)handleWrittenValueWithError:(NSError *)anError
{
    NSLog(@"Characteristic - %@ wrote with error - %@", self.cbCharacteristic.UUID, anError);
    characteristicWriteCallback callback = [self popFromArray:self.writeOperationArray];
    if (callback) {
        callback(anError);
    }
}



@end
