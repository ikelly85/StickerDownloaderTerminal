//
//  Application.h
//  StickerDownloader
//
//  Created by kelly on 2017. 1. 12..
//  Copyright © 2017년 SNOW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExportPacks.h"
#import "ExportStickers.h"

@interface Application : NSObject
+ (Application *)sharedInstance;
- (NSMutableArray *)getPackDownloads;
- (NSMutableArray *)getItemDownloads;
- (void)go;
- (void)exportFile;

@property (strong, nonatomic) ExportPacks *exportPacks;
@property (strong, nonatomic) ExportStickers *exportStickers;
@end
