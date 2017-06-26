//
//  NSURL+HSURL.m
//  FunkyRemotePlayer
//
//  Created by 胡晟 on 2017/6/25.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "NSURL+HSURL.h"

@implementation NSURL (HSURL)

- (NSURL *)steamingURL {
    // http://xxxx
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"sreaming";
    return compents.URL;
}

- (NSURL *)httpURL {
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"http";
    return compents.URL;    
}

@end
