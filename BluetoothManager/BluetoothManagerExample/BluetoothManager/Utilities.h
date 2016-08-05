//
//  Utilities.h
//  BluetoothManagerExample
//
//  Created by Mindbowser on 24/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BMCharacteristics.h"
@class BMPeripheral;
typedef void(^discoverCharacterisitcCallback)(BMCharacteristics *characteristic, NSError *error);

#pragma mark - Error Domains -

extern NSString * const kwriteErrorDomain;

extern NSString * const kerrorMessageKey;

extern const NSInteger kmissingServiceErrorCode;

extern const NSInteger kmissingCharacteristicErrorCode;

extern NSString * const kmissingServiceErrorMessage;

extern NSString * const kmissingCharacteristicErrorMessage;


@interface Utilities : NSObject

+ (void)writeData:(NSData *)aData
      charactUUID:(NSString *)aCharacteristic
      serviceUUID:(NSString *)aService
       peripheral:(BMPeripheral *)aPeripheral
       completion:(characteristicWriteCallback)aCallback;

+ (void)readDataFromCharactUUID:(NSString *)aCharacteristic
                    serviceUUID:(NSString *)aService
                     peripheral:(BMPeripheral *)aPeripheral
                     completion:(characteristicReadCallback)aCallback;


+ (void)discoverCharactUUID:(NSString *)aCharacteristic
                serviceUUID:(NSString *)aService
                 peripheral:(BMPeripheral *)aPeripheral
                 completion:(discoverCharacterisitcCallback)aCallback;

@end
