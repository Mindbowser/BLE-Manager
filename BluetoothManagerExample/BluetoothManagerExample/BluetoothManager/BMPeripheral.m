//
//  BMPeripheral.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 15/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "BMPeripheral.h"
#import "BMCentralManager.h"
#import "Utilities.h"
#import "BMServices.h"
#import "BMCharacteristics.h"

NSString * const kperipheralDidConnect    = @"peripheralDidConnect";

NSString * const kperipheralDidDisconnect = @"peripheralDidDisconnect";
NSString * const kperipheralConnectionErrorDomain = @"peripheralConnectionErrorDomain";
const NSInteger kconnectionTimeoutErrorCode = 408;
const NSInteger kconnectionMissingErrorCode = 409;
NSString * const kconnectionTimeoutErrorMessage = @"BLE Device can't be connected by given interval";
NSString * const kconnectionMissingErrorMessage = @"BLE Device is not connected";


@implementation BMPeripheral


- (instancetype)initWithPeripheral:(CBPeripheral *)aPeripheral manager:(BMCentralManager *)manager
{
    if (self = [super init]) {
        _cbPeripheral = aPeripheral;
        _cbPeripheral.delegate = self;
        _centralmanager = manager;
    }
    return self;
}

- (BOOL)isConnected
{
    return (self.cbPeripheral.state == CBPeripheralStateConnected);
}

- (NSString *)UUIDString
{
    return [self.cbPeripheral.identifier UUIDString];
}

- (NSString *)name
{
    return [self.cbPeripheral name];
}

- (NSString *)description
{
    NSString *descriptionString = [super description];
    
    return [descriptionString stringByAppendingFormat:@" UUIDString: %@", self.UUIDString];
}

-(void)connectWithCompletion:(peripheralConnectionCallback)aCallback
{
    _timeOutStarted = NO;
    self.connectionBlock = aCallback;
    [self.centralmanager.manager connectPeripheral:self.cbPeripheral
                                    options:nil];
}

- (void)connectWithTimeout:(NSUInteger)timeOutInterval
                completion:(peripheralConnectionCallback)aCallback
{
    [self connectWithCompletion:aCallback];
    [self performSelector:@selector(connectionWatchFired)
               withObject:nil
               afterDelay:timeOutInterval];
}

- (void)disconnectWithCompletion:(peripheralConnectionCallback)aCallback
{
    self.disconnectBlock = aCallback;
    [self.centralmanager.manager cancelPeripheralConnection:self.cbPeripheral];
}

- (void)discoverServicesWithCompletion:(peripheralDiscoverServicesCallback)aCallback
{
    [self discoverServices:nil
                completion:aCallback];
}

- (void)discoverServices:(NSArray *)serviceUUIDs
              completion:(peripheralDiscoverServicesCallback)aCallback
{
    self.discoverServicesBlock = aCallback;
    if (self.isConnected) {
        _discoveringServices = YES;
        [self.cbPeripheral discoverServices:serviceUUIDs];
    } else if (self.discoverServicesBlock) {
        self.discoverServicesBlock(nil, [self connectionErrorWithCode:kconnectionMissingErrorCode
                                                              message:kconnectionMissingErrorMessage]);
        self.discoverServicesBlock = nil;
    }
}

- (void)readRSSIValueCompletion:(peripheralRSSIValueCallback)aCallback
{
    self.rssiValueBlock = aCallback;
    if (self.isConnected) {
        [self.cbPeripheral readRSSI];
    } else if (self.rssiValueBlock) {
        self.rssiValueBlock(nil, [self connectionErrorWithCode:kconnectionMissingErrorCode
                                                       message:kconnectionMissingErrorMessage]);
        self.rssiValueBlock = nil;
    }
}



- (void)handleConnectionWithError:(NSError *)anError
{
    // Connection was made, canceling watchdog
//    [NSObject cancelPreviousPerformRequestsWithTarget:self
//                                             selector:@selector(connectionWatchDogFired)
//                                               object:nil];
    NSLog(@"Connection with error - %@", anError);
    if (self.connectionBlock) {
        self.connectionBlock(anError);
    }
    self.connectionBlock = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kperipheralDidConnect
                                                        object:self
                                                      userInfo:@{@"error" : anError ? : [NSNull null]}];
}

- (void)handleDisconnectWithError:(NSError *)anError
{
    NSLog(@"Disconnect with error - %@", anError);
    if (self.disconnectBlock) {
        self.disconnectBlock(anError);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kperipheralDidDisconnect
                                                            object:self
                                                          userInfo:@{@"error" : anError ? : [NSNull null]}];
    }
    self.disconnectBlock = nil;
}



- (NSError *)connectionErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kperipheralConnectionErrorDomain
                               code:aCode
                           userInfo:@{kerrorMessageKey : aMsg}];
}



- (void)connectionWatchFired
{
    _timeOutStarted = YES;
    __weak BMPeripheral *weakSelf = self;
    [self disconnectWithCompletion:^(NSError *error) {
        __strong BMPeripheral *strongSelf = weakSelf;
        if (strongSelf.connectionBlock) {
            strongSelf.connectionBlock([self connectionErrorWithCode:kconnectionTimeoutErrorCode
                                                             message:kconnectionTimeoutErrorMessage]);
        }
        self.connectionBlock = nil;
    }];
}

- (void)updateServicesArray
{
    NSMutableArray *updatedServices = [NSMutableArray new];
    for (CBService *service in self.cbPeripheral.services) {
        [updatedServices addObject:[[BMServices alloc] initWithService:service]];
    }
    _services = updatedServices;
}

- (BMServices *)wrapperByService:(CBService *)aService
{
    BMServices *objService = nil;
    for (BMServices *discovered in self.services) {
        if (discovered.cbService == aService) {
            objService = discovered;
            break;
        }
    }
    return objService;
}

#pragma mark - CBPeripheral Delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _discoveringServices = NO;
        [self updateServicesArray];
        for (BMServices *aService in self.services) {
            NSLog(@"Service discovered - %@", aService.cbService.UUID);
        }
        
       if (self.discoverServicesBlock) {
            self.discoverServicesBlock(self.services, error);
        }
        self.discoverServicesBlock = nil;
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self wrapperByService:service] handleDiscoveredCharacteristics:service.characteristics
                                                                   error:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSData *value = [characteristic.value copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleReadValue:value error:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleSetNotifiedWithError:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self wrapperByService:characteristic.service]
          wrapperByCharacteristic:characteristic]
         handleWrittenValueWithError:error];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.rssiValueBlock) {
            self.rssiValueBlock(RSSI, error);
        }
        self.rssiValueBlock = nil;
    });
}


@end
