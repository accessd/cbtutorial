//
//  CBCentralManagerViewController.m
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import "CBCentralManagerViewController.h"

@implementation CBCentralManagerViewController


- (void)viewDidLoad {

    [super viewDidLoad];
     _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    

     _data = [[NSMutableData alloc] init];
}




- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        #define DEVICE_INFO_SERVICE_UUID @"384abbc5-9ad6-4eaa-86af-1ee629ba9838"
        
        NSDictionary    *options    = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:DEVICE_INFO_SERVICE_UUID]] options:options];
        
        NSLog(@"Scanning started");
    }
}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    //if (_discoveredPeripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        _discoveredPeripheral = peripheral;
        
        // And connect
        NSString* data = [NSString stringWithFormat:@"Connecting to peripheral %@", peripheral];
        NSLog(@"%@", data);
        
        [_textview setText:data];
        [_centralManager connectPeripheral:peripheral options:nil];

    
    //}
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    NSLog(@"peripheral");
    [_peripheralManager startAdvertising:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
//[self cleanup];
}


- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!_discoveredPeripheral.state == CBPeripheralStateConnected) {
        return;
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:_discoveredPeripheral];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    
    //[_centralManager stopScan];
    //NSLog(@"Scanning stopped");
    
    [_data setLength:0];
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
        return;
        
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Characteristic: %@", characteristic.UUID);
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            NSData * data=[NSData dataWithBytes:DOOR_OPEN_CODE length:strlen(DOOR_OPEN_CODE)];
        
            NSLog(@"Writing value for characteristic %@", characteristic);
            [_discoveredPeripheral writeValue:data forCharacteristic:characteristic
                          type:CBCharacteristicWriteWithResponse];
        
        
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
#define DEVICE_INFO_SERVICE_UUID @"384abbc5-9ad6-4eaa-86af-1ee629ba9838"
            
            NSDictionary    *options    = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            
            
                notification.alertBody = NSLocalizedString(@"You're inside the region", @"");
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

            [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:DEVICE_INFO_SERVICE_UUID]] options:options];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    if (error) {
        NSLog(@"characteristic %@", characteristic);
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [_centralManager stopScan];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
