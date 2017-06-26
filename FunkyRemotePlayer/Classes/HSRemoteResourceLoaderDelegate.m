//
//  HSRemoteResourceLoaderDelegate.m
//  FunkyRemotePlayer
//
//  Created by 胡晟 on 2017/6/25.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "HSRemoteResourceLoaderDelegate.h"
#import "HSRemoteAudioFile.h"
#import "NSURL+HSURL.h"
#import "HSAudioDownLoader.h"

@interface HSRemoteResourceLoaderDelegate ()<HSAudioDownLoaderDelegate>

@property (nonatomic, strong) HSAudioDownLoader *downLoader;

@property (nonatomic, strong) NSMutableArray *loadingRequests;

@end

@implementation HSRemoteResourceLoaderDelegate

// 当外界, 需要播放一段音频资源是, 会跑一个请求, 给这个对象
// 这个对象, 到时候, 只需要根据请求信息, 抛数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    NSLog(@"%@", loadingRequest);
    
    // 1. 判断本地有没有该音频资源的缓存文件, 如果有 -> 直接根据本地缓存, 向外界响应数据(3个步骤) return
    
    NSURL *url = [loadingRequest.request.URL httpURL];
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if (requestOffset != currentOffset) {
        requestOffset = currentOffset;
    }
    
    if ([HSRemoteAudioFile cacheFileExists:url]) {
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    // 记录所有的请求
    [self.loadingRequests addObject:loadingRequest];


    
    // 2. 资源没有下载好(本地没有该音频资源的缓存文件) -> 判断有没有正在下载,如果没有正在下载，那么就去下载 return
    if (self.downLoader.loadedSize == 0) {
        
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        // 开始下载数据(根据请求的信息, url, requestOffset, requestLength)
        return YES;
    }
    
    
    // 3. 当前有正在下载 -> 判断当前是否需要重新下载，如果是，直接重新下载，return
        // --> 当资源请求的开始点（起始点） < 下载的开始点
        // --> 当资源的请求的开始点 > 下载的开始点 + 下载的长度 + 666（可允许的加载字节）
    if (requestOffset < self.downLoader.offset || requestOffset > (self.downLoader.offset + self.downLoader.loadedSize + 666)) {
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    
    // 下载的区间是可以匹配的到响应区间的
    // 4. 处理所有资源请求 (在下载过程当中, 也要不断的判断，并处理请求)
    [self handleAllLoadingRequest];

    
    
    return YES;
}

// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"取消某个请求");
    [self.loadingRequests removeObject:loadingRequest];

}


- (void)downLoading {
    [self handleAllLoadingRequest];
}

#pragma mark - 私有方法

- (void)handleAllLoadingRequest {
    //    NSLog(@"在这里不断的处理请求");
    //NSLog(@"-----%@", self.loadingRequests);
    NSMutableArray *deleteRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        // 1. 填充内容信息头
        NSURL *url = loadingRequest.request.URL;
        long long totalSize = self.downLoader.totalSize;
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        NSString *contentType = self.downLoader.mimeType;
        loadingRequest.contentInformationRequest.contentType = contentType;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        // 2. 填充数据
        NSData *data = [NSData dataWithContentsOfFile:[HSRemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        if (data == nil) {
            // 如果从临时文件找不到，就从缓存文件中取！
            data = [NSData dataWithContentsOfFile:[HSRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        if (requestOffset != currentOffset) {
            requestOffset = currentOffset;
        }
        NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
        
        
        long long responseOffset = requestOffset - self.downLoader.offset;
        long long responseLength = MIN(self.downLoader.offset + self.downLoader.loadedSize - requestOffset, requestLength) ;
        
        NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        
        [loadingRequest.dataRequest respondWithData:subData];
        
        
        
        // 3. 完成请求(必须把所有的关于这个请求的区间数据, 都返回完之后, 才能完成这个请求)
        if (requestLength == responseLength) {
            [loadingRequest finishLoading];
            [deleteRequests addObject:loadingRequest];
        }
        
    }
    
    [self.loadingRequests removeObjectsInArray:deleteRequests];
    
}

// 处理, 本地已经下载好的资源文件
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    // 1. 填充相应的信息头信息
    // 计算总大小
    
    
    NSURL *url = loadingRequest.request.URL;
    long long totalSize = [HSRemoteAudioFile cacheFileSize:url];
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    
    NSString *contentType = [HSRemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    // 2. 相应数据给外界
    NSData *data = [NSData dataWithContentsOfFile:[HSRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
    
    // requestedOffset -> 请求开始的节点  requestedLength -> 请求的长度
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    // 3. 完成本次请求(一旦,所有的数据都给完了, 才能调用完成请求方法)
    [loadingRequest finishLoading];
}

#pragma mark - 懒加载

- (HSAudioDownLoader *)downLoader {
    if (!_downLoader) {
        _downLoader = [[HSAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}


- (NSMutableArray *)loadingRequests {
    if (!_loadingRequests) {
        _loadingRequests = [NSMutableArray array];
    }
    return _loadingRequests;
}

@end
