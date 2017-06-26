//
//  HSAudioDownLoader.m
//  FunkyRemotePlayer
//
//  Created by 胡晟 on 2017/6/25.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "HSAudioDownLoader.h"
#import "HSRemoteAudioFile.h"


// 下载某一个区间的数据,不需要断点续传功能

@interface HSAudioDownLoader()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSURL *url;


@end


@implementation HSAudioDownLoader


- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {
    [self cancelAndClean];
    
    self.url = url;
    self.offset = offset;
    
    // 请求的是某一个区间的数据 Range
    // NSURLRequestReloadIgnoringLocalCacheData 忽略本地缓存数据
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
    
}


- (void)cancelAndClean {
    // 取消
    [self.session invalidateAndCancel];
    self.session = nil;
    // 清空本地已经存储的临时缓存
    [HSRemoteAudioFile clearTmpFile:self.url];
    
    // 重置数据
    self.loadedSize = 0;
}


#pragma mark - NSURLSessionDataDelegate {

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    // 1. 从  Content-Length 取出来
    // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
    self.totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if (contentRangeStr.length != 0) {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    
    self.mimeType = response.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[HSRemoteAudioFile tmpFilePath:self.url] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if ([self.delegate respondsToSelector:@selector(downLoading)]) {
        [self.delegate downLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error == nil) {
        NSURL *url = self.url;
        if ([HSRemoteAudioFile tmpFileSize:url] == self.totalSize) {
            // 移动文件 : 临时文件夹 -> cache文件夹
            [HSRemoteAudioFile moveTmpPathToCachePath:url];
        }
        
    }else {
        NSLog(@"有错误");
    }
    
    
}



@end

