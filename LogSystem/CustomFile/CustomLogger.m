//
//  CustomLogger.m
//  LogSeystem
//
//  Created by zhoahanjun on 2018/7/13.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

#import "CustomLogger.h"
#import "SSZipArchive.h"
#import "RSA.h"
@interface CustomLogger ()
@property (nonatomic, strong) NSMutableArray *logMessagesArray;
@property (nonatomic, strong) NSString *logMessageStr;
/**
 打印的log信息
 */
@property (nonatomic, strong) NSString *logMessagesString;
/**
 log信息储存的问价内置 .txt文件
 */
@property (nonatomic, strong) NSString *logMessagesFilePath;
/**
 zip信息储存的问价内置 .zip文件
 */
@property (nonatomic, strong) NSString *logZipFilePath;
@end
@implementation CustomLogger

#pragma mark - =========================init=========================

- (instancetype)init{
    self = [super init];
    if (self) {
        self.deleteInterval = 0;
        self.maxAge = 0;
        //设置在每次储存时，是否删除
        self.deleteOnEverySave = NO;
        self.saveInterval = 60;
        self.saveThreshold = 500;
        //创建文件储存路径
//        [self createFilePath];
        //别忘了在 dealloc 里 removeObserver
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveOnSuspend)
                                                     name:@"UIApplicationWillResignActiveNotification"
                                                   object:nil];
    }
    return self;
}

#pragma mark - =========================SaveLogData=========================

/**
 异步线程储存
 */
- (void)saveOnSuspend {
    dispatch_async(_loggerQueue, ^{
        [self db_save];
    });
}


/**
 储存打印的信息

 @param logMessage log信息
 @return 返回是否储存成功
 */
- (BOOL)db_log:(DDLogMessage *)logMessage
{
    if (!_logFormatter) {
        //没有指定 formatter
        return NO;
    }
    if (!_logMessagesArray)
        _logMessagesArray = [NSMutableArray arrayWithCapacity:500]; // 设置储存500条日志
    if ([_logMessagesArray count] > 2000) {
        // 如果段时间内进入大量log，并且迟迟发不到服务器上，我们可以判断哪里出了问题，在这之后的 log 暂时不处理了。
        // 但我们依然要告诉 DDLog 这个存进去了。
        return YES;
    }
    //利用 formatter 得到消息字符串，添加到缓存，并加密字符串
    [_logMessagesArray addObject:[RSA encryptString:[_logFormatter formatLogMessage:logMessage] publicKey:@"电脑上生成的秘钥"]];
    return YES;
}

/**
 储存打印的信息到本地并上传服务器
 */
- (void)db_save{
    //判断是否在 logger 自己的GCD队列中
    if (![self isOnInternalLoggerQueue])
        NSAssert(NO, @"❌❌db_saveAndDelete should only be executed on the internalLoggerQueue thread, if you're seeing this, your doing it wrong.");
    //如果缓存内没数据，啥也不做
    if ([_logMessagesArray count] == 0)
        return;
    //获取缓存中所有数据，之后将缓存清空
    NSArray *oldLogMessagesArray = [_logMessagesArray copy];
    _logMessagesArray = [NSMutableArray arrayWithCapacity:0];
    //用换行符，把所有的数据拼成一个大字符串
    self.logMessagesString = [oldLogMessagesArray componentsJoinedByString:@"\n"];
    
    //将储存的文件写入本地
    NSError *error;
    [self.logMessagesString writeToFile:self.logMessagesFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"❌❌导出失败:%@",error);
    }else{
        NSLog(@"导出成功");
    }

    //对打印的日志压缩处理，如果不需要则略过
    //Caches路径 Caches 目录：用于存放应用程序专用的支持文件，保存应用程序再次启动过程中需要的信息。可创建子文件夹。可以用来放置您希望被备份但不希望被用户看到的数据。
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //创建储存Zip的文件夹
    NSString * filePath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@"LogOfZip"];
    self.logZipFilePath = filePath;
    //zip压缩包保存路径
//    NSString *path = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[self getCurrentTimes]]];
    //需要压缩的文件
//    NSArray *filesPath = @[self.logMessagesFilePath];
    //创建不带密码zip压缩包
//    [SSZipArchive createZipFileAtPath:path withFilesAtPaths:filesPath];
    //带密码的压缩，采用AES加密
//    [SSZipArchive createZipFileAtPath:path withFilesAtPaths:filesPath withPassword:@"1234567"];
    //发送给咱自己服务器，上传到服务器后再删除本地储存的Zip文件，节省手机资源空间
    [self post:self.logMessagesString];
}

#pragma mark - =========================FileManager=========================

- (NSString*)getCurrentTimes{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    //现在时间
    NSDate *datenow = [NSDate date];
    //----------将nsdate按formatter格式转成nsstring
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    NSLog(@"currentTimeString =  %@",currentTimeString);
    
    return currentTimeString;
    
}

- (BOOL)createFilePath{
    //Caches 目录：用于存放应用程序专用的支持文件，保存应用程序再次启动过程中需要的信息。可创建子文件夹。可以用来放置您希望被备份但不希望被用户看到的数据。
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@"AppLogs"];
    //文件编号
    logUploadNum  = logUploadNum + 1;
    //文件命名
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%03ld.log",[self getCurrentTimes],(long)logUploadNum]];//在传入的路径下创建log.txt"文件
    self.logMessagesFilePath = filePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if  (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {//先判断目录是否存在，不存在才创建
        BOOL res=[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        return res;
    } else return NO;
}

#pragma mark - =========================HTTP=========================

- (void)post:(NSString *)logMessagesString{
    //拿到Zip目录，转换成NSDA或者后台支持的其他格式，上传到服务器
    
}
@end
