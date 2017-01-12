//
//  main.m
//  StickerDownloader
//
//  Created by kelly on 2017. 1. 12..
//  Copyright © 2017년 SNOW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Application.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSString *applicationPath = [[NSBundle mainBundle] bundlePath];
        NSLog(@"Hello, World! %@", applicationPath);
        
        [[Application sharedInstance] go];
        
        while (1)
        {
            SInt32 res = 0;
            @autoreleasepool
            {
                res = CFRunLoopRunInMode(kCFRunLoopDefaultMode, DBL_MAX, false);
            }
            
            if (kCFRunLoopRunStopped == res || kCFRunLoopRunFinished == res) {
                break;
            }
        }
        
    }
    return 0;
}
