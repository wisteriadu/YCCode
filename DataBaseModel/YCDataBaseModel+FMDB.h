//
//  YCDataBaseModel+FMDB.h
//  YanceyCode
//
//  Created by 杜艳新 on 2019/6/3.
//  Copyright © 2019 杜艳新. All rights reserved.
//

#import "YCDataBaseModel.h"
#import "FMDB.h"

/**数据库表的model封装类的抽象基类，对FMDB做的定制封装*/
@interface YCDataBaseModel (FMDB)

/**使用FMDB的result set生成Model的快速初始化方法*/
+ (instancetype _Nullable)modelWithResultSet:(FMResultSet *_Nullable)rs;

@end
