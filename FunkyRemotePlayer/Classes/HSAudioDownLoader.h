//
//  HSAudioDownLoader.h
//  FunkyRemotePlayer
//
//  Created by 胡晟 on 2017/6/25.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HSAudioDownLoaderDelegate <NSObject>

- (void)downLoading;

@end


@interface HSAudioDownLoader : NSObject


@property (nonatomic, weak) id<HSAudioDownLoaderDelegate> delegate;

@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long loadedSize;
@property (nonatomic, assign) long long offset;
@property (nonatomic, strong) NSString *mimeType;


- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;


@end
