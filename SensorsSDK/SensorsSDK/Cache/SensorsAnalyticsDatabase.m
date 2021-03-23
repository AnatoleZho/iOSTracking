//
//  SensorsAnalyticsDatabase.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/24.
//

#import "SensorsAnalyticsDatabase.h"

static NSString * const SensorsAnalyticsDefaultDatabase = @"SensorsAnalyticsDatabase.sqlite";

@interface SensorsAnalyticsDatabase ()
{
    sqlite3 *_database;
}
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SensorsAnalyticsDatabase

- (instancetype)init {
    return [self initWithFilePath:nil];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath ?: [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultDatabase];
        
        // 初始化队列的唯一标识符
        NSString *label = [NSString stringWithFormat:@"sn.sensorsdata.serialQueue.%p", self];
        // 创建一个 serial 类型的 queue，即 FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        [self open];
        
        [self queryLocalDatabaseEventCount];
    }
    
    return self;
}

// 打开数据库并创建表
- (void)open {
    dispatch_async(self.queue, ^{
        // 初始化 SQLite 库
        if (sqlite3_initialize() != SQLITE_OK) {
            return NSLog(@"创建数据库失败");
        }
        
        // 打开数据库，获取数据库指针
        if (sqlite3_open_v2([self.filePath UTF8String], &(self->_database), SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            return NSLog(@"SQLite stmt prepare eror: %s", sqlite3_errmsg(self.database));
        }
        
        // 创建数据库表的 SQL 语句
        char *error;
        NSString *sql = @"CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event BLOB);";
        // 运行创建表的 SQL 语句
        if (sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, &error) != SQLITE_OK) {
            return NSLog(@"Create events Failure %s", error);
        }
    });
    
}


static sqlite3_stmt *insertStmt = NULL;

- (void)insertEvent:(NSDictionary *)event {
    dispatch_async(self.queue, ^{
//      // 定义 SQLite Statement
//        sqlite3_stmt *stmt;
//        // 插入语句
//        NSString *sql = @"INSERT INTO events (event) values (?)";
//        // 准备执行 SQL 语句，获取 sqlite3_stmt
//        if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
//            // 执行 SQL 语句失败，打印 log 返回失败
//            return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
//        }
//
//        NSError *error = nil;
//        // 将 event 转成 JSON 数据
//        NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
//        if (error) {
//            // event 转换失败，打印 log 返回失败（NO）
//            return NSLog(@"JSON Serialization error: %@", error);
//        }
//
//        // 将 JSON 数据与 stmt 绑定
//        sqlite3_bind_blob(stmt, 1, data.bytes, (int)data.length, SQLITE_TRANSIENT);
//        // 执行 stmt
//        if (sqlite3_step(stmt) != SQLITE_DONE) {
//            // 执行失败，打印 log 返回失败（NO）
//            return NSLog(@"Insert evnet into events error");
//        }

        if (insertStmt) {
            // 充值插入语句，重置之后可重新绑定数据；
            sqlite3_reset(insertStmt);
        } else {
            // 插入语句
            NSString *sql = @"INSERT INTO events (event) values (?)";
            // 准备执行 SQL 语句，获取 sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &insertStmt, NULL) != SQLITE_OK) {
                // 执行 SQL 语句失败，打印 log 返回失败
                return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            }
        }

        NSError *error = nil;
        // 将 event 转成 JSON 数据
        NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            // event 转换失败，打印 log 返回失败（NO）
            return NSLog(@"JSON Serialization error: %@", error);
        }
        
        // 将 JSON 数据与 insertStmt 绑定
        sqlite3_bind_blob(insertStmt, 1, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        // 执行 stmt
        if (sqlite3_step(insertStmt) != SQLITE_DONE) {
            // 执行失败，打印 log 返回失败（NO）
            return NSLog(@"Insert evnet into events error");
        }
        
        // 数据插入成功 事件数量加 1
        self.eventCount += 1;
    });
    


}

