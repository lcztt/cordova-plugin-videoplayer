//
//  YSPBVideoPlayManager.m
//  HelloWorld
//
//  Created by vitas on 2019/7/27.
//

#import "YSPBVideoPlayManager.h"
#import "LCAVPlayer.h"
#import "LCAVPlayerModel.h"
#import "MainViewController.h"


@interface YSPBVideoPlayManager ()

@property (nonatomic, strong) CDVInvokedUrlCommand *command;
@property (nonatomic, strong) LCAVPlayer *videoPlayer;

@end

@implementation YSPBVideoPlayManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static YSPBVideoPlayManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[YSPBVideoPlayManager alloc] init];
    });
    return manager;
}

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    self.command = command;

    if (command.arguments.count != 1) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSDictionary *params = (NSDictionary *)[command.arguments objectAtIndex:0];
    if (![params isKindOfClass:[NSDictionary class]] || params.count == 0) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSLog(@"%@", params);
    NSString *videoPath = params[@"videoPath"];
    NSString *videoCover = params[@"videoCover"];
    BOOL isLoop = [params[@"isLoop"] boolValue];
    BOOL isStart = [params[@"isStart"] boolValue];
    
    UIViewController *vc = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([vc isKindOfClass:[UINavigationController class]]) {
        vc = [[(UINavigationController *)vc viewControllers] lastObject];
    }
    if (![vc isKindOfClass:[MainViewController class]]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    if (self.videoPlayer) {
        
        if ([self.videoPlayer.videoModel.video_path isEqualToString:videoPath]) {
            [self.videoPlayer play];
            return;
        }
        
        [self.videoPlayer removeFromSuperview];
        self.videoPlayer = nil;
    }
    CGRect frame = [[UIScreen mainScreen] bounds];
//    frame.origin.y = frame.size.height;
    self.videoPlayer = [[LCAVPlayer alloc] initWithFrame:frame];
    [vc.view insertSubview:self.videoPlayer belowSubview:vc.webView];
    vc.webView.opaque = false;
    
    self.videoPlayer.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.videoPlayer.alpha = 1;
//        CGRect frame = self.videoPlayer.frame;
//        frame.origin.y = 0;
//        self.videoPlayer.frame = frame;
    } completion:^(BOOL finished) {
        
        [self addNotification];
        
        self.videoPlayer.shouldAutoPlay = isStart;
        self.videoPlayer.shouldLoopPlay = isLoop;
        
        LCAVPlayerModel *data = [[LCAVPlayerModel alloc] init];
        data.video_path = videoPath;
        data.cover_path = videoCover;
        // 先设定 shouldAutoPlay，在设定 videoModel
        self.videoPlayer.videoModel = data;
    }];
    
    NSDictionary *paramss = @{@"status":@(0)};
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:paramss];
    pluginResult.keepCallback = @(1);
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)closeVideo:(CDVInvokedUrlCommand *)command
{
    if (self.videoPlayer) {
        [UIView animateWithDuration:0.25 animations:^{
            self.videoPlayer.alpha = 0;
//            CGRect frame = self.videoPlayer.frame;
//            frame.origin.y = 0;
//            self.videoPlayer.frame = frame;
        } completion:^(BOOL finished) {
            [self.videoPlayer removeFromSuperview];
            self.videoPlayer = nil;
            
            MainViewController *vc = (MainViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
            vc.webView.opaque = true;
            [self removeNotification];
        }];
    }
}

- (void)pauseVideo:(CDVInvokedUrlCommand *)command
{
    [self.videoPlayer pause];
}

- (void)replay:(CDVInvokedUrlCommand *)command
{
    [self.videoPlayer play];
}

- (void)mute:(CDVInvokedUrlCommand *)command
{
    if (command.arguments.count > 0) {
        NSDictionary *params = command.arguments[0];
        if ([params isKindOfClass:[NSDictionary class]]) {
            self.videoPlayer.isMute = [params[@"mute"] boolValue];
            
            NSDictionary *params = @{};
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:params];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
    }
    
    NSDictionary *params = @{@"code":@(1), @"desc":@"参数不完整"};
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:params];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:YSPhotoBrowserVideoStartPlayNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:YSPhotoBrowserVideoDownloadCompletionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notificationHandler:(NSNotification *)notification
{
//    if ([notification.name isEqualToString:YSPhotoBrowserVideoDownloadCompletionNotification]) {
//        NSLog(@"load first frame completion 1");
//
//        NSDictionary *params = @{@"status":@(1)};
//        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
//                                                      messageAsDictionary:params];
//        pluginResult.keepCallback = @(1);
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
//    } else if ([notification.name isEqualToString:YSPhotoBrowserVideoStartPlayNotification]) {
//        NSLog(@"start play 2");
//
//        NSDictionary *params = @{@"status":@(2)};
//        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
//                                                      messageAsDictionary:params];
//        pluginResult.keepCallback = @(1);
//        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
//    } else
        if ([notification.name isEqualToString:AVPlayerItemDidPlayToEndTimeNotification]) {
        NSLog(@"play to end 3");
        
        NSDictionary *params = @{@"status":@(3)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:params];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    } else if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        NSLog(@"pause to play 4");
        
        NSDictionary *params = @{@"status":@(4)};
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:params];
        pluginResult.keepCallback = @(1);
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }
}

- (NSString *)jsonStringEncodedWith:(NSDictionary *)params {
    if ([NSJSONSerialization isValidJSONObject:params]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

@end
