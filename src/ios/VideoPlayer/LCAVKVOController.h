//
//  LCAVKVOController.h
//  Naga
//
//  Created by touchpal on 2020/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCAVKVOController : NSObject

- (instancetype)initWithTarget:(NSObject *)target;

- (void)safelyAddObserver:(NSObject *)observer
               forKeyPath:(NSString *)keyPath
                  options:(NSKeyValueObservingOptions)options
                  context:(nullable void *)context;

- (void)safelyRemoveObserver:(NSObject *)observer
                  forKeyPath:(NSString *)keyPath;

- (void)safelyRemoveAllObservers;

@end

NS_ASSUME_NONNULL_END
