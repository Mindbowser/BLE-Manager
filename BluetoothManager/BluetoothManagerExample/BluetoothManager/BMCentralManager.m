//
//  BMCentralManager.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 15/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "BMCentralManager.h"
#import "Utilities.h"
@implementation BMCentralManager

static BMCentralManager *sharedInstance = nil;

+ (BMCentralManager *)sharedInstance
{
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [BMCentralManager new];
        }
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _centralQueue = dispatch_queue_create("com.bluetooth.centralQueue", DISPATCH_QUEUE_SERIAL);
        _manager      = [[CBCentralManager alloc] initWithDelegate:self queue:self.centralQueue];
        _cbCentralManagerState = _manager.state;
        _scannedPeripheralsArray = [NSMutableArray new];
        _peripheralsCountToStop = NSUIntegerMax;

    }
    return self;
}


- (BOOL)isCentralReady
{
    return (self.manager.state == CBCentralManagerStatePoweredOn);
}

- (NSString *)centralNotReadyReason
{
    return [self stateresultMessage];
}

- (NSArray *)peripherals
{
    // Sorting Peripherals by RSSI values
    NSArray *sortedArray;
    sortedArray = [_scannedPeripheralsArray sortedArrayUsingComparator:^NSComparisonResult(BMPeripheral *a, BMPeripheral *b) {
        return a.RSSI < b.RSSI;
    }];
    return sortedArray;
}

+ (NSSet *)keyPathsForValuesCentralReady
{
    return [NSSet setWithObject:@"cbCentralManagerState"];
}

+ (NSSet *)keyPathsForValuesCentralNotReadyReason
{
    return [NSSet setWithObject:@"cbCentralManagerState"];
}

- (void)scanForPeripherals
{
    [self scanForPeripheralsWithServices:nil
                                 options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
}

- (void)stopScanForPeripherals
{
    self.scanning = NO;
    [self.manager stopScan];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(stopScanForPeripherals)
                                               object:nil];
    if (self.scanBlock) {
        self.scanBlock(self.peripherals);
    }
    self.scanBlock = nil;
}

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options
{
    [self.scannedPeripheralsArray removeAllObjects];
    self.scanning = YES;
    [self.manager scanForPeripheralsWithServices:serviceUUIDs
                                         options:options];
}

- (void)scanForPeripheralsByInterval:(NSUInteger)aScanInterval
                          completion:(centralManagerDiscoverPeripheralsCallback)aCallback
{
    [self scanForPeripheralsByInterval:aScanInterval
                              services:nil
                               options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}
                            completion:aCallback];
}

- (void)scanForPeripheralsByInterval:(NSUInteger)aScanInterval
                            services:(NSArray *)serviceUUIDs
                             options:(NSDictionary *)options
                          completion:(centralManagerDiscoverPeripheralsCallback)aCallback
{
    self.scanBlock = aCallback;
    [self scanForPeripheralsWithServices:serviceUUIDs
                                 options:options];
   
    [self performSelector:@selector(stopScanForPeripherals)
               withObject:nil
               afterDelay:aScanInterval];
}

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers
{
    return [self getPeripherals:[self.manager retrievePeripheralsWithIdentifiers:identifiers]];
}

- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDS
{
    return [self getPeripherals:[self.manager retrieveConnectedPeripheralsWithServices:serviceUUIDS]];
}

- (NSString *)stateresultMessage
{
    NSString *message = nil;
    switch (self.manager.state) {
        case CBCentralManagerStateUnsupported:
            message = @"The hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            message = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnknown:
            message = @"Central not initialized yet.";
            break;
        case CBCentralManagerStatePoweredOff:
            message = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            break;
        default:
            break;
    }
    return message;
}

- (BMPeripheral *)wrapperByPeripheral:(CBPeripheral *)aPeripheral
{
    BMPeripheral *objPeripheral = nil;
    for (BMPeripheral *scanned in self.scannedPeripheralsArray) {
        if (scanned.cbPeripheral == aPeripheral) {
            objPeripheral = scanned;
            break;
        }
    }
    if (!objPeripheral) {
        objPeripheral = [[BMPeripheral alloc] initWithPeripheral:aPeripheral manager:self];
        [self.scannedPeripheralsArray addObject:objPeripheral];
    }
    return objPeripheral;
}

- (NSArray *)getPeripherals:(NSArray *)peripherals
{
    NSMutableArray *peripheralsArray = [NSMutableArray new];
    
    for (CBPeripheral *peripheral in peripherals) {
        [peripheralsArray addObject:[self wrapperByPeripheral:peripheral]];
    }
    return peripheralsArray;
}


#pragma mark - Central Manager Delegate
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self wrapperByPeripheral:peripheral] handleConnectionWithError:nil];
    });
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self wrapperByPeripheral:peripheral] handleConnectionWithError:error];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BMPeripheral *objPeripheral = [self wrapperByPeripheral:peripheral];
        [objPeripheral handleDisconnectWithError:error];
       
    });
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    self.cbCentralManagerState = central.state;
    NSString *message = [self stateresultMessage];
        if (message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", message);
        });
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BMPeripheral *objPeripheral = [self wrapperByPeripheral:peripheral];
        if (!objPeripheral.RSSI) {
            objPeripheral.RSSI = [RSSI integerValue];
        } else {
            // Calculating average RSSI
            objPeripheral.RSSI = (objPeripheral.RSSI + [RSSI integerValue]) / 2;
        }
        objPeripheral.advertisingDataDict = advertisementData;
        
        if ([self.scannedPeripheralsArray count] >= self.peripheralsCountToStop) {
            
            [self stopScanForPeripherals];
        }
    });
}






@end
