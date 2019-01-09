//
//  CustomLogFileManagerDefault.m
//  LogSystem
//
//  Created by zhoahanjun on 2018/7/24.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

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
