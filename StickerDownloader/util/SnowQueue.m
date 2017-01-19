//
//  SnowQueue.m
//  chat
//
//  Created by HAN on 2016. 5. 23..
//  Copyright © 2016년 campmobile. All rights reserved.
//

#import "SnowQueue.h"
#import "NSDictionary+Addition.h"

static NSString *const QUEUE_LABEL_DATABASE = @"QUEUE_LABEL_DATABASE";
static NSString *const QUEUE_LABEL_SESSION = @"QUEUE_LABEL_SESSION";
static NSString *const QUEUE_LABEL_SERIAL = @"QUEUE_LABEL_SERIAL";

@implementation SnowQueue

#pragma mark - Public Methods

+ (void)runMainQueue:(void (^)(void))block
{
    dispatch_async(dispatch_get_main_queue(), block);
}

+ (void)runMainQueueAfter:(CGFloat)second block:(void (^)(void))block
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

+ (void)runGlobalQueue:(void (^)(void))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

+ (void)runGlobalHighQueue:(void (^)(void))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}

+ (void)runGlobalBGQueue:(void (^)(void))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

+ (dispatch_queue_t)getDatabaseQueue
{
    return [SnowQueue dispatchQueue:QUEUE_LABEL_DATABASE dispatchQueueAttr:DISPATCH_QUEUE_SERIAL];
}

+ (dispatch_queue_t)getSessionQueue
{
    return [SnowQueue dispatchQueue:QUEUE_LABEL_SESSION dispatchQueueAttr:DISPATCH_QUEUE_SERIAL];
}

+ (dispatch_queue_t)getSerialQueue
{
    return [SnowQueue dispatchQueue:QUEUE_LABEL_SERIAL dispatchQueueAttr:DISPATCH_QUEUE_SERIAL];
}

+ (void)runDatabase:(void (^)(void))block
{
    [SnowQueue dispatchAsync:QUEUE_LABEL_DATABASE dispatchQueueLabel:QUEUE_LABEL_DATABASE dispatchQueueAttr:DISPATCH_QUEUE_SERIAL maxDispatchQueueCount:0
                       block:block];
}

+ (void)runDatabaseLimitedly:(SnowQueueType)queueType block:(void (^)(void))block
{
    [SnowQueue dispatchAsync:[@(queueType)stringValue] dispatchQueueLabel:QUEUE_LABEL_DATABASE dispatchQueueAttr:DISPATCH_QUEUE_SERIAL maxDispatchQueueCount:2
                       block:block];
}

+ (void)runSessionQueue:(void (^)(void))block
{
    [SnowQueue dispatchAsync:QUEUE_LABEL_SESSION dispatchQueueLabel:QUEUE_LABEL_SESSION dispatchQueueAttr:DISPATCH_QUEUE_SERIAL maxDispatchQueueCount:0
                       block:block];
}

+ (void)runSerialQueue:(void (^)(void))block
{
    [SnowQueue dispatchAsync:QUEUE_LABEL_SERIAL dispatchQueueLabel:QUEUE_LABEL_SERIAL dispatchQueueAttr:DISPATCH_QUEUE_SERIAL maxDispatchQueueCount:0
                       block:block];
}

#pragma mark - Private Methods

+ (NSMutableDictionary *)getDispatchQueueCountMap
{
    static NSMutableDictionary *dispatchQueueCountMap = nil;
    if (dispatchQueueCountMap == nil) {
        dispatchQueueCountMap = [NSMutableDictionary dictionary];
    }
    return dispatchQueueCountMap;
}

+ (NSInteger)dispatchQueueCount:(NSString *)method
{
    return [[[SnowQueue getDispatchQueueCountMap] objectForKey:method] integerValue];
}

+ (BOOL)executable:(NSString *)method maxDispatchQueueCount:(NSInteger)maxDispatchQueueCount
{
    NSInteger dispatchQueueCount = [SnowQueue dispatchQueueCount:method];
    return dispatchQueueCount < maxDispatchQueueCount;
}

+ (void)increaseDispatchQueueCount:(NSString *)method
{
    NSInteger dispatchQueueCount = [SnowQueue dispatchQueueCount:method];
    [[SnowQueue getDispatchQueueCountMap] setObject:@(dispatchQueueCount + 1) forKey:method];
}

+ (void)decreaseDispatchQueueCount:(NSString *)method
{
    NSInteger dispatchQueueCount = [SnowQueue dispatchQueueCount:method];
    [[SnowQueue getDispatchQueueCountMap] setObject:@(dispatchQueueCount - 1) forKey:method];
}

+ (dispatch_queue_t)dispatchQueue:(NSString *)dispatchQueueLabel dispatchQueueAttr:(dispatch_queue_attr_t)dispatchQueueAttr
{
    static NSMutableDictionary *dispatchQueueMap = nil;
    if (dispatchQueueMap == nil) {
        dispatchQueueMap = [NSMutableDictionary dictionary];
    }
    dispatch_queue_t dispatchQueue = nil;
    if ([dispatchQueueMap hasKey:dispatchQueueLabel]) {
        dispatchQueue = [dispatchQueueMap objectForKey:dispatchQueueLabel];
    } else {
        dispatchQueue = dispatch_queue_create([dispatchQueueLabel UTF8String], dispatchQueueAttr);
        [dispatchQueueMap setObject:dispatchQueue forKey:dispatchQueueLabel];
    }
    return dispatchQueue;
}

+ (void)dispatchAsync:(NSString *)method dispatchQueueLabel:(NSString *)dispatchQueueLabel dispatchQueueAttr:(dispatch_queue_attr_t)dispatchQueueAttr maxDispatchQueueCount:(NSInteger)maxDispatchQueueCount block:(void (^)(void))block
{
    if (maxDispatchQueueCount > 0 && [SnowQueue executable:method maxDispatchQueueCount:maxDispatchQueueCount] == NO) {
        return;
    }
    dispatch_queue_t dispatchQueue = [SnowQueue dispatchQueue:dispatchQueueLabel dispatchQueueAttr:dispatchQueueAttr];
    @synchronized(dispatchQueue)
    {
        [SnowQueue increaseDispatchQueueCount:method];
    }
    dispatch_async(dispatchQueue, ^{
        if (block != nil) {
            block();
        }
        @synchronized(dispatchQueue)
        {
            [SnowQueue decreaseDispatchQueueCount:method];
        }
    });
}

@end
