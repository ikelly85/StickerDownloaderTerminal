//
//  SnowQueue.h
//  chat
//
//  Created by HAN on 2016. 5. 23..
//  Copyright © 2016년 campmobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SnowQueueTypeGetChatChannelList,
    SnowQueueTypeUpdateBadgeCount
}SnowQueueType;

@interface SnowQueue : NSObject

+ (void)runMainQueue:(void (^)(void))block;
+ (void)runMainQueueAfter:(CGFloat)second block:(void (^)(void))block;
+ (void)runGlobalQueue:(void (^)(void))block;
+ (void)runGlobalHighQueue:(void (^)(void))block;
+ (void)runGlobalBGQueue:(void (^)(void))block;

+ (dispatch_queue_t)getDatabaseQueue;
+ (dispatch_queue_t)getSessionQueue;
+ (dispatch_queue_t)getSerialQueue;

+ (void)runSessionQueue:(void (^)(void))block;
+ (void)runDatabase:(void (^)(void))block;
+ (void)runDatabaseLimitedly:(SnowQueueType)queueType block:(void (^)(void))block;
+ (void)runSerialQueue:(void (^)(void))block;

@end
