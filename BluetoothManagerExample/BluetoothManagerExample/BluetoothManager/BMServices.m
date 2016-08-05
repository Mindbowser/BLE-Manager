//
//  BMServices.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 23/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "BMServices.h"
#import "BMCharacteristics.h"
#import "CBUUID+String.h"
@implementation BMServices

- (instancetype)initWithService:(CBService *)aService
{
    if (self = [super init]) {
        _cbService = aService;
    }
    return self;
}


- (NSString *)UUIDString
{
    return [self.cbService.UUID representativeString];
}

- (void)discoverCharacteristicsWithCompletion:(serviceDiscoverCharacterisitcsCallback)aCallback
{
    [self discoverCharacteristicsWithUUIDs:nil
                                completion:aCallback];
}

- (void)discoverCharacteristicsWithUUIDs:(NSArray *)uuids
                              completion:(serviceDiscoverCharacterisitcsCallback)aCallback
{
    self.discoverCharacterisitcsBlock = aCallback;
    _discoveringCharacteristics = YES;
    [self.cbService.peripheral discoverCharacteristics:uuids
                                            forService:self.cbService];
}

- (BMCharacteristics *)wrapperByCharacteristic:(CBCharacteristic *)aChar
{
    BMCharacteristics *objCharacteristic = nil;
    for (BMCharacteristics *discovered in self.characteristics) {
        if (discovered.cbCharacteristic == aChar) {
            objCharacteristic = discovered;
            break;
        }
    }
    return objCharacteristic;
}
- (void)updateCharacteristics
{
    NSMutableArray *updatedCharacteristics = [NSMutableArray new];
    for (CBCharacteristic *characteristic in self.cbService.characteristics) {
        [updatedCharacteristics addObject:[[BMCharacteristics alloc] initWithCharacteristic:characteristic]];
    }
    _characteristics = updatedCharacteristics;
}

- (void)handleDiscoveredCharacteristics:(NSArray *)aCharacteristics error:(NSError *)aError
{
    _discoveringCharacteristics = NO;
    [self updateCharacteristics];
    for (BMCharacteristics *aChar in self.characteristics) {
        NSLog(@"Characteristic discovered - %@", aChar.cbCharacteristic.UUID);
        
    }

    if (self.discoverCharacterisitcsBlock) {
        self.discoverCharacterisitcsBlock(self.characteristics, aError);
    }
    self.discoverCharacterisitcsBlock = nil;
}


@end
