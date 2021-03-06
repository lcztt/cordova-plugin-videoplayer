//
//  LCAVNetworkReachability.m
//  Naga
//
//  Created by touchpal on 2020/3/23.
//

#import <CoreFoundation/CoreFoundation.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import "LCAVNetworkReachability.h"

NSString *const LCAVNetworkReachabilityStatusDidChangeNotification = @"LCAVNetworkReachabilityStatusDidChangeNotification";

static void LCAVNetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@interface LCAVNetworkReachability ()
@property (nonatomic, assign) LCAVNetworkReachabilityStatus status;
@property (nonatomic, copy) void (^statusChangedBlock)(LCAVNetworkReachability *reachability, LCAVNetworkReachabilityStatus status);
@property (nonatomic, assign, readonly) SCNetworkReachabilityRef networkReachability;
@property (nonatomic, strong) dispatch_queue_t networkReachabilityQueue;
@end


@implementation LCAVNetworkReachability

- (void)dealloc
{
    [self stopMonitor];

    if (_networkReachability) {
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability
{
    self = [super init];
    if (self) {
        _networkReachability = CFRetain(reachability);

        NSString *queueName = [NSString stringWithFormat:@"com.0x123.LCAVNetworkReachability.%@", [NSUUID UUID].UUIDString];
        self.networkReachabilityQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], NULL);

        self.status = [self currentReachabilityStatus];
    }

    return self;
}

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

+ (instancetype)defaultReachability
{
    static LCAVNetworkReachability *__gDefaultReachability = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __gDefaultReachability = [self reachabilityForInternetConnection];
    });

    return __gDefaultReachability;
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);

    LCAVNetworkReachability *instance = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);

    instance.identifier = hostName;

    return instance;
}

+ (instancetype)reachabilityWithAddress:(const void *)address
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);

    LCAVNetworkReachability *instance = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);

    instance.identifier = [self IPForSocketAddress:(const struct sockaddr *)address];

    return instance;
}

+ (instancetype)reachabilityForInternetConnection
{
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;

    return [self reachabilityWithAddress:&address];
}

+ (instancetype)reachabilityForLocalWiFi
{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

    return [self reachabilityWithAddress:&localWifiAddress];
}

- (NSString *)statusString
{
    return LCAVNetworkReachabilityStatusString(self.status);
}

- (BOOL)isReachable
{
    return (LCAVNetworkReachabilityStatusReachableViaWWAN == self.status ||
            LCAVNetworkReachabilityStatusReachableViaWiFi == self.status);
}

- (BOOL)isReachableViaWWAN
{
    return (LCAVNetworkReachabilityStatusReachableViaWWAN == self.status);
}

- (BOOL)isReachableViaWiFi
{
    return (LCAVNetworkReachabilityStatusReachableViaWiFi == self.status);
}

- (BOOL)startMonitoring
{
    [self stopMonitor];

    if (self.networkReachability) {
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};

        if (SCNetworkReachabilitySetCallback(self.networkReachability, LCAVNetworkReachabilityCallback, &context)) {
            if (SCNetworkReachabilitySetDispatchQueue(self.networkReachability, self.networkReachabilityQueue)) {
                return YES;
            } else {
                SCNetworkReachabilitySetCallback(self.networkReachability, NULL, NULL);
            }
        }
    }

    return NO;
}

- (void)stopMonitor
{
    if (self.networkReachability) {
        SCNetworkReachabilitySetCallback(self.networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(self.networkReachability, NULL);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, identifier: %@, flags: %@, status: %@>",
            NSStringFromClass([self class]),
            self,
            self.identifier,
            [[self class] networkReachabilityFlagsString:self.currentReachabilityFlags],
            self.statusString
    ];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (SCNetworkReachabilityFlags)currentReachabilityFlags
{
    if (self.networkReachability) {
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            return flags;
        }
    }

    return 0;
}

- (LCAVNetworkReachabilityStatus)currentReachabilityStatus
{
    return [[self class] statusForReachabilityFlags:[self currentReachabilityFlags]];
}

- (void)networkReachabilityStatusChanged:(SCNetworkReachabilityFlags)flags
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.status = [[self class] statusForReachabilityFlags:flags];

        if (self.statusChangedBlock) {
            self.statusChangedBlock(self, self.status);
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:LCAVNetworkReachabilityStatusDidChangeNotification object:self];
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helpers

+ (NSString *)networkReachabilityFlagsString:(SCNetworkReachabilityFlags)flags
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
#else
            'X',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-'
    ];
}

+ (LCAVNetworkReachabilityStatus)statusForReachabilityFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    // the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    // and no [user] intervention is needed...
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);

    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    if (!isNetworkReachable) {
        return LCAVNetworkReachabilityStatusNotReachable;
    }
#if TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        return LCAVNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        return LCAVNetworkReachabilityStatusReachableViaWiFi;
    }
}

+ (NSString *)IPForSocketAddress:(const struct sockaddr *)address
{
    if (AF_INET == address->sa_family) {
        struct sockaddr_in *addr = (struct sockaddr_in *)address;
        char ipBuffer[INET_ADDRSTRLEN];
        if (inet_ntop(AF_INET, &addr->sin_addr, ipBuffer, sizeof(ipBuffer))) {
            return [NSString stringWithUTF8String:ipBuffer];
        }
    } else if (AF_INET6 == address->sa_family) {
        struct sockaddr_in6 *addr = (struct sockaddr_in6 *)address;
        char ipBuffer[INET6_ADDRSTRLEN];
        if (inet_ntop(AF_INET6, &addr->sin6_addr, ipBuffer, sizeof(ipBuffer))) {
            return [NSString stringWithUTF8String:ipBuffer];
        }
    }

    return nil;
}

@end

NSString *LCAVNetworkReachabilityStatusString(LCAVNetworkReachabilityStatus status)
{
    switch (status) {
        case LCAVNetworkReachabilityStatusNotReachable:
            return LCAVNetworkReachabilityStatusStringNotReachable;

        case LCAVNetworkReachabilityStatusReachableViaWWAN:
            return LCAVNetworkReachabilityStatusStringReachableViaWWAN;

        case LCAVNetworkReachabilityStatusReachableViaWiFi:
            return LCAVNetworkReachabilityStatusStringReachableViaWiFi;

        default:
            return @"Unknown";
    }
}

static void LCAVNetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
#pragma unused (target)
    LCAVNetworkReachability *instance = (__bridge LCAVNetworkReachability *)info;

    @autoreleasepool {
        [instance networkReachabilityStatusChanged:flags];
    }
}
