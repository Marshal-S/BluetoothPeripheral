//
//  ZLBlueTooth.h
//  dakaDevice
//
//  Created by Marshal on 2020/4/15.
//  Copyright © 2020 Marshal. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLBlueTooth : NSObject

+ (instancetype)manager;

- (void)sendWifiResult:(BOOL)result;

- (void)reset; //重置内部信息

@end

NS_ASSUME_NONNULL_END
