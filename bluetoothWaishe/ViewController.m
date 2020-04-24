//
//  ViewController.m
//  bluetoothWaishe
//
//  Created by Marshal on 2020/4/24.
//  Copyright © 2020 Marshal. All rights reserved.
//

#import "ViewController.h"
#import "ZLBlueTooth.h"

@interface ViewController ()

@property ZLBlueTooth *bluetooth;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _bluetooth = [ZLBlueTooth manager];
}


@end
