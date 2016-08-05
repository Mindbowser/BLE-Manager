//
//  BMPeripheral.h
//  BluetoothManagerExample
//
//  Created by Mindbowser on 15/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class BMCentralManager;
extern NSString * const kperipheralDidConnect;

extern NSString * const kperipheralDidDisconnect;

extern NSString * const kperipheralConnectionErrorDomain;

extern const NSInteger kconnectionTimeoutErrorCode;

extern const NSInteger kconnectionMissingErrorCode;

extern NSString * const kconnectionTimeoutErrorMessage;

extern NSString * const kconnectionMissingErrorMessage;

typedef void(^peripheralConnectionCallback)(NSError *error);
typedef void(^peripheralDiscoverServicesCallback)(NSArray *services, NSError *error);
typedef void(^peripheralRSSIValueCallback)(NSNumber *RSSI, NSError *error);

@interface BMPeripheral : NSObject<CBPeripheralDelegate>


@property (strong, nonatomic, readonly) CBPeripheral *cbPeripheral;

@property (weak, nonatomic, readonly) BMCentralManager *centralmanager;

@property (assign, nonatomic, readonly, getter = isDiscoveringServices) BOOL discoveringServices;

@property (strong, nonatomic, readonly) NSArray *services;


@property (weak, nonatomic, readonly) NSString *UUIDString;

@property (weak, nonatomic, readonly) NSString *name;


@property (assign, nonatomic, readonly) BOOL timeOutStarted;


@property (assign, nonatomic) NSInteger RSSI;


@property (strong, nonatomic) NSDictionary *advertisingDataDict;

@property (copy, atomic) peripheralConnectionCallback       connectionBlock;
@property (copy, atomic) peripheralConnectionCallback       disconnectBlock;
@property (copy, atomic) peripheralDiscoverServicesCallback discoverServicesBlock;
@property (copy, atomic) peripheralRSSIValueCallback        rssiValueBlock;

@property (readonly, nonatomic, getter = isConnected) BOOL connected;
- (void)connectWithCompletion:(peripheralConnectionCallback)aCallback;


- (void)connectWithTimeout:(NSUInteger)timeOutInterval
                completion:(peripheralConnectionCallback)aCallback;

- (void)disconnectWithCompletion:(peripheralConnectionCallback)aCallback;


- (void)discoverServicesWithCompletion:(peripheralDiscoverServicesCallback)aCallback;

- (void)discoverServices:(NSArray *)serviceUUIDs
              completion:(peripheralDiscoverServicesCallback)aCallback;


- (void)readRSSIValueCompletion:(peripheralRSSIValueCallback)aCallback;



- (void)handleConnectionWithError:(NSError *)anError;

- (void)handleDisconnectWithError:(NSError *)anError;


- (instancetype)initWithPeripheral:(CBPeripheral *)aPeripheral manager:(BMCentralManager *)manager;

@end
