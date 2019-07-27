//
//  YSPBCopyWriter.m
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import "YSPBCopyWriter.h"

@implementation YSPBCopyWriter
#pragma mark - life cycle

+ (instancetype)shareCopyWriter
{
    static YSPBCopyWriter *CopyWriter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CopyWriter = [YSPBCopyWriter new];
    });
    return CopyWriter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        YSPBCopyWriterType type = YSPBCopyWriterTypeSimplifiedChinese;
        NSArray *appleLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        if (appleLanguages && appleLanguages.count > 0) {
            NSString *languages = appleLanguages[0];
            if (![languages isEqualToString:@"zh-Hans-CN"]) {
                type = YSPBCopyWriterTypeEnglish;
            }
        }
        self.type = type;
        
        [self initCopy];
    }
    return self;
}

#pragma mark - private

- (void)initCopy {
    BOOL en = self.type == YSPBCopyWriterTypeEnglish;
    
    self.videoIsInvalid = en ? @"Video is invalid" : @"视频无效";
    self.videoError = en ? @"Video error" : @"视频错误";
    self.unableToSave = en ? @"Unable to save" : @"无法保存";
    self.imageIsInvalid = en ? @"Image is invalid" : @"图片无效";
    self.downloadImageFailed = en ? @"Download failed" : @"图片下载失败";
    self.getPhotoAlbumAuthorizationFailed = en ? @"Failed to get album authorization" : @"获取相册权限失败";
    self.saveToPhotoAlbumSuccess = en ? @"Save successful" : @"已保存到系统相册";
    self.saveToPhotoAlbumFailed = en ? @"Save failed" : @"保存失败";
    self.saveToPhotoAlbum = en ? @"Save" : @"保存到相册";
    self.cancel = en ? @"Cancel" : @"取消";
}

#pragma mark - public

- (void)setType:(YSPBCopyWriterType)type
{
    _type = type;
    [self initCopy];
}

@end
