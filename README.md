## DDLog自定义上传日志使用过程
第一步：在AppDelegate中初始化DDlog配置文件，以及自定义自己所需要的功能+创建日志保存目录


```objc
- (void)setupCocoaLumberjack
{
    //log日志第三方库初始化
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    //测试
    DDLogVerbose(@"Verbose");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    
    DDLog *aDDLogInstance = [DDLog new];
    //设置控制台打印，这样才能获取到打印的信息，发送到苹果日志系统代码为：[DDLog addLogger:[DDASLLogger sharedInstance]]，本项目暂不需要
    [aDDLogInstance addLogger:[DDTTYLogger sharedInstance]];
    //设置自定义的打印格式
    [DDTTYLogger sharedInstance].logFormatter = [[CustomLogFormatter alloc] init];
    //设置log日志自定义管理类（这段代码只有在需要自定义输出路径以及自定义文件保存逻辑的时候才开启）
    CustomLogger *logger = [CustomLogger new];
    [logger setLogFormatter:[[CustomLogFormatter alloc] init]];
    [DDLog addLogger:logger];
    //测试
    DDLogVerboseToDDLog(aDDLogInstance, @"Verbose from aDDLogInstance");
    DDLogInfoToDDLog(aDDLogInstance, @"Info from aDDLogInstance");
    DDLogWarnToDDLog(aDDLogInstance, @"Warn from aDDLogInstance");
    DDLogErrorToDDLog(aDDLogInstance, @"Error from aDDLogInstance");
    //相关偏好设置
    CustomLogFileManagerDefault *ulFileManager = [[CustomLogFileManagerDefault alloc] initWithLogsDirectory:[self createFilePath] fileName:@"LAS"];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:ulFileManager];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 每个文件超过24小时后会被新的日志覆盖
//    fileLogger.rollingFrequency = 0;                        // 忽略时间回滚
    fileLogger.logFileManager.maximumNumberOfLogFiles = 5;  //最多保存5个日志文件
    fileLogger.maximumFileSize = 1024 * 500;   //每个文件数量最大尺寸为500K
    fileLogger.logFileManager.logFilesDiskQuota = 50*1024*1024;     //所有文件的尺寸最大为50M
    CustomLogFormatter *logFormatter = [[CustomLogFormatter alloc] init];
    DDContextWhitelistFilterLogFormatter *whiteLogFormatter = [[DDContextWhitelistFilterLogFormatter alloc] init];
    [whiteLogFormatter addToWhitelist:HJ_LOG_HTTP_LEVEL];
    [fileLogger setLogFormatter:logFormatter];
    [fileLogger setLogFormatter:whiteLogFormatter];
    [DDLog addLogger:fileLogger];
}

- (NSString *)createLogFilePath{
    //Caches 目录：用于存放应用程序专用的支持文件，保存应用程序再次启动过程中需要的信息。可创建子文件夹。可以用来放置您希望被备份但不希望被用户看到的数据。
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@"AppLogs"];
    return path;
}DDLogMacros.h

```

其中引用头部文件包括DDlog宏文件DDLogMacros.h以及自定义的DDlog日志上传配置文件，详情如下：

```objc
#import "AppDelegate.h"
#import "ViewController.h"
#import "CocoaLumberjack.h"
#import "DDLogMacros.h"
#import "DDContextFilterLogFormatter.h"
//以下为自定义配置文件
#import "CustomLogFormatter.h"
#import "CustomLogger.h"
#import "CustomLogFileManagerDefault.h"
```

CustomLogger配置文件中的代码：

```objc
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
```
CustomLogFormatter配置文件中的代码（遵循<DDLogFormatter>协议）：

