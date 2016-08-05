//
//  ViewController.m
//  BluetoothManagerExample
//
//  Created by Mindbowser on 15/07/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

#import "ViewController.h"
#import "BMCentralManager.h"
#import "BMPeripheral.h"
#import "BMServices.h"
#import "BMCharacteristics.h"
#import "Utilities.h"


@interface ViewController ()
{
    BMPeripheral *testPeripheral;
    IBOutlet UILabel *peripheralStatusLabel;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    peripheralStatusLabel.text = @"Disconnected";

    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)StartscanbuttonClick:(UIButton *)sender
{
    [[BMCentralManager sharedInstance] scanForPeripheralsByInterval:2
                                                         completion:^(NSArray *peripherals)
     {
         if (peripherals.count) {
             [self selectPeripheralforConnection:peripherals[0]];
         }
     }];
    
}

- (void)selectPeripheralforConnection:(BMPeripheral*)peripheral
{
    //  connecting to peripheral
    [peripheral connectWithCompletion:^(NSError *error) {
        
        testPeripheral = peripheral;
        peripheralStatusLabel.text = @"Connected";
        // Discovering services of peripheral
        [peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
            for (BMServices *service in services) {
                // Finding out specific service
                if ([service.UUIDString isEqualToString:@"FFC"]) {
                    // Discovering characteristics of  service
                    [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                        
                        for (BMCharacteristics *charact in characteristics) {
                            // FFC3 is a writabble characteristic, lets test writting
                            if ([charact.UUIDString isEqualToString:@"FFC3"]) {
                                [charact writeByte:0xAA completion:^(NSError *error) {
                                    NSLog(@"Error:%@",[error localizedDescription]);
                                }];
                            } else {
                                [charact readValueWithBlock:^(NSData *data, NSError *error) {
                                    
                                    NSLog(@"Read Data:%@",data);
                                }];
                            }
                        }
                    }];
                }
            }
        }];
    }];
}

-(IBAction)disConnectButtonClick:(id)sender {
    
    if (testPeripheral.isConnected == YES) {
        [testPeripheral disconnectWithCompletion:nil];
    }
    peripheralStatusLabel.text = @"Disconnected";

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
