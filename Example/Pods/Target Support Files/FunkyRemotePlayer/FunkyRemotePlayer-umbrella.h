#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HSAudioDownLoader.h"
#import "HSRemoteAudioFile.h"
#import "HSRemotePlayer.h"
#import "HSRemoteResourceLoaderDelegate.h"
#import "NSURL+HSURL.h"

FOUNDATION_EXPORT double FunkyRemotePlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char FunkyRemotePlayerVersionString[];

