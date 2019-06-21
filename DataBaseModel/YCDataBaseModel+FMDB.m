//
//  YCDataBaseModel+FMDB.m
//  YanceyCode
//
//  Created by 杜艳新 on 2019/6/3.
//  Copyright © 2019 杜艳新. All rights reserved.
//

#import "YCDataBaseModel+FMDB.h"
#import <objc/runtime.h>

@implementation YCDataBaseModel (FMDB)

//使用FMDB的result set生成Model的快速初始化方法
+ (instancetype _Nullable)modelWithResultSet:(FMResultSet *_Nullable)rs {
    if(!rs) return nil;
    //不能使用YCDataBaseModel的alloc，要使用self.class，因为是子类调用
    YCDataBaseModel *model = [[self.class alloc] init];
    //获得属性列表
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self.class, &propertyCount);
    //遍历属性列表
    for(NSInteger i = 0; i < propertyCount; i++) {
        //得到属性、属性名、属性类型
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        const char *type = property_getAttributes(property);
        NSString *propertyType = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        //根据属性类型决定result set需要调用的取值方法
        id propertyValue = [self resultSetValue:rs ofPropertyType:propertyType propertyName:propertyName];
        [model setValue:propertyValue forKey:propertyName];
    }
    free(properties);
    return model;
}


//根据属性类型决定result set需要调用的取值方法
+ (id)resultSetValue:(FMResultSet *)rs ofPropertyType:(NSString *)propertyType propertyName:(NSString *)propertyName {
    //字符串类型
    if([propertyType hasPrefix:@"T@\"NSString\""]) {
        return [rs stringForColumn:propertyName];
    }
    //NSData
    else if([propertyType hasPrefix:@"T@\"NSData\""]) {
        return [rs dataForColumn:propertyName];
    }
    //布尔
    else if([propertyType hasPrefix:@"TB"]) {
        return @([rs boolForColumn:propertyName]);
    }
    //整型
    else if([propertyType hasPrefix:@"Tc"]
            || [propertyType hasPrefix:@"TC"]
            || [propertyType hasPrefix:@"Ts"]
            || [propertyType hasPrefix:@"TS"]
            || [propertyType hasPrefix:@"Ti"]
            || [propertyType hasPrefix:@"TI"]) {
        return @([rs intForColumn:propertyName]);
    }
    //长整型
    else if([propertyType hasPrefix:@"Tq"]) {
        return @([rs longLongIntForColumn:propertyName]);
    }
    //无符号长整型
    else if([propertyType hasPrefix:@"TQ"]) {
        return @([rs unsignedLongLongIntForColumn:propertyName]);
    } else if([propertyType hasPrefix:@"Tf"]
              || [propertyType hasPrefix:@"Td"]) {
        return @([rs doubleForColumn:propertyName]);
    }
    return nil;
}

@end
