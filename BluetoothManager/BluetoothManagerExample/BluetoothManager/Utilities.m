//
//  Utilities.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 24/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "Utilities.h"
#import "BMServices.h"
#import "BMPeripheral.h"

NSString * const kwriteErrorDomain = @"writeErrorDomain";

NSString * const kreadErrorDomain = @"readErrorDomain";

NSString * const kdiscoverErrorDomain = @"discoverErrorDomain";

NSString * const kerrorMessageKey = @"msg";

const NSInteger kmissingServiceErrorCode = 410;

const NSInteger kmissingCharacteristicErrorCode = 411;

NSString * const kmissingServiceErrorMessage = @"Provided service UUID doesn't exist in pheripheral";

NSString * const kmissingCharacteristicErrorMessage = @"Provided characteristic doesn't exist in service";;

const NSInteger kperipheralConnectionTimeoutInterval = 30;


@implementation Utilities

+ (void)writeData:(NSData *)aData
      charactUUID:(NSString *)aCharacteristic
      serviceUUID:(NSString *)aService
       peripheral:(BMPeripheral *)aPeripheral
       completion:(characteristicWriteCallback)aCallback
{
    if (aPeripheral.cbPeripheral.state == CBPeripheralStateConnected) {
        [self writeData:aData
            charactUUID:aCharacteristic
            serviceUUID:aService
        aPeripheral:aPeripheral
             completion:aCallback];
    } else {
        [aPeripheral connectWithTimeout:kperipheralConnectionTimeoutInterval completion:^(NSError *error) {
            [self writeData:aData
                charactUUID:aCharacteristic
                serviceUUID:aService
            aPeripheral:aPeripheral
                 completion:aCallback];
        }];
    }
}

+ (void)readDataFromCharactUUID:(NSString *)aCharacteristic
                    serviceUUID:(NSString *)aService
                     peripheral:(BMPeripheral *)aPeripheral
                     completion:(characteristicReadCallback)aCallback
{
    if (aPeripheral.cbPeripheral.state == CBPeripheralStateConnected) {
        [self readDataFromCharactUUID:aCharacteristic
                          serviceUUID:aService
                      aPeripheral:aPeripheral
                           completion:aCallback];
    } else {
        [aPeripheral connectWithTimeout:kperipheralConnectionTimeoutInterval completion:^(NSError *error) {
            [self readDataFromCharactUUID:aCharacteristic
                              serviceUUID:aService
                          aPeripheral:aPeripheral
                               completion:aCallback];
        }];
    }
}

+ (void)discoverCharactUUID:(NSString *)aCharacteristic
                serviceUUID:(NSString *)aService
                 peripheral:(BMPeripheral *)aPeripheral
                 completion:(discoverCharacterisitcCallback)aCallback
{
    if (aPeripheral.cbPeripheral.state == CBPeripheralStateConnected) {
        [self discoverCharactUUID:aCharacteristic
                      serviceUUID:aService
                  aPeripheral:aPeripheral
                       completion:aCallback];
    } else {
        [aPeripheral connectWithTimeout:kperipheralConnectionTimeoutInterval completion:^(NSError *error) {
            [self discoverCharactUUID:aCharacteristic
                          serviceUUID:aService
                      aPeripheral:aPeripheral
                           completion:aCallback];
        }];
    }
}

///
+ (void)writeData:(NSData *)aData
      charactUUID:(NSString *)aCharacteristic
      serviceUUID:(NSString *)aService
  aPeripheral:(BMPeripheral *)aPeripheral
       completion:(characteristicWriteCallback)aCallback;
{
    [aPeripheral discoverServices:@[[CBUUID UUIDWithString:aService]] completion:^(NSArray *services, NSError *error) {
        BMServices *service = nil;
        if (services.count && !error && (service = [self findServiceInList:services byUUID:aService])) {
            [service discoverCharacteristicsWithUUIDs:@[[CBUUID UUIDWithString:aCharacteristic]]
                                           completion:^(NSArray *characteristics, NSError *error)
             {
                 BMCharacteristics *characteristic = nil;
                 if (characteristics.count && (characteristic = [self findCharacteristicInList:characteristics byUUID:aCharacteristic])) {
                     [characteristic writeValue:aData completion:aCallback];
                 } else {
                     if (aCallback) {
                         if (!error) {
                             aCallback([Utilities writeErrorWithCode:kmissingCharacteristicErrorCode
                                                           message:kmissingCharacteristicErrorMessage]);
                         } else {
                             aCallback(error);
                         }
                     }
                     NSLog(@"Missing characteristic : %@ in service : %@", aCharacteristic, aService);
                 }
             }];
        } else {
            if (aCallback) {
                if (!error) {
                    aCallback([Utilities writeErrorWithCode:kmissingServiceErrorCode
                                                  message:kmissingServiceErrorMessage]);
                } else {
                    aCallback(error);
                }
            }
            NSLog(@"Missingservice : %@ in peripheral", aService);
        }
    }];
}

