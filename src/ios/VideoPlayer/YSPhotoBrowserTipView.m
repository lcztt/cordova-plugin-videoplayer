//
//  YSPhotoBrowserTipView.m
//  Solution
//
//  Created by vitas on 2018/11/9.
//  Copyright © 2018 Solution. All rights reserved.
//

#import "YSPhotoBrowserTipView.h"
#import <objc/runtime.h>

@implementation UIView (YSPhotoBrowserPromptBar)

- (void)showHookTipView:(NSString *)text
{
    [self showTipViewWithText:text type:YSPhotoBrowserTipTypeHook hideAfterDelay:2];
}

- (void)showForkTipView:(NSString *)text
{
    [self showTipViewWithText:text type:YSPhotoBrowserTipTypeFork hideAfterDelay:2];
}

- (void)showTipViewWithText:(NSString *)text type:(YSPhotoBrowserTipType)type hideAfterDelay:(NSTimeInterval)delay
{
    YSPhotoBrowserTipView *tipView = self.tipView;
    if (!tipView) {
        tipView = [YSPhotoBrowserTipView new];
        self.tipView = tipView;
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideTipView) object:nil];
    }
    
    if (!tipView.superview) {
        [self addSubview:tipView];
        tipView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:tipView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:tipView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:tipView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:40];
        NSLayoutConstraint *layD = [NSLayoutConstraint constraintWithItem:tipView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-40];
        [self addConstraints:@[layA, layB, layC, layD]];
    }
    
    [tipView startAnimationWithText:text type:type];
    
    [self performSelector:@selector(hideTipView) withObject:nil afterDelay:delay];
}

- (void)hideTipView {
    YSPhotoBrowserTipView *tipView = self.tipView;
    if (tipView && tipView.superview) {
        [tipView removeFromSuperview];
    }
}

- (void)setTipView:(YSPhotoBrowserTipView * _Nonnull)tipView
{
    objc_setAssociatedObject(self, "YSPhotoBrowserTipView", tipView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YSPhotoBrowserTipView *)tipView
{
    return objc_getAssociatedObject(self, "YSPhotoBrowserTipView");
}

@end


@interface YSPhotoBrowserTipView () {
    YSPhotoBrowserTipType _tipType;
    CAShapeLayer *_shapeLayer;
}
@property (nonatomic, strong) UILabel *textLabel;

@end


@implementation YSPhotoBrowserTipView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_tipType = YSPhotoBrowserTipTypeNone;
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.userInteractionEnabled = NO;
        self.layer.cornerRadius = 7;
        
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)updateConstraints {
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *layA = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20];
    NSLayoutConstraint *layB = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20];
    NSLayoutConstraint *layC = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-15];
    NSLayoutConstraint *layD = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:70];
    NSLayoutConstraint *layE = [NSLayoutConstraint constraintWithItem:self.textLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60];
    [self addConstraints:@[layA, layB, layC, layD, layE]];
    [super updateConstraints];
}

- (void)layoutSubviews {
    if (self->_tipType != YSPhotoBrowserTipTypeNone) {
        [self _startAnimation];
    }
    [super layoutSubviews];
}

#pragma mark - animation

- (void)startAnimationWithText:(NSString *)text type:(YSPhotoBrowserTipType)tipType {
    self.textLabel.text = text;
    self->_tipType = tipType;
    [self setNeedsLayout];
}

- (void)_startAnimation {
    if (_shapeLayer && _shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
    }
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    _shapeLayer.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer.lineWidth = 5.0;
    _shapeLayer.lineCap = @"round";
    _shapeLayer.lineJoin = @"round";
    _shapeLayer.strokeStart = 0.0;
    _shapeLayer.strokeEnd = 0.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    CGFloat r = 13.0;
    CGFloat x = self.bounds.size.width / 2.0;
    CGFloat y = 38.0;
    switch (self->_tipType) {
        case YSPhotoBrowserTipTypeHook: {
            [bezierPath moveToPoint:CGPointMake(x - r - r / 2, y)];
            [bezierPath addLineToPoint:CGPointMake(x - r / 2, y + r)];
            [bezierPath addLineToPoint:CGPointMake(x + r * 2 - r / 2, y - r)];
        }
            break;
        case YSPhotoBrowserTipTypeFork: {
            [bezierPath moveToPoint:CGPointMake(x - r, y - r)];
            [bezierPath addLineToPoint:CGPointMake(x + r, y + r)];
            [bezierPath moveToPoint:CGPointMake(x - r, y + r)];
            [bezierPath addLineToPoint:CGPointMake(x + r, y - r)];
        }
            break;
        default:break;
    }
    
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    [baseAnimation setFromValue:@0.0];
    [baseAnimation setToValue:@1.0];
    [baseAnimation setDuration:0.3];
    baseAnimation.removedOnCompletion = NO;
    baseAnimation.fillMode = kCAFillModeBoth;
    
    _shapeLayer.path = bezierPath.CGPath;
    [self.layer addSublayer:_shapeLayer];
    [_shapeLayer addAnimation:baseAnimation forKey:@"strokeEnd"];
}

#pragma mark - getter

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont systemFontOfSize:14];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 0;
    }
    return _textLabel;
}
@end
