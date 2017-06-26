//
//  HSAppDelegate.m
//  FunkyRemotePlayer
//
//  Created by funkyHS on 06/23/2017.
//  Copyright (c) 2017 funkyHS. All rights reserved.
//

#import "HSAppDelegate.h"

@implementation HSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

/*
 
 1.播放器-简单功能实现
 
     - 播放
     - 暂停
     - 继续
     - 停止
     - 快进／快退
     - 指定时间播放 （指定进度，指定时间偏移量）
     - 倍速
     - 声音调整
 
 
 2.播放器-事件&数据提供
 
     - 音频总时长
     - 音频当前播放时长
     - 播放进度
     - 音频URL地址
     - 缓冲进度
     - 是否静音
     - 音量大小
     - 速率
     - 注意: 数据的提供方式：一对一的情况（block／代理），一对多的情况（通知）
     - 状态（所有的播放, 走一个方法, 比较好控制）
     - 事件
        播放完成：AVPlayerItemDidPlayToEndTimeNotification
        播放被打断：AVPlayerItemPlaybackStalledNotification
        播放状态的变化
 
 
 3.播放器-拦截播放请求&假数据测试
 
     3.1 拦截音频需要加载的区域
     3.2 从本地文件中获取响应数据, 并返回给播放器
         - 填写内容头部信息
         - 返回响应填充数据
         - 完成请求
     
 
 
 4.播放器-边播放,边下载, 边缓存
 
    4.1 拦截播放数据请求（streaming -> 设置资源加载代理)
    4.2 处理请求
     --> 检测本地缓存是否存在, 如果存在, 则直接从本地缓存返回相应额信息
        - 根据文件后缀名, 获取对应的mimeType
        - 获取文件的总大小
        - 获取数据并响应
        - 完成请求
     --> 否则进行下载处理
        - 判断是否正在下载, 如果没有, 则下载并返回
        - 如果已经在下载, 判断是否需要重新下载, 如果需要, 则重新下载并返回
        - 否则, 就处理保存在数组中的请求(并且在下载过程中, 不断的判断处理所有请求)
        - 关于所有请求的处理流程
            - 给每个请求, 填充头部信息
            - 计算填充区域
            - 根据每个请求的区间, 填充数据
            - 判断是否能够完全填充, 如果能, 则返回数据后, 结束这个请求
    4.3 恶心的代码
        - 根据文件名称获取mimeType
        - 框架 : #import <MobileCoreServices/MobileCoreServices.h>
        - 函数 : CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
 
 */




@end
