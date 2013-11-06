//
// HCReachability.m
//
// Copyright (c) 2013 Neil Burchfield
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "HCReachability.h"
#import <Availability.h>

NSString *const HCReachabilityStatusDidChangeNotification = @"HCReachabilityStatusDidChangeNotification";
NSString *const HCReachabilityNotificationStatusKey       = @"status";

@interface HCReachability ()
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, assign) HCReachabilityStatus     status;
@end

@implementation HCReachability

static void ONEReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info){
    dispatch_async(DISPATCH_GLOBAL_OBJECT(dispatch_queue_t, _dispatch_main_q), ^{
        
    });
    
    //////////////////////////////////////////////////////////
    // HCReachabilityStatusNotReachable
    //////////////////////////////////////////////////////////
    
    HCReachabilityStatus status = HCReachabilityStatusUnknown;
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0 ||
        (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0) {
        status = HCReachabilityStatusNotReachable;
    }
    
    
    //////////////////////////////////////////////////////////
    // HCReachabilityStatusReachableViaWWAN
    //////////////////////////////////////////////////////////
    
#if TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = HCReachabilityStatusReachableViaWWAN;
    }
#endif
    
    //////////////////////////////////////////////////////////
    // HCReachabilityStatusReachableViaWiFi
    //////////////////////////////////////////////////////////
    
    else {
        status = HCReachabilityStatusReachableViaWiFi;
    }
    
    //////////////////////////////////////////////////////////
    // Notify if Network Status Changed
    //////////////////////////////////////////////////////////
    
    if (status != [HCReachability sharedInstance].status) {
        [HCReachability sharedInstance].status = status;
        [[NSNotificationCenter defaultCenter] postNotificationName:HCReachabilityStatusDidChangeNotification object:[HCReachability sharedInstance] userInfo:@{HCReachabilityNotificationStatusKey: @(status)}];
    }
}

+ (void)load {
    
    //////////////////////////////////////////////////////////
    // Init Singleton on Main
    //////////////////////////////////////////////////////////
    
    [self performSelectorOnMainThread:@selector (sharedInstance) withObject:nil waitUntilDone:NO];
}

+ (instancetype)sharedInstance {
    
    //////////////////////////////////////////////////////////
    // Init Singleton
    //////////////////////////////////////////////////////////
    
    static HCReachability *instance;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

+ (BOOL)isReachable {
    
    //////////////////////////////////////////////////////////
    // Return NO if Not Reachable
    //////////////////////////////////////////////////////////
    
    return [[self sharedInstance] status] != HCReachabilityStatusNotReachable;
}

- (id)init {
    
    //////////////////////////////////////////////////////////
    // Default Class Variables
    //////////////////////////////////////////////////////////
    
    if ((self = [super init])) {
        _status       = HCReachabilityStatusUnknown;
        _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "apple.com");
        SCNetworkReachabilitySetCallback(_reachability, ONEReachabilityCallback, NULL);
        SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
    //////////////////////////////////////////////////////////
    // Safely Release
    //////////////////////////////////////////////////////////
    
    if (_reachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(_reachability);
    }
}

@end