+ (void)readDataFromCharactUUID:(NSString *)aCharacteristic
                    serviceUUID:(NSString *)aService
                aPeripheral:(BMPeripheral *)aPeripheral
                     completion:(characteristicReadCallback)aCallback;
{
    [aPeripheral discoverServices:@[[CBUUID UUIDWithString:aService]] completion:^(NSArray *services, NSError *error) {
        if (services.count && !error) {
            BMServices *service = [self findServiceInList:services
                                                  byUUID:aService];
            [service discoverCharacteristicsWithUUIDs:@[[CBUUID UUIDWithString:aCharacteristic]] completion:^(NSArray *characteristics, NSError *error) {
                if (characteristics.count) {
                    BMCharacteristics *characteristic = [self findCharacteristicInList:characteristics
                                                                               byUUID:aCharacteristic];
                    [characteristic readValueWithBlock:aCallback];
                } else {
                    if (aCallback) {
                        if (!error) {
                            aCallback(nil, [Utilities readErrorWithCode:kmissingCharacteristicErrorCode
                                                              message:kmissingCharacteristicErrorMessage]);
                        } else {
                            aCallback(nil, error);
                        }
                    }
                }
            }];
        } else {
            if (aCallback) {
                if (!error) {
                    aCallback(nil, [Utilities readErrorWithCode:kmissingServiceErrorCode
                                                      message:kmissingServiceErrorMessage]);
                } else {
                    aCallback(nil, error);
                }
            }
            NSLog(@"Missing provided service : %@ in peripheral", aService);
        }
    }];
}

+ (void)discoverCharactUUID:(NSString *)aCharacteristic
                serviceUUID:(NSString *)aService
            aPeripheral:(BMPeripheral *)aPeripheral
                 completion:(discoverCharacterisitcCallback)aCallback
{
    [aPeripheral discoverServices:@[[CBUUID UUIDWithString:aService]] completion:^(NSArray *services, NSError *error) {
        if (services.count && !error) {
            BMServices *service = [self findServiceInList:services
                                                  byUUID:aService];
            [service discoverCharacteristicsWithUUIDs:@[[CBUUID UUIDWithString:aCharacteristic]] completion:^(NSArray *characteristics, NSError *error) {
                if (characteristics.count) {
                    BMCharacteristics *characteristic = [self findCharacteristicInList:characteristics
                                                                               byUUID:aCharacteristic];
                    if (aCallback) {
                        aCallback(characteristic, nil);
                    }
                } else {
                    if (aCallback) {
                        if (!error) {
                            aCallback(nil, [Utilities discoverErrorWithCode:kmissingCharacteristicErrorCode
                                                                  message:kmissingCharacteristicErrorMessage]);
                        } else {
                            aCallback(nil, error);
                        }
                    }
                }
            }];
        } else {
            if (aCallback) {
                if (!error) {
                    aCallback(nil, [Utilities discoverErrorWithCode:kmissingServiceErrorCode
                                                          message:kmissingServiceErrorMessage]);
                } else {
                    aCallback(nil, error);
                }
            }
            NSLog(@"Missing  service : %@ in peripheral", aService);
        }
    }];
}

+ (BMCharacteristics *)findCharacteristicInList:(NSArray *)characteristics
                                        byUUID:(NSString *)anID
{
    for (BMCharacteristics *characteristic in characteristics) {
        if ([[characteristic.UUIDString lowercaseString] isEqualToString:[anID lowercaseString]]) {
            return characteristic;
        }
    }
    return nil;
}

+ (BMServices *)findServiceInList:(NSArray *)services
                          byUUID:(NSString *)anID
{
    for (BMServices *service in services) {
        if ([[service.UUIDString lowercaseString] isEqualToString:[anID lowercaseString]]) {
            return service;
        }
    }
    return nil;
}

+ (NSError *)writeErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kwriteErrorDomain
                               code:aCode
                           userInfo:@{kerrorMessageKey : aMsg}];
}

+ (NSError *)readErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kreadErrorDomain
                               code:aCode
                           userInfo:@{kerrorMessageKey : aMsg}];
}

+ (NSError *)discoverErrorWithCode:(NSInteger)aCode message:(NSString *)aMsg
{
    return [NSError errorWithDomain:kdiscoverErrorDomain
                               code:aCode
                           userInfo:@{kerrorMessageKey : aMsg}];
}

@end
