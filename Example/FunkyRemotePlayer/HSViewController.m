//
//  HSViewController.m
//  FunkyRemotePlayer
//
//  Created by funkyHS on 06/23/2017.
//  Copyright (c) 2017 funkyHS. All rights reserved.
//

#import "HSViewController.h"
#import "HSRemotePlayer.h"


@interface HSViewController ()

@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *loadPV;

@property (nonatomic, weak) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

@property (weak, nonatomic) IBOutlet UIButton *mutedBtn;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;



@end

@implementation HSViewController

- (NSTimer *)timer {
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        _timer = timer;
    }
    return _timer;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self timer];
}


- (void)update {
    
    NSLog(@"%zd", [HSRemotePlayer shareInstance].state);
    
    // 68
    // 01:08
    // 设计数据模型的
    // 弱业务逻辑存放位置的问题
    self.playTimeLabel.text =  [HSRemotePlayer shareInstance].currentTimeFormat;
    self.totalTimeLabel.text = [HSRemotePlayer shareInstance].totalTimeFormat;
    
    self.playSlider.value = [HSRemotePlayer shareInstance].progress;
    
    self.volumeSlider.value = [HSRemotePlayer shareInstance].volume;
    
    self.loadPV.progress = [HSRemotePlayer shareInstance].loadDataProgress;
    
    self.mutedBtn.selected = [HSRemotePlayer shareInstance].muted;
    
    
}


- (IBAction)play:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://audio.xmcdn.com/group23/M04/63/C5/wKgJNFg2qdLCziiYAGQxcTOSBEw402.m4a"];
    [[HSRemotePlayer shareInstance] playWithURL:url isCache:YES];
    
}
- (IBAction)pause:(id)sender {
    [[HSRemotePlayer shareInstance] pause];
}

- (IBAction)resume:(id)sender {
    [[HSRemotePlayer shareInstance] resume];
}
- (IBAction)kuaijin:(id)sender {
    [[HSRemotePlayer shareInstance] seekWithTimeDiffer:15];
}
- (IBAction)progress:(UISlider *)sender {
    [[HSRemotePlayer shareInstance] seekWithProgress:sender.value];
}
- (IBAction)rate:(id)sender {
    [[HSRemotePlayer shareInstance] setRate:2];
}
- (IBAction)muted:(UIButton *)sender {
    sender.selected = !sender.selected;
    [[HSRemotePlayer shareInstance] setMuted:sender.selected];
}
- (IBAction)volume:(UISlider *)sender {
    [[HSRemotePlayer shareInstance] setVolume:sender.value];
}


@end
