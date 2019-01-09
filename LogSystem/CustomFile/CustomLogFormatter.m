//
//  LogFormatter.m
//  LogSeystem
//
//  Created by zhoahanjun on 2018/7/13.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

#import "CustomLogFormatter.h"

@interface CustomLogFormatter () 
@end
@implementation CustomLogFormatter

//- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
//    NSMutableDictionary *logDict = [NSMutableDictionary dictionary];
//    //取得文件名
//    NSString *locationString;
//    NSArray *parts = [logMessage->_file componentsSeparatedByString:@"/"];
//    if ([parts count] > 0)
//        locationString = [parts lastObject];
//    if ([locationString length] == 0)
//        locationString = @"No file";
//    //这里的格式: {"location":"myfile.m:120(void a::sub(int)"}， 文件名，行数和函数名是用的编译器宏 __FILE__, __LINE__, __PRETTY_FUNCTION__
//    logDict[@"location"] = [NSString stringWithFormat:@"%@:%lu(%@)", locationString, (unsigned long)logMessage->_line, logMessage->_function]
//    //尝试将logDict内容转为字符串，其实这里可以直接构造字符串，但真实项目中，肯定需要很多其他的信息，不可能仅仅文件名、行数和函数名就够了的。
//    NSError *error;
//    NSData *outputJson = [NSJSONSerialization dataWithJSONObject:logfields options:0 error:&error];
//    if (error)
//        return @"{\"location\":\"error\"}"
//        NSString *jsonString = [[NSString alloc] initWithData:outputJson encoding:NSUTF8StringEncoding];
//    if (jsonString)
//        return jsonString;
//    return @"{\"location\":\"error\"}"
//}

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


@end
