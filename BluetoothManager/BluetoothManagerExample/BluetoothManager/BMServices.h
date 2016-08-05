//
//  BMServices.h
//  BluetoothManagerExample
//
//  Created by Mindbowser on 23/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class CBCharacteristic;
@class CBService;
@class CBPeripheral;
@class BMCharacteristics;

typedef void(^serviceDiscoverCharacterisitcsCallback)(NSArray *characteristics, NSError *error);
@interface BMServices : NSObject

@property (strong, nonatomic, readonly) CBService *cbService;

@property (weak, nonatomic, readonly) CBPeripheral *cbPeripheral;

@property (weak, nonatomic, readonly) NSString *UUIDString;

@property (assign, nonatomic, readonly, getter = isDiscoveringCharacteristics) BOOL discoveringCharacteristics;

@property (strong, nonatomic) NSArray *characteristics;
@property (copy, nonatomic) serviceDiscoverCharacterisitcsCallback discoverCharacterisitcsBlock;


- (instancetype)initWithService:(CBService *)aService;

- (void)discoverCharacteristicsWithCompletion:(serviceDiscoverCharacterisitcsCallback)aCallback;

- (void)discoverCharacteristicsWithUUIDs:(NSArray *)uuids
                              completion:(serviceDiscoverCharacterisitcsCallback)aCallback;

- (void)handleDiscoveredCharacteristics:(NSArray *)aCharacteristics error:(NSError *)aError;

- (BMCharacteristics *)wrapperByCharacteristic:(CBCharacteristic *)aChar;



@end
