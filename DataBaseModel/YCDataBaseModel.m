//
//  YCDataBaseModel.m
//  YanceyCode
//
//  Created by 杜艳新 on 2019/6/3.
//  Copyright © 2019 杜艳新. All rights reserved.
//

#import "YCDataBaseModel.h"
#import <objc/runtime.h>

@implementation YCDataBaseModel

//创建数据库表的sql语句，主键自增
+ (NSString *)sqlOfCreateTablePrimaryKeyAutoIncrement {
    //属性与数据类型的映射表
    NSDictionary <NSString *, NSString *> *propertyMap = [self propertyTypeMap];
    //拼装sql语句
    NSMutableString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",[self tableName]].mutableCopy;
    for(NSString *key in propertyMap.allKeys) {
        if([propertyMap[key] isEqualToString:[self primaryKey]]) {
            [sql appendFormat:@"%@ %@ PRIMARY KEY AUTOINCREMENT NOT NULL,", key, propertyMap[key]];
        } else {
            [sql appendFormat:@"%@ %@,", key, propertyMap[key]];
        }
    }
    [sql deleteCharactersInRange:[sql rangeOfString:@"," options:NSBackwardsSearch]];
    //添加结尾的")"号
    [sql appendString:@")"];
    return sql.copy;
}
//创建对应数据库表的sql语句
+ (NSString *)sqlOfCreateTable {
    //属性与数据类型的映射表
    NSDictionary <NSString *, NSString *> *propertyMap = [self propertyTypeMap];
    //拼装sql语句
    NSMutableString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",[self tableName]].mutableCopy;
    for(NSString *key in propertyMap.allKeys) {
        if([key isEqualToString:[self primaryKey]]) {
            if([self autoIncrementPrimaryValue]) {
                [sql appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,", key];
            } else {
                [sql appendFormat:@"%@ %@ PRIMARY KEY NOT NULL,", key, propertyMap[key]];
            }
        } else {
            [sql appendFormat:@"%@ %@,", key, propertyMap[key]];
        }
    }
    //删除多余的逗号，并添加结尾的")"号
    [sql replaceCharactersInRange:NSMakeRange(sql.length - 1, 1) withString:@")"];
    return sql.copy;
}
//向表中添加记录的sql语句
- (NSString *)sqlOfInsert {
    //找到需要插入的属性数据
    NSDictionary <NSString *, id> *propertyMap = [self propertyValueMap];
    //拼装sql语句
    NSMutableString *sqlPrefix = [NSString stringWithFormat:@"INSERT INTO %@ (",[self.class tableName]].mutableCopy;
    NSMutableString *sqlSuffix = [NSString stringWithFormat:@" VALUES ("].mutableCopy;
    //遍历所有参数
    for(NSString *key in propertyMap.allKeys) {
        //如果是主键，并且有设置主键自增，则不在语句中添加这段
        if([key isEqualToString:[self.class primaryKey]] && [self.class autoIncrementPrimaryValue] && [propertyMap[key] integerValue] == 0) continue;
        //判断值类型，只有NSNumber类型和NSString类型才是有效类型
        id value = propertyMap[key];
        if([value isKindOfClass:NSNumber.class]) {
            [sqlPrefix appendFormat:@"%@,", key];
            [sqlSuffix appendFormat:@"%@,", value];
        }
        //字符串类型要在值前后加上单引号
        else if([value isKindOfClass:NSString.class]) {
            [sqlPrefix appendFormat:@"%@,", key];
            [sqlSuffix appendFormat:@"'%@',", value];
        }
    }
    //防止数据异常引起崩溃
    if(![sqlPrefix containsString:@","] || ![sqlPrefix containsString:@","]) return @"";
    //删除多加的","号
    [sqlPrefix deleteCharactersInRange:[sqlPrefix rangeOfString:@"," options:NSBackwardsSearch]];
    [sqlSuffix deleteCharactersInRange:[sqlSuffix rangeOfString:@"," options:NSBackwardsSearch]];
    //添加结尾的")"号
    [sqlPrefix appendString:@")"];
    [sqlSuffix appendString:@")"];
    //拼成完整的语句
    NSString *sql = [NSString stringWithFormat:@"%@%@",sqlPrefix,sqlSuffix];
    return sql;
}
//从表中删除记录的sql语句
- (NSString *)sqlOfDelete {
    //找到主键的值
    NSString *primaryValue = [self valueForKey:[self.class primaryKey]];
    //通过主键生成sql语句
    NSString *sql = [self.class sqlOfDeleteWithPrimaryValues:@[primaryValue]];
    return sql;
}
//从表中批量删除记录的sql 语句
+ (NSString *)sqlOfDeleteWithModels:(NSArray<YCDataBaseModel *> *)models {
    //找到所有主键的值拼成数组
    NSMutableArray<NSString *> *primaryValues = [NSMutableArray arrayWithCapacity:models.count];
    for(YCDataBaseModel *model in models) {
        id primaryValue = [model valueForKey:[model.class primaryKey]];
        if(primaryValue) [primaryValues addObject:primaryValue];
    }
    //调用sqlOfDeleteWithPrimaryValues:方法
    return [self sqlOfDeleteWithPrimaryValues:primaryValues.copy];
}
//通过主键的值从表中删除记录的sql 语句
+ (NSString *)sqlOfDeleteWithPrimaryValues:(NSArray<NSString *> *)primaryValues {
    NSMutableString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ in (", [self tableName], [self primaryKey]].mutableCopy;
    for(NSString *value in primaryValues) {
        if([value isKindOfClass:NSNumber.class]) {
            [sql appendFormat:@"%@,", value];
        } else if([value isKindOfClass:NSString.class]) {
            [sql appendFormat:@"'%@',", value];
        }
    }
    //防止数据异常引起崩溃
    if(![sql containsString:@","]) return @"";
    //删除多拼的","
    [sql deleteCharactersInRange:[sql rangeOfString:@"," options:NSBackwardsSearch]];
    //拼接最后的"]"
    [sql appendString:@")"];
    return sql.copy;
}
//更新单条数据记录的sql语句
- (NSString *)sqlOfUpdate {
    //找到model中有意义的属性和值
    NSDictionary <NSString *, NSString *> *propertyMap = [self propertyValueMap];
    //拼装sql语句
    NSMutableString *sql = [NSString stringWithFormat:@"UPDATE %@ SET ",[self.class tableName]].mutableCopy;
    for(NSString *key in propertyMap.allKeys) {
        //主键不更新
        if([key isEqualToString:[self.class primaryKey]]) continue;
        id value = propertyMap[key];
        //拼接更新语句
        if([value isKindOfClass:NSNumber.class]) {
            [sql appendFormat:@"%@ = %@,", key, value];
        } else if([value isKindOfClass:NSString.class]) {
            [sql appendFormat:@"%@ = '%@',", key, value];
        }
    }
    //防止数据异常引起崩溃
    if(![sql containsString:@","]) return @"";
    //去掉多加的","
    [sql deleteCharactersInRange:[sql rangeOfString:@"," options:NSBackwardsSearch]];
    //加上主键条件
    [sql appendFormat:@" where %@ = '%@'", [self.class primaryKey], propertyMap[[self.class primaryKey]]];
    return sql.copy;
}
//查询所有信息
+ (NSString *)sqlOfQueryAll {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", [self tableName]];
    return sql;
}
//根据主键查询
+ (NSString *)sqlOfQuery:(NSArray *)primaryValues {
    //数据为空的时候，for循环进不去，在delete逗号的时候会崩
    if(!primaryValues || ![primaryValues isKindOfClass:NSArray.class] || primaryValues.count == 0) {
        return @"";
    }
    //拼装sql语句
    NSMutableString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ in (", [self tableName], [self primaryKey]].mutableCopy;
    for(NSString *value in primaryValues) {
        if([value isKindOfClass:NSNumber.class]) {
            [sql appendFormat:@"%@,", value];
        } else if([value isKindOfClass:NSString.class]) {
            [sql appendFormat:@"'%@',", value];
        }
    }
    //防止数据异常引起崩溃
    if(![sql containsString:@","]) return @"";
    //删除多加的","
    [sql deleteCharactersInRange:[sql rangeOfString:@"," options:NSBackwardsSearch]];
    //加上最后的"]"
    [sql appendString:@")"];
    return sql.copy;
}

#pragma mark -- 抽象方法
+ (NSString *)tableName {
    return @"";
}
+ (NSString *)primaryKey {
    return @"";
}
/**主键是否需要自增*/
+ (BOOL)autoIncrementPrimaryValue {
    return NO;
}


#pragma mark -- 内部方法
//将子类的属性名和对应的数据库数据类型组成字典
+ (NSDictionary *)propertyTypeMap {
    //保存返回值
    NSMutableDictionary *map = @{}.mutableCopy;
    //获得属性列表
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self.class, &propertyCount);
    //遍历属性列表
    for(NSInteger i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        //属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        //整型数据类型与位数的关系
        //"Tc" : 8位，"Ts" : 16位，"Ti" : 32位，"Tq" : 64位。大写为无符号类型，位数相同。
        //"TB"为布尔型，"T@"为对象类型，后面紧跟引号，引号内为对象类型名，如"T@\"NSString\""。
        //字符串
        if ([propertyType hasPrefix:@"T@\"NSString\""]) {
            [map setObject:@"text" forKey:propertyName];
        }
        //64位整型
        else if ([propertyType hasPrefix:@"Tq"] || [propertyType hasPrefix:@"TQ"]) {
            [map setObject:@"bigint" forKey:propertyName];
        }
        //32位整型
        else if ([propertyType hasPrefix:@"Ti"] || [propertyType hasPrefix:@"TI"]) {
            [map setObject:@"int" forKey:propertyName];
        }
        //16位整型
        else if ([propertyType hasPrefix:@"Ts"] || [propertyType hasPrefix:@"TS"]) {
            [map setObject:@"smallint" forKey:propertyName];
        }
        //BOOL型和8位整型
        else if ([propertyType hasPrefix:@"TB"] || [propertyType hasPrefix:@"Tc"] || [propertyType hasPrefix:@"TC"]) {
            [map setObject:@"tinyint" forKey:propertyName];
        }
        //实数型
        else if ([propertyType hasPrefix:@"Tf"] || [propertyType hasPrefix:@"Td"]) {
            [map setObject:@"real" forKey:propertyName];
        }
    }
    return map.copy;
}
//将子类的属性和值转为字典
- (NSDictionary *)propertyValueMap {
    //保存返回值
    NSMutableDictionary *map = @{}.mutableCopy;
    //获得属性列表
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self.class, &propertyCount);
    //遍历属性列表
    for(NSInteger i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        //属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        //属性值
        id propertyValue = [self valueForKey:propertyName];
        //有可能为nil，需要判断一下。
        if(propertyValue) [map setObject:propertyValue forKey:propertyName];
    }
    return map.copy;
}

@end