```objc
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError : logLevel = @"❗️❗️❗️"; break;
        case DDLogFlagWarning : logLevel = @"⚠️"; break;
        case DDLogFlagInfo : logLevel = @"ℹ️"; break;
        case DDLogFlagDebug : logLevel = @"🔧"; break;
        case HJ_LOG_HTTP_LEVEL : logLevel = @"🌍"; break;
        default : logLevel = @"🚩"; break;
}
    //以上是根据不同的类型 定义不同的标记字符
    return [NSString stringWithFormat:@"🚀%@🚀 %@ %@(line:%zd)->%@: %@\n",[self getCurrentTimes], logLevel, logMessage->_fileName, logMessage->_line, logMessage->_function, logMessage->_message];
    //以上就是加入文件名 行号 方法名的
}

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
```
CustomLogFileManagerDefault继承DDLogFileManagerDefault，配置文件中的代码：

.h文件配置方法：

```objc
- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory
                             fileName:(NSString *)name;
@end
```

```objc
#import "CustomLogFileManagerDefault.h"
#import "CustomLogFormatter.h"
#import "RSA.h"
#import "SSZipArchive.h"
@interface CustomLogFileManagerDefault ()
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSString *zipFilePath;
@end
@implementation CustomLogFileManagerDefault

#pragma mark - Lifecycle

- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory
                             fileName:(NSString *)name {
    //logsDirectory日志自定义路径
    self = [super initWithLogsDirectory:logsDirectory];
    if (self) {
        self.fileName = name;
    }
    return self;
}

#pragma mark - Override methods

- (NSString *)newLogFileName {
    logUploadNum = logUploadNum + 1;
    //重写文件名称 文件名前缀+时间+序列号
    return [NSString stringWithFormat:@"%@ %@ %03ld.log", self.fileName, [self getCurrentTimes],(long)logUploadNum];
}

- (BOOL)isLogFile:(NSString *)fileName {
    //返回YES为每次重新创建文件，如果每次不需要重新创建就直接返回NO，如果有别的创建需要直接重写此方法
    return YES;
}

- (void)didArchiveLogFile:(NSString *)logFilePath
{
    NSLog(@"哈哈哈哈哈哈");
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath
{
    //当文件大小达到指定大小的时候调用  logFilePath为当前达到文件大小的文件地址
    //判断文件是否存在
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        
        //数据请求
        [self postWithFilePath:logFilePath];
    }
    else
    {
        //记录文件丢失的时间、路径
        DDLogError(@"%@-%@-%@",[self getCurrentTimes],@"===============文件丢失===============",logFilePath);
    }
}

#pragma mark - HTTP

- (void)postWithFilePath:(NSString *)filePath
{
    
//    zip压缩包保存路径
    NSString *path = [self.zipFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %03ld.zip",[self getCurrentTimes],(long)logUploadNum]];
//    需要压缩的文件
    NSArray *filesPath = @[filePath];
//    创建不带密码zip压缩包
//    [SSZipArchive createZipFileAtPath:path withFilesAtPaths:filesPath];
//    带密码的压缩，采用AES加密
    [SSZipArchive createZipFileAtPath:path withFilesAtPaths:filesPath withPassword:@"1234567"];
    //准备获取文件并上传
    NSData *data = [RSA encryptData:[NSData dataWithContentsOfFile:path] publicKey:@"电脑上生成的秘钥"];
    //上传加密后的Data
}

#pragma mark - other methods

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

#pragma mark - lazy load

- (NSString *)zipFilePath
{
    if (!_zipFilePath) {
        //Caches路径 Caches 目录：用于存放应用程序专用的支持文件，保存应用程序再次启动过程中需要的信息。可创建子文件夹。可以用来放置您希望被备份但不希望被用户看到的数据。
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _zipFilePath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@"LogOfZip"];
    }
    return _zipFilePath;
}

@end

```
以上就是自定义DDLOG中所使用的自定义类以及配置代码了，其中为了保证数据安全，用到了RSA的加密方法，实际开发过程中可以灵活应用。

（更多iOS开发干货，欢迎关注  [微博@夏目漱心 ](http://weibo.com/hanjunzhao/) ）

----------
Posted by  [微博@夏目漱心 ](http://weibo.com/hanjunzhao/))  
原创文章，版权声明：自由转载-非商用-非衍生-保持署名 |