static sqlite3_stmt *selectStmt = NULL;
static NSUInteger lastSelectEventCount = 50;

-(NSArray<NSString *> *)selectEventsForCount:(NSUInteger)count {
    // 初始化数组，用于存储查询到的事件数据
    NSMutableArray<NSString *> *arrayM = [NSMutableArray arrayWithCapacity:count];
    
    // 若使用 dispatch_async 会导致返回事件不完整
    dispatch_sync(self.queue, ^{
        // 当本地事件数量为 0时，直接返回
        if (0 == self.eventCount) {
            return;
        }
//        // 定义 SQLite Statement
//        sqlite3_stmt *stmt;
//        // 查询语句
//        NSString *sql = [NSString stringWithFormat:@"SELECT id, event FROM events ORDER BY id ASC LIMIT %lu", (unsigned long)count];
//        // 准备执行 SQL 语句，获取 sqlite3_stmt
//        if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
//            // 准备执行 SQL 失败，打印 log 返回失败 （NO）
//            return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
//        }
//
//        // 执行语句
//        while (sqlite3_step(stmt) == SQLITE_ROW) {
//            // 将查询的这条数组转换为 NSData对象
//            NSData *data = [[NSData data] initWithBytes:sqlite3_column_blob(stmt, 1) length:sqlite3_column_bytes(stmt, 1)];
//            // 将查询语句转换成 JSON 字符串
//            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//#if DEBUG
//            NSLog(@"%@", jsonString);
//#endif
//            // 将 JSON 字符串添加到数组中
//            [arrayM addObject:jsonString];
//        }
        
        if (count != lastSelectEventCount) {
            lastSelectEventCount = count;
            selectStmt = NULL;
        }
        if (selectStmt) {
            // 重置查询语句， 重置后可重新查询数据
            sqlite3_reset(selectStmt);
        } else {
            // 查询语句
            NSString *sql = [NSString stringWithFormat:@"SELECT id, event FROM events ORDER BY id ASC LIMIT %lu", (unsigned long)count];
            // 准备执行 SQL 语句，获取 sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &selectStmt, NULL) != SQLITE_OK) {
                // 准备执行 SQL 失败，打印 log 返回失败 （NO）
                return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            }
        }
        
        // 执行语句
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            // 将查询的这条数组转换为 NSData对象
            NSData *data = [[NSData data] initWithBytes:sqlite3_column_blob(selectStmt, 1) length:sqlite3_column_bytes(selectStmt, 1)];
            // 将查询语句转换成 JSON 字符串
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#if DEBUG
            NSLog(@"%@", jsonString);
#endif
            // 将 JSON 字符串添加到数组中
            [arrayM addObject:jsonString];
        }
    });
    
    return [arrayM copy];
}

- (BOOL)deleteEventsForCount:(NSInteger)count {
    __block BOOL deleteResult = YES;
    dispatch_sync(self.queue, ^{
        // 当本地事件数量为 0时，直接返回
        if (0 == self.eventCount) {
            return;
        }
       // 删除语句
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN (SELECT id FROM events ORDER BY id ASC LIMIT %lu);",(unsigned long)count];
        char *errmsg;
        // 执行 删除语句
        if (sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, &errmsg) != SQLITE_OK) {
            deleteResult = NO;
            NSLog(@"Failed to delete record msg=%s", errmsg);
        }
    });
    return deleteResult;
}

static sqlite3_stmt *queryCountStmt;
- (void)queryLocalDatabaseEventCount {
    dispatch_async(self.queue, ^{
        // 查询语句
        NSString *sql = @"SELECT count(*) FROM events;";
        if (sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &queryCountStmt, NULL) != SQLITE_OK) {
            // 准备执行 SQL 失败，打印 log 返回失败 （NO）
            return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
        }
        while (sqlite3_step(queryCountStmt) == SQLITE_ROW) {
            self.eventCount = sqlite3_column_int(queryCountStmt, 0);
        }
    });
}

@end
