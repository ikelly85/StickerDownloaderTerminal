//
//  BannerEventThumbnailWorker.m
//  chat
//
//  Created by kelly on 2015. 10. 22..
//  Copyright © 2015년 campmobile. All rights reserved.
//

#import "ThumbnailWorker.h"
#import "ObjectiveCUtil.h"
#import "CommonUtil.h"
#import "Post.h"
#import "PostSticker.h"
#import "StringUtils.h"
#import "Application.h"
#import "SnowQueue.h"

@implementation ThumbnailWorker

SYNTHESIZE_SINGLETON_CLASS(ThumbnailWorker, sharedInstance);

- (NSString *)makePath:(NSString *)thumbnail index:(NSInteger)index
{
    NSString *targetId = nil;
    if (index < [[[Application sharedInstance] getPackDownloads] count]) {
        Post *post = [[[Application sharedInstance] getPackDownloads] objectAtIndex:index];
        if ([StringUtils equals:post.thumbnailOn andString:thumbnail]) {
            targetId = post.stickerPackId;
        }
    }
    
    if (index < [[[Application sharedInstance] getItemDownloads] count]) {
        PostSticker *post = [[[Application sharedInstance] getItemDownloads] objectAtIndex:index];
        if ([StringUtils equals:post.thumbnail andString:thumbnail]) {
            targetId = post.stickerId;
        }
    }
    
    NSString *fileName = targetId;
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileNamePath = [NSString stringWithFormat:@"postSticker/images/%@@3x.png", fileName];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileNamePath];

    return filePath;
}

- (BOOL)processJob
{
    __block BOOL find = NO;
    
    dispatch_sync([SnowQueue getSerialQueue], ^{
        if ([CommonUtil isEmptyMap:thumbnailUrlMap]) {
            if (!session) {
                session = [self URLsession];
            }
            
            thumbnailUrlMap = [NSMutableDictionary dictionary];
            
            NSMutableArray *thumbnailList = [NSMutableArray array];
            for (Post *post in [[Application sharedInstance] getPackDownloads]) {
                if ([StringUtils isNotEmpty:post.thumbnailOn]) {
                    [thumbnailList addObject:post.thumbnailOn];
                }
            }
            [self setThumbnailUrlMapOn:thumbnailList];
            
            [thumbnailList removeAllObjects];
            for (PostSticker *postSticker in [[Application sharedInstance] getItemDownloads]) {
                if ([StringUtils isNotEmpty:postSticker.thumbnail]) {
                    [thumbnailList addObject:postSticker.thumbnail];
                }
            }
            [self setThumbnailUrlMapOn:thumbnailList];
            
            if ([CommonUtil isNotEmptyMap:thumbnailUrlMap]) {
                find = YES;
            }
        }
    });
    
    if (find) {
        [self download];
    }
    
    return NO;
}

- (void)setThumbnailUrlMapOn:(NSArray *)thumbnailList
{
    if ([CommonUtil isEmptyList:thumbnailList]) {
        return;
    }
    
    NSInteger i = 0;
    for (NSString *thumbnail in thumbnailList) {
        @synchronized (thumbnailUrlMap) {
            [thumbnailUrlMap setObject:@(i) forKey:thumbnail];
        }
        i++;
    }
}

- (NSURLSession *)URLsession
{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    sessionConfig.timeoutIntervalForResource = 300;
    sessionConfig.timeoutIntervalForRequest = 300;
    sessionConfig.networkServiceType = NSURLNetworkServiceTypeBackground;
    NSURLSession *_session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    return _session;
}

- (void)download
{
    __block NSString *serverPath = nil;
    __block NSInteger index = -1;
    
    dispatch_sync([SnowQueue getSerialQueue], ^{
        serverPath = [[thumbnailUrlMap allKeys] firstObject];
        index = [[thumbnailUrlMap objectForKey:serverPath] integerValue];
        [thumbnailUrlMap removeObjectForKey:serverPath];
    });
    
    NSURL *url = nil;
    if ([serverPath hasPrefix:@"http"]) {
        url = [NSURL URLWithString:serverPath];
    } else {
        NSString *baseServerPath = @"http://dev-fs.snow.me";
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"dev"]) {
            baseServerPath = @"http://dev-fs.snow.me";
        } else if ([[[NSProcessInfo processInfo] arguments] containsObject:@"test"]) {
           baseServerPath = @"http://qa-fs.snow.me";
        } else if ([[[NSProcessInfo processInfo] arguments] containsObject:@"stage"] || [[[NSProcessInfo processInfo] arguments] containsObject:@"real"]) {
            baseServerPath = @"http://kr-fs.snow.me";
        }
        
        NSMutableString *serverFullUrl = [NSMutableString stringWithString:baseServerPath];
        if ([serverPath hasPrefix:@"/"]) {
            [serverFullUrl appendString:serverPath];
        } else {
            [serverFullUrl appendFormat:@"/%@", serverPath];
        }
        
        url = [NSURL URLWithString:serverFullUrl];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDownloadTask *downloadTask;

    downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                        __block BOOL isLast = NO;
                        
                        dispatch_sync([SnowQueue getSerialQueue], ^{
                            isLast = (thumbnailUrlMap.count == 0);
                        });
        
                        if (error) {
                            [self onFailureImage:error];
                        } else {
                            [self onSucceessImage:[location path] serverPath:serverPath isLast:isLast index:index];
                            if (isLast) {
                                session = nil;
                            }
                        }
        
                        if (!isLast) {
                            [self download];
                        }
                    }];


    downloadTask.priority = 0.0f;//NSURLSessionTaskPriorityLow;
    [downloadTask resume];
}

- (void)onSucceessImage:(NSString *)localFilePath serverPath:(NSString *)serverPath isLast:(BOOL)isLast index:(NSInteger)index
{
    NSString *saveImagePath = [self makePath:serverPath index:index];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:saveImagePath];
    if (fileExists) {
        [fileManager removeItemAtPath:saveImagePath error:nil];
    }

    BOOL success = [fileManager moveItemAtPath:localFilePath toPath:saveImagePath error:nil];
    if (!success) {
        [self onFailureImage:nil];
        return;
    }

    if (isLast) {
        [[Application sharedInstance] exportFile];
    }
}

- (void)onFailureImage:(NSError *)error
{
    NSLog(@"fail image");
}

- (void)doFinish
{
    [super doFinish];
}

@end
