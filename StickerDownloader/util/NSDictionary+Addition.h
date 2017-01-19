//
//  NSDictionary_Addition.h
//  NaverCalendar
//
//  Created by kelly on 12. 9. 12..
//  Copyright (c) 2012년 NHN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Addition)

- (NSString *)toXML;
- (id)objectForKeyOrNil:(id)aKey;
- (BOOL)getBool:(NSString *)key;
- (NSInteger)getInteger:(NSString *)key;

- (NSInteger)integerWithKey:(NSString *)key;
- (CGFloat)floatWithKey:(NSString *)key;
- (BOOL)hasKey:(id)key;
- (NSString *)jsonString;
- (NSString *)stringByAligned;

@end
