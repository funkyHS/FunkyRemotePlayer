//
//  HSRemotePlayer.m
//  FunkyRemotePlayer
//
//  Created by 胡晟 on 2017/6/23.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "HSRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "HSRemoteResourceLoaderDelegate.h"
#import "NSURL+HSURL.h"


@interface HSRemotePlayer ()
{
    BOOL _isUserPause;
}
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) HSRemoteResourceLoaderDelegate *resourceLoaderDelegate;



@end

@implementation HSRemotePlayer

static HSRemotePlayer *_shareInstance;
+ (instancetype)shareInstance {
    if (!_shareInstance) {
        _shareInstance = [[HSRemotePlayer alloc] init];
    }
    
    return _shareInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}


// 根据url播放远程地址
- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache {
    
    NSURL *currentURL = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ([url isEqual:currentURL]) {
        NSLog(@"当前播放任务已经存在");
        [self resume];
        return;
    }
    
    /*
     
    --> 直接创建一个播放器对象（如果用此方法去播放远程音频，默认帮我们封装了三个步骤：资源的请求 -> 资源的组织 -> 资源的播放）,如果资源加载比较慢,可能会造成调用了play方法, 但是并没有播放音频
     
     AVPlayer *player = [AVPlayer playerWithURL:url];
     [player play];
     
     */
    
    _url = url;
    if (isCache) {
        url = [url steamingURL];
    }
    
    // 1. 资源的请求(利用内部 AVAssetResourceLoader *resourceLoader 进行资源请求)
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    if (self.player.currentItem) {
        // 防止点击2次播放，重复添加监听者
        [self removeObserver];
    }
    
    
    // 关于网络音频的请求,是通过对象resourceLoader,调用代理的相关方法,进行加载的,想要拦截加载的请求, 只需要重新修改它的代理方法就可以（AVAssetResourceLoader仅在AVURLAsset不知道如何去加载这个URL资源时才会被调用）
    self.resourceLoaderDelegate = [HSRemoteResourceLoaderDelegate new];
    [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_get_main_queue()];
    
    
    // 2. 资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 当资源的组织者, 告诉我们资源准备好了之后, 我们再播放
    // AVPlayerItemStatus status（KVO监听是否准备好）
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听资源是否足够播放
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    // 播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    // 播放被打断（来电话／资源加载跟不上了）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // 3. 资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
    
}

// 暂停播放
- (void)pause {
    [self.player pause];
    _isUserPause = YES;
    if (self.player) {
        self.state = HSRemotePlayerStatePause;
    }
}

// 继续播放
- (void)resume {
    [self.player play];
    _isUserPause = NO;
    // 当前播放器存在且数据组织者里面的数据准备, 已经足够播放了
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        self.state = HSRemotePlayerStatePlaying;
    }
    
}

// 停止播放
- (void)stop {
    [self.player pause];
    self.player = nil;
    if (self.player) {
        self.state = HSRemotePlayerStateStopped;
    }
}

// 拖动进度条的进度
- (void)seekWithProgress:(float)progress {
    
    if (progress < 0 || progress > 1) {
        return;
    }
    
    // 可以指定时间节点去播放
    // 时间: CMTime : 影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    // 当前音频, 已经播放的时长 --> self.player.currentItem.currentTime

    
    CMTime totalTime = self.player.currentItem.duration;
    
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"确定加载这个时间点的音频资源");
        }else {
            NSLog(@"取消加载这个时间点的音频资源");
        }
    }];
    
    
}

// 快进 timeDiffer 秒
- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    
    // 1. 当前音频资源的总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    
    // 2. 当前音频, 已经播放的时长
    NSTimeInterval playTimeSec = [self currentTime];
    
    playTimeSec += timeDiffer;
    
    [self seekWithProgress:playTimeSec / totalTimeSec];
    
}

// 倍速
- (void)setRate:(float)rate {
    [self.player setRate:rate];
}
- (float)rate {
    return self.player.rate;
}

// 设置静音
- (void)setMuted:(BOOL)muted {
    self.player.muted = muted;
}
- (BOOL)muted {
    return self.player.muted;
}

// 音量
- (void)setVolume:(float)volume {
    
    if (volume < 0 || volume > 1) {
        return;
    }
    if (volume > 0) {
        [self setMuted:NO];
    }
    
    self.player.volume = volume;
}
- (float)volume {
    return self.player.volume;
}

- (NSString *)currentTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

- (NSString *)totalTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.totalTime / 60, (int)self.totalTime % 60];
}

#pragma mark -数据/事件
// 总时间
-(NSTimeInterval)totalTime {
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if (isnan(totalTimeSec)) {
        return 0;
    }
    return totalTimeSec;
}

// 当前播放时间
- (NSTimeInterval)currentTime {
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if (isnan(playTimeSec)) {
        return 0;
    }
    return playTimeSec;
}

// 播放进度
- (float)progress {
    if (self.totalTime == 0) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

//缓存进度
- (float)loadDataProgress {
    
    if (self.totalTime == 0) {
        return 0;
    }
    
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
    
}

// 播放状态的改变
- (void)setState:(HSRemotePlayerState)state {
    _state = state;
    
    // 如果需要告知外界相关的事件（block／代理／发通知）
    
    
}

// 移除监听者
- (void)removeObserver {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

// 播放完成
- (void)playEnd {
    NSLog(@"播放完成");
    self.state = HSRemotePlayerStateStopped;
}

// 播放被打断
- (void)playInterupt {
    // 来电话, 资源加载跟不上
    NSLog(@"播放被打断");
    self.state = HSRemotePlayerStatePause;
}



#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"资源准备好了, 这时候播放就没有问题");
            [self resume];
        }else {
            NSLog(@"状态未知");
            self.state = HSRemotePlayerStateFailed;
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if (ptk) {
            NSLog(@"当前的资源, 准备的已经足够播放了");
            
            // 用户的手动暂停的优先级最高
            if (!_isUserPause) {
                [self resume];
            }else {
                
            }
            
        }else {
            NSLog(@"资源还不够, 正在加载过程当中");
            self.state = HSRemotePlayerStateLoading;
        }
        
        
    }
    
    
    
}



@end
