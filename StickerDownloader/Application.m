//
//  Application.m
//  StickerDownloader
//
//  Created by kelly on 2017. 1. 12..
//  Copyright © 2017년 SNOW. All rights reserved.
//

#import "Application.h"
#import "ObjectiveCUtil.h"
#import "Post.h"
#import "PostSticker.h"
#import "ThumbnailWorker.h"
#import "StringUtils.h"
#import "ContentsModel.h"

@implementation Application
{
    NSMutableArray *packDownloads;
    NSMutableArray *itemDownloads;
    NSFileManager *fileManager;
    dispatch_semaphore_t semaphore;
}

SYNTHESIZE_SINGLETON_CLASS(Application, sharedInstance);

- (instancetype)init
{
    self = [super init];
    return self;
}

- (NSMutableArray *)getPackDownloads
{
    return packDownloads;
}

- (NSMutableArray *)getItemDownloads
{
    return itemDownloads;
}

- (void)go
{
    fileManager = [NSFileManager defaultManager];
    
    [self makeDir];
    
    packDownloads = [NSMutableArray array];
    itemDownloads = [NSMutableArray array];
    
    [Post globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (error) {
            exit(-1);
            return;
        }
        
        __block NSInteger i = 0;
        for (Post *post in posts) {
            [packDownloads addObject:post];
            
            [PostSticker globalTimelinePostsWithBlock:post.stickerPackSeq stickerPackId:post.stickerPackId block:^(NSArray *postStickers, NSError *error) {
                if (postStickers && [postStickers count] > 0) {
                    for (PostSticker *postSticker in postStickers) {
                        [itemDownloads addObject:postSticker];
                    }
                }
                
                if (i == [posts count] - 1) {
                    [self download];
                }
                
                i++;
            }];
        }
        
    }];
}

- (void)makeDir
{
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *postStickerPath = [documentsPath stringByAppendingPathComponent:@"postSticker"];
    if (![fileManager fileExistsAtPath:postStickerPath]) {
        [fileManager createDirectoryAtPath:postStickerPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *imagesPath = [postStickerPath stringByAppendingPathComponent:@"images"];
    if (![fileManager fileExistsAtPath:imagesPath]) {
        [fileManager createDirectoryAtPath:imagesPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
}

- (void)download
{
    [[ThumbnailWorker sharedInstance] notify];
}

- (void)cleansing
{
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    NSString *assetPath = [applicationPath stringByAppendingPathComponent:@"Images.xcassets/post_stickers"];
    
    [fileManager removeItemAtPath:assetPath error:nil];
    [fileManager createDirectoryAtPath:assetPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    ContentsModel *contentsModel = [ContentsModel new];
    InfoModel *infoModel = [InfoModel new];
    [infoModel setAuthor:@"xcode"];
    [infoModel setVersion:1];
    [contentsModel setInfo:infoModel];
    
    NSString *jsonText = [contentsModel toJSONString];
    NSString *contentsFilePath = [assetPath stringByAppendingPathComponent:@"Contents.json"];
    if (![fileManager fileExistsAtPath:contentsFilePath]) {
        [fileManager createFileAtPath:contentsFilePath contents:nil attributes:nil];
    }
    
    [[jsonText dataUsingEncoding:NSUTF8StringEncoding] writeToFile:contentsFilePath atomically:NO];
}

- (void)exportFile
{
    ExportPacks *exportPacks = [ExportPacks new];
    [exportPacks setStickerPackList:(NSArray <Post> *)packDownloads];
    _exportPacks = exportPacks;
    
    ExportStickers *exportStickers = [ExportStickers new];
    [exportStickers setStickerList:(NSArray <PostSticker> *)itemDownloads];
    _exportStickers = exportStickers;
    
    [self writeStringToFile:[_exportPacks toJSONString] fileName:@"pack"];
    [self writeStringToFile:[_exportStickers toJSONString] fileName:@"sticker"];
    
    [self cleansing];
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *docResourcePath = [docPath stringByAppendingPathComponent:@"postSticker"];
    
    NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
    NSString *assetPath = [applicationPath stringByAppendingPathComponent:@"Images.xcassets/post_stickers"];
    
    
    NSURL *directoryURL = [NSURL fileURLWithPath:docResourcePath isDirectory:YES];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            // handle error
        } else {
            // No error and it’s not a directory; do something with the file
            if (![isDirectory boolValue]) {
                if ([url.lastPathComponent hasSuffix:@".json"]) {
                    NSString *jsonResourcePath = [applicationPath stringByAppendingPathComponent:@"Resources/postSticker"];
                    NSURL *destURL = [NSURL fileURLWithPath:[jsonResourcePath stringByAppendingPathComponent:url.lastPathComponent] isDirectory:NO];
                    [fileManager copyItemAtURL:url toURL:destURL error:&error];
                } else if ([url.lastPathComponent hasSuffix:@"@3x.png"]) {
                    NSString *assetImage = [[url.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"@3x" withString:@""];
                    NSString *assetImageFolderName = [assetImage stringByAppendingString:@".imageset"];
                    NSString *assetImageFolder = [assetPath stringByAppendingPathComponent:assetImageFolderName];
                    [fileManager createDirectoryAtPath:assetImageFolder withIntermediateDirectories:NO attributes:nil error:nil];
                    
                    NSURL *destURL = [NSURL fileURLWithPath:[assetImageFolder stringByAppendingPathComponent:url.lastPathComponent] isDirectory:NO];
                    [fileManager copyItemAtURL:url toURL:destURL error:&error];
                    
                    ContentsModel *contentsModel = [ContentsModel new];
                    ImageModel *imageModel = [ImageModel new];
                    [imageModel setIdiom:@"universal"];
                    [imageModel setFilename:url.lastPathComponent];
                    [imageModel setScale:@"3x"];
                    [contentsModel setImages:(NSArray <ImageModel> *)@[imageModel]];
                    
                    InfoModel *infoModel = [InfoModel new];
                    [infoModel setAuthor:@"xcode"];
                    [infoModel setVersion:1];
                    [contentsModel setInfo:infoModel];
                    
                    NSString *jsonText = [contentsModel toJSONString];
                    NSString *contentsFilePath = [assetImageFolder stringByAppendingPathComponent:@"Contents.json"];
                    if (![fileManager fileExistsAtPath:contentsFilePath]) {
                        [fileManager createFileAtPath:contentsFilePath contents:nil attributes:nil];
                    }
                    
                    [[jsonText dataUsingEncoding:NSUTF8StringEncoding] writeToFile:contentsFilePath atomically:NO];
                }
            }
        }
    }
        
    [fileManager removeItemAtPath:docResourcePath error:nil];
    exit(0);
}

- (void)writeStringToFile:(NSString *)jsonString fileName:(NSString *)fileName
{
    // Build the path, and create if needed.
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *fileNamePath = [NSString stringWithFormat:@"postSticker/%@.json", fileName];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileNamePath];
    
    if (![fileManager fileExistsAtPath:fileAtPath]) {
        [fileManager createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
    
    // The main act...
    [[jsonString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:NO];
}

@end
