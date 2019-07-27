//
//  YSPBCopyWriter.h
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YSPBCopyWriterType) {
    YSPBCopyWriterTypeSimplifiedChinese,
    YSPBCopyWriterTypeEnglish
};

@interface YSPBCopyWriter : NSObject

+ (instancetype)shareCopyWriter;

@property (nonatomic, assign) YSPBCopyWriterType type;


// The following propertys can be changed.

@property (nonatomic, copy) NSString *videoIsInvalid;

@property (nonatomic, copy) NSString *videoError;

@property (nonatomic, copy) NSString *unableToSave;

@property (nonatomic, copy) NSString *imageIsInvalid;

@property (nonatomic, copy) NSString *downloadImageFailed;

@property (nonatomic, copy) NSString *getPhotoAlbumAuthorizationFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbumSuccess;

@property (nonatomic, copy) NSString *saveToPhotoAlbumFailed;

@property (nonatomic, copy) NSString *saveToPhotoAlbum;

@property (nonatomic, copy) NSString *cancel;

@end

NS_ASSUME_NONNULL_END
