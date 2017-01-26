// AFAppDotNetAPIClient.h
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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

#import "AFAppDotNetAPIClient.h"

static NSString *AFAppDotNetAPIBaseURLString = @"http://dev.admin.snow.me/api/sticker/";

@implementation AFAppDotNetAPIClient

+ (instancetype)sharedClient {
    static AFAppDotNetAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"dev"]) {
            AFAppDotNetAPIBaseURLString = @"http://dev.admin.snow.me/api/sticker/";
        } else if ([[[NSProcessInfo processInfo] arguments] containsObject:@"qa"]) {
            AFAppDotNetAPIBaseURLString = @"http://qa.admin.snow.me/api/sticker/";
        } else if ([[[NSProcessInfo processInfo] arguments] containsObject:@"stage"] || [[[NSProcessInfo processInfo] arguments] containsObject:@"real"]) {
            AFAppDotNetAPIBaseURLString = @"http://admin.snow.me/api/sticker/";
        }
        
        _sharedClient = [[AFAppDotNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:AFAppDotNetAPIBaseURLString]];
        
    });
    
    return _sharedClient;
}

@end
