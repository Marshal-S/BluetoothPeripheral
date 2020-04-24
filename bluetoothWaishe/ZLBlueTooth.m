//
//  ZLBlueTooth.m
//  dakaDevice
//
//  Created by Marshal on 2020/4/15.
//  Copyright © 2020 Marshal. All rights reserved.
//

#import "ZLBlueTooth.h"
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *serviceUUID = @"11000000-0000-0000-0000-818282828282";
static NSString *characterUUID = @"12000000-0000-0000-0000-000000000000";
static NSString *writeCharacterUUID = @"13000000-0000-0000-0000-000000000000";

@interface ZLBlueTooth ()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *manager;

@property (nonatomic, strong) CBMutableCharacteristic *readWrite;
@property (nonatomic, strong) CBMutableCharacteristic *write;

@property (nonatomic, strong) NSMutableData *wifiData;
@property (nonatomic, strong) NSMutableString *wifiString;

@end

@implementation ZLBlueTooth

+ (instancetype)manager {
    ZLBlueTooth *instance = [[self alloc] init];
    instance.manager = [[CBPeripheralManager alloc] initWithDelegate:instance queue:nil];
    return instance;
}

- (void)reset {
    self.wifiData = [NSMutableData data];
    self.wifiString = [NSMutableString string];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            [self setup];
            break;
        case CBManagerStatePoweredOff:
            [self showAlertWithMessage:@"检测到蓝牙未打开！"];
            [self disConnect];
            break;
        case CBManagerStateUnauthorized: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"检测到未打开蓝牙权限" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:UIApplicationOpenSettingsURLString options:@{} completionHandler:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
            [self disConnect];
            break;
        }
        default: {
            [self showAlertWithMessage:@"蓝牙功能出现异常，请重新打开蓝牙，或者关闭应用尝试"];
            [self disConnect];
            break;
        }
    }
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    [self disConnect];
}

- (void)disConnect {
    if (!_manager) return;
    [_manager stopAdvertising];
    [_manager removeAllServices];
}

- (void)setup {
    _wifiData = [NSMutableData data];
    _wifiString = [NSMutableString string];
    //两个暂时都全能，兼容app端错误的操作方式，有利于操作
    _readWrite = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:characterUUID] properties:(CBCharacteristicPropertyIndicate | CBCharacteristicPropertyWriteWithoutResponse | CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite) value:nil permissions:(CBAttributePermissionsReadable | CBAttributePermissionsWriteable)];
    CBMutableDescriptor *readwriteCharacteristicDescription = [[CBMutableDescriptor alloc] initWithType: [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString] value:@"name"];
    _readWrite.descriptors = @[readwriteCharacteristicDescription];
    _write = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:writeCharacterUUID] properties:(CBCharacteristicPropertyIndicate | CBCharacteristicPropertyWriteWithoutResponse | CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead | CBCharacteristicPropertyWrite) value:nil permissions:(CBAttributePermissionsReadable | CBAttributePermissionsWriteable)];
    _write.descriptors = @[readwriteCharacteristicDescription];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:serviceUUID] primary:YES];
    service.characteristics = @[_readWrite, _write];
    [_manager addService:service];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error {
    if (error) return;
    [peripheral startAdvertising:@{
        CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:serviceUUID]],
        CBAdvertisementDataLocalNameKey: [@"😂😂😂_" stringByAppendingString:@"123456"]
    }];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error {
    NSLog(@"peripheralManagerDidStartAdvertising");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"didReceiveReadRequest: %@", request);
    NSData *data = request.characteristic.value;
    [request setValue:data];
           //对请求作出成功响应
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    [requests enumerateObjectsUsingBlock:^(CBATTRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //均支持写入操作
        if (obj.characteristic.properties & CBCharacteristicPropertyWrite) {
            [peripheral respondToRequest:obj withResult:CBATTErrorSuccess]; //返回成功标识，标识对面某个写入请求是否写入成功
        }
        if (!obj.value) return;
        if ([obj.characteristic.UUID.UUIDString isEqualToString:writeCharacterUUID]) {
            NSString *singleString = [NSString stringWithUTF8String:[[obj.value copy] bytes]];
            if (!singleString) return;
            //有wifi和data两种交互方式
            [self.wifiString appendString:singleString];
            [self.wifiData appendData:obj.value];
            
        }
    }];
}

- (void)sendWifiResult:(BOOL)result {
    NSData *successData = [result ? @"true" : @"false" dataUsingEncoding:NSUTF8StringEncoding];
    self.readWrite.value = successData; //将信息保存到character中，读取时会用到
    [_manager updateValue:successData forCharacteristic:self.readWrite onSubscribedCentrals:nil]; //直接通知更改
}

@end
