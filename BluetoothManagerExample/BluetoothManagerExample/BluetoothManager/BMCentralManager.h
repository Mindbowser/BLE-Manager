//
//  BMCentralManager.h
//  BluetoothManagerExample
//
//  Created by Mindbowser on 15/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BMPeripheral.h"
@class CBCentralManager;


typedef void (^centralManagerDiscoverPeripheralsCallback) (NSArray *peripherals);

@interface BMCentralManager : NSObject<CBCentralManagerDelegate>

@property (nonatomic, getter = isScanning) BOOL scanning;

@property (assign, nonatomic, readonly, getter = isCentralReady) BOOL centralReady;

@property (weak, nonatomic, readonly) NSString *centralNotReadyReason;

@property (weak, nonatomic, readonly) NSArray *peripherals;

@property (strong, nonatomic, readonly) CBCentralManager *manager;

@property (assign, nonatomic) NSUInteger peripheralsCountToStop;

@property (strong, nonatomic) dispatch_queue_t centralQueue;

@property (strong, nonatomic) NSMutableArray *scannedPeripheralsArray;

@property (copy, nonatomic) centralManagerDiscoverPeripheralsCallback scanBlock;

@property(nonatomic) CBCentralManagerState cbCentralManagerState;

+ (BMCentralManager *)sharedInstance;

+ (NSSet *)keyPathsForValuesCentralReady;

+ (NSSet *)keyPathsForValuesCentralNotReadyReason;

- (void)scanForPeripherals;

- (void)scanForPeripheralsWithServices:(NSArray *)serviceUUIDs
                               options:(NSDictionary *)options;

- (void)scanForPeripheralsByInterval:(NSUInteger)aScanInterval
                          completion:(centralManagerDiscoverPeripheralsCallback)aCallback;

- (void)scanForPeripheralsByInterval:(NSUInteger)aScanInterval
                            services:(NSArray *)serviceUUIDs
                             options:(NSDictionary *)options
                          completion:(centralManagerDiscoverPeripheralsCallback)aCallback;

- (void)stopScanForPeripherals;

- (NSArray *)retrievePeripheralsWithIdentifiers:(NSArray *)identifiers;
- (NSArray *)retrieveConnectedPeripheralsWithServices:(NSArray *)serviceUUIDS;

@end
