//
//  LCAVPlayerPresentView.h
//  LC
//
//  Created by touchpal on 2020/5/25.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

@interface LCAVPlayerPresentView : UIView

@property (nonatomic, strong) AVPlayer *player;
/// default is AVLayerVideoGravityResizeAspect.
@property (nonatomic, strong) AVLayerVideoGravity videoGravity;

@end

NS_ASSUME_NONNULL_END
