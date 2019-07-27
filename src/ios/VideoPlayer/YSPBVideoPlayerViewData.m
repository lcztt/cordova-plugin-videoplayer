//
//  YSPBVideoPlayerViewData.m
//  JieYouPu
//
//  Created by vitas on 2018/11/12.
//  Copyright © 2018 XinChao. All rights reserved.
//

#import "YSPBVideoPlayerViewData.h"
#import "YSPBVideoPlayerView.h"
#import "YSPBUtilities.h"
#import "YSPhotoBrowserTipView.h"
#import "YSPBCopyWriter.h"

@interface YSPBVideoPlayerViewData () <NSURLSessionDelegate> {
    NSURLSessionDownloadTask *_downloadTask;
}
@end

@implementation YSPBVideoPlayerViewData
#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self->_dataState = YSPBVideoPlayerViewDataStateInvalid;
        self->_dataDownloadState = YSPBVideoPlayerViewDataDownloadStateNone;
    }
    return self;
}

#pragma mark - public

- (void)setUrl:(NSURL *)url {
    _url = [url isKindOfClass:NSString.class] ? [NSURL URLWithString:(NSString *)url] : url;
    self.avAsset = [AVURLAsset URLAssetWithURL:self->_url options:nil];
    
    [self loadData];
}

#pragma mark - internal

- (void)loadData {
    if (self.avAsset) {
        [self loadFirstFrameOfVideo];
    } else {
        self.dataState = YSPBVideoPlayerViewDataStateInvalid;
    }
}

- (BOOL)loadLocalFirstFrameOfVideo {
    if (self.firstFrame) {
        self.dataState = YSPBVideoPlayerViewDataStateFirstFrameReady;
    } else {
        return NO;
    }
    return YES;
}

- (void)loadFirstFrameOfVideo {
    if (!self.avAsset) return;
    
    if ([self loadLocalFirstFrameOfVideo]) return;
    
    if (self.dataState == YSPBVideoPlayerViewDataStateIsLoadingFirstFrame) {
        self.dataState = YSPBVideoPlayerViewDataStateIsLoadingFirstFrame;
        return;
    }
    
    self.dataState = YSPBVideoPlayerViewDataStateIsLoadingFirstFrame;
    CGSize size = [self.class getPixelSizeOfCurrentLayoutDirection];
    XCPB_GET_QUEUE_ASYNC(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.avAsset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = size;
        NSError *error = nil;
        CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:NULL error:&error];
        UIImage *result = cgImage ? [UIImage imageWithCGImage:cgImage] : nil;
        XCPB_GET_QUEUE_MAIN_ASYNC(^{
            if (error || !result) {
                self.dataState = YSPBVideoPlayerViewDataStateLoadFirstFrameFailed;
            } else {
                self.firstFrame = result;
                self.dataState = YSPBVideoPlayerViewDataStateLoadFirstFrameSuccess;
                self.dataState = YSPBVideoPlayerViewDataStateFirstFrameReady;
            }
        })
    })
}

+ (CGRect)getImageViewFrameWithImageSize:(CGSize)size {
    CGSize cSize = [self.class getSizeOfCurrentLayoutDirection];
    if (cSize.width <= 0 || cSize.height <= 0 || size.width <= 0 || size.height <= 0) return CGRectZero;
    CGFloat x = 0, y = 0, width = 0, height = 0;
    if (size.width / size.height >= cSize.width / cSize.height) {
        width = cSize.width;
        height = cSize.width * (size.height / size.width);
        x = 0;
        y = (cSize.height - height) / 2.0;
    } else {
        height = cSize.height;
        width = cSize.height * (size.width / size.height);
        x = (cSize.width - width) / 2.0;
        y = 0;
    }
    return CGRectMake(x, y, width, height);
}

#pragma mark - private

+ (CGSize)getPixelSizeOfCurrentLayoutDirection {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = [self getSizeOfCurrentLayoutDirection];
    return CGSizeMake(size.width * scale, size.height * scale);
}

+ (CGSize)getSizeOfCurrentLayoutDirection
{
    return [UIScreen mainScreen].bounds.size;
}

- (void)downloadWithUrl:(NSURL *)url {
    if (self.dataDownloadState == YSPBVideoPlayerViewDataDownloadStateIsDownloading) {
        self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateIsDownloading;
        return;
    }
    self.downloadingVideoProgress = 0;
    self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateIsDownloading;
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self->_downloadTask = [session downloadTaskWithURL:url];
    [self->_downloadTask resume];
}

#pragma mark - <NSURLSessionDelegate>

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    self.downloadingVideoProgress = progress;
    self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateIsDownloading;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateComplete;
    if (error) {
        [YSPBGetNormalWindow() showForkTipView:@"下载失败"];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [cache stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:file] error:nil];
    
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
        UISaveVideoAtPathToSavedPhotosAlbum(file, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    } else {
        self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateComplete;
        [YSPBGetNormalWindow() showForkTipView:[YSPBCopyWriter shareCopyWriter].saveToPhotoAlbumFailed];
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    self.dataDownloadState = YSPBVideoPlayerViewDataDownloadStateComplete;
    if (error) {
        [YSPBGetNormalWindow() showForkTipView:[YSPBCopyWriter shareCopyWriter].saveToPhotoAlbumFailed];
    } else {
        [YSPBGetNormalWindow() showHookTipView:[YSPBCopyWriter shareCopyWriter].saveToPhotoAlbumSuccess];
    }
}

@end
