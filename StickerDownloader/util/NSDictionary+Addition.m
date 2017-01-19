//
//  NSDictionary_Addition.m
//  NaverCalendar
//
//  Created by kelly on 12. 9. 12..
//  Copyright (c) 2012년 NHN. All rights reserved.
//

#import "NSDictionary+Addition.h"

#define XML_HEADER "<?xml version='1.0' encoding='UTF-8'?>"

@implementation NSDictionary (Addtion)
- (NSString *)toXML
{
    NSMutableString *xmlString = [NSMutableString stringWithString:@""];

    //xmlString = [[NSMutableString alloc] initWithString:@"<?xml version='1.0' encoding='utf-8'?>"];
    // if body object exists encode it as form of xml.


    NSObject *value = self;
    NSArray *keys = [(NSDictionary *)value allKeys];
    for (NSString *key in keys) {
        NSObject *subValue = [(NSDictionary *)value objectForKey:key];
        NSMutableString *subXml = nil;
        if ([subValue isKindOfClass:[NSString class]]) {
            subXml = [NSMutableString stringWithString:(NSString *)subValue];
        } else if ([subValue isKindOfClass:[NSArray class]]) {
            NSUInteger size = [(NSArray *)subValue count];
            subXml = [NSMutableString stringWithString:@""];
            for (NSUInteger i = 0; i < size; i++) {
                // Elements in array should be NSDictionary.
                NSDictionary *element = (NSDictionary *)[(NSArray *)subValue objectAtIndex:i];
                [subXml appendString:[element toXML]];
            }
        } else if ([subValue isKindOfClass:[NSDictionary class]]) {
            subXml = [NSMutableString stringWithString:[(NSDictionary *)subValue toXML]];
        }

        [xmlString appendFormat:@"<%@>%@</%@>", key, subXml, key];
    }

    return xmlString;
}

- (id)objectForKeyOrNil:(id)aKey
{
    id sObject = [self objectForKey:aKey];

    if ([sObject isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        return sObject;
    }
}

- (BOOL)getBool:(NSString *)key
{
    id sObject = [self objectForKey:key];

    if (sObject == nil || [sObject isKindOfClass:[NSNull class]]) {
        return NO;
    } else {
        return [sObject boolValue];
    }
}

- (NSInteger)getInteger:(NSString *)key
{
    id sObject = [self objectForKey:key];

    if (sObject == nil || [sObject isKindOfClass:[NSNull class]]) {
        return 0;
    } else {
        return [sObject integerValue];
    }
}

- (NSInteger)integerWithKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value integerValue];
    }
    return 0;
}

- (CGFloat)floatWithKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value floatValue];
    }
    return 0.0f;
}

- (BOOL)hasKey:(id)key
{
    return key != nil && [[self allKeys] containsObject:key];
}

- (NSString *)jsonString
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return @"{}";
}


- (NSString *)stringByAligned
{
    if ([self count] <= 0)
    {
        return @"";
    }
    
    NSMutableString *sResultString = [NSMutableString string];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id akey, id aObject, BOOL *aStop) {
        if ([akey isKindOfClass:[NSString class]])
        {
            [sResultString appendString:[NSString stringWithFormat:@"%@ : %@\n", akey, aObject]];
        }
    }];
    
    return sResultString;
}


@end
