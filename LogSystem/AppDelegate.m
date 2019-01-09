//
//  AppDelegate.m
//  LogSystem
//
//  Created by zhoahanjun on 2018/7/18.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CocoaLumberjack.h"
#import "DDLogMacros.h"

#import "CustomLogFormatter.h"
#import "CustomLogger.h"
#import "CustomLogFileManagerDefault.h"
#import "DDContextFilterLogFormatter.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[ViewController alloc] init];
    //初始化日志输出系统
    [self setupCocoaLumberjack];
    return YES;
}

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

- (NSString *)createFilePath{
    //Caches 目录：用于存放应用程序专用的支持文件，保存应用程序再次启动过程中需要的信息。可创建子文件夹。可以用来放置您希望被备份但不希望被用户看到的数据。
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@"AppLogs"];
    return path;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
