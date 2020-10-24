//
//  LCAVPlayerPresentView.m
//  LC
//
//  Created by touchpal on 2020/5/25.
//

#import "LCAVPlayerPresentView.h"

@implementation LCAVPlayerPresentView
@dynamic player;
@dynamic videoGravity;

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)avLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player
{
    if (player == self.player) return;
    [self avLayer].player = player;
}

- (AVPlayer *)player
{
    return [self avLayer].player;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity
{
    if (videoGravity == self.videoGravity) return;
    [self avLayer].videoGravity = videoGravity;
}

- (AVLayerVideoGravity)videoGravity
{
    return [self avLayer].videoGravity;
}

@end
