//
//  CustomLogFileManagerDefault.h
//  LogSystem
//
//  Created by zhoahanjun on 2018/7/24.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

#import "DDFileLogger.h"

@interface CustomLogFileManagerDefault : DDLogFileManagerDefault
- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory
                             fileName:(NSString *)name;
@end
