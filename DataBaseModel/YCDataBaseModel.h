//
//  YCDataBaseModel.h
//  YanceyCode
//
//  Created by 杜艳新 on 2019/6/3.
//  Copyright © 2019 杜艳新. All rights reserved.
//

#import <Foundation/Foundation.h>

/**数据库表的model封装类的抽象基类*/
@interface YCDataBaseModel : NSObject

#pragma mark -- 常用的一些sql语句，需要子类的tableName和primaryKey方法的支持
/**创建对应数据库表的sql语句*/
+ (NSString *)sqlOfCreateTable;
/**从表中批量删除记录的sql 语句*/
+ (NSString *)sqlOfDeleteWithModels:(NSArray<YCDataBaseModel *> *)models;
/**通过主键的值从表中删除记录的sql 语句*/
+ (NSString *)sqlOfDeleteWithPrimaryValues:(NSArray *)primaryValues;
/**查询所有信息*/
+ (NSString *)sqlOfQueryAll;
/**根据主键查询*/
+ (NSString *)sqlOfQuery:(NSArray *)primaryValues;
/**向表中添加记录的sql语句*/
- (NSString *)sqlOfInsert;
/**从表中删除记录的sql语句*/
- (NSString *)sqlOfDelete;
/**更新单条记录的sql语句*/
- (NSString *)sqlOfUpdate;

#pragma mark -- 抽象方法，需要子类实现
/**对应的数据库表的名称，子类必须实现*/
+ (NSString *)tableName;
/**主键名，子类必须实现*/
+ (NSString *)primaryKey;
/**主键是否需要自增，不重写为NO*/
+ (BOOL)autoIncrementPrimaryValue;

@end
