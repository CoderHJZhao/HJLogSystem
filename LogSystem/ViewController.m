//
//  ViewController.m
//  LogSeystem
//
//  Created by zhoahanjun on 2018/7/13.
//  Copyright © 2018年 zhoahanjun. All rights reserved.
//

#import "ViewController.h"
#import "CocoaLumberjack.h"
#import "DDLogMacros.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
@interface ViewController ()
/**
 粒子动画Layer层
 */
@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@end

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additionral setup after loading the view, typically from a nib.
    //使他的中心点为父视图的中心点，
    self.emitterLayer.emitterPosition = self.view.center;
    self.view.backgroundColor = [UIColor blackColor];
    //先设置粒子发送器的属性
    //设置粒子发送器每秒钟发送粒子数量
    self.emitterLayer.birthRate = 2;
    //设置粒子发送器的样式
    self.emitterLayer.renderMode = kCAEmitterLayerAdditive;
    //初始化要发射的cell
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    //contents:粒子的内容
    cell.contents = (id)[UIImage imageNamed:@"image"].CGImage;//他所需要对象类型的和图层类似
    //接着设置cell的属性
    //    粒子的出生量
    cell.birthRate = 2;
    //    存活时间
    cell.lifetime = 3;
    cell.lifetimeRange = 1;
    //    设置粒子发送速度
    cell.velocity = 50;
    cell.velocityRange = 30;
    //    粒子发送的方向
    cell.emissionLatitude = 90*M_PI/180;
    //    发送粒子的加速度
    cell.yAcceleration = -100;
    
    //    散发粒子的范围  ->  弧度
    cell.emissionRange = 180*M_PI/180;
    
    //最后把粒子的cell添加到粒子发送器  数组内可以添加多个cell对象
    self.emitterLayer.emitterCells = @[cell];

    //0,01秒打印一次
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(log) userInfo:nil repeats:YES];
   
    
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event

- (void)log
{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.huangyibiao.serial_queue",
                                                         DISPATCH_QUEUE_SERIAL);
    // 将serialQueue放到全局队列中作为子队列，这样优先级就是使用默认
    dispatch_set_target_queue(serialQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    
    dispatch_async(serialQueue, ^{
        HJHttpLog(@"dfsdfsdfsdfsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsdfsdfsdfsdfsfdsfds");
    });
}

- (CAEmitterCell *)getEmitterCell {
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    //设置速度
    cell.velocity = 400;
    cell.velocityRange = 400;
    //设置粒子缩放比例
    cell.scale = 0.7;
    cell.scaleRange = 0.3;
    //设置粒子方向
    cell.emissionLongitude = 0;
    cell.emissionRange = M_PI_4;
    //设置粒子存活时间
    cell.lifetime = 0.1;
    cell.lifetimeRange = 0.1;
    //设置粒子旋转
    cell.spin = M_PI_2;
    cell.spinRange = M_PI_4;
    //设置粒子每秒弹出的个数
    cell.birthRate = 100;
    //设置图片
    cell.contents = (id)[UIImage imageNamed:@"fire.png"].CGImage;
    cell.color = [UIColor redColor].CGColor;
    cell.name = @"fire";
    
    cell.alphaRange = 0.8;
    
    
    return cell;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"hhahahahaa");
    NSLog(@"hhahahahaa");
    NSLog(@"hhahahahaa");
    NSLog(@"hhahahahaa");
    NSLog(@"hhahahahaa");
}

#pragma mark - lazy load

- (CAEmitterLayer *)emitterLayer{
    if (_emitterLayer) {
        return _emitterLayer;
    }
    _emitterLayer = [[CAEmitterLayer alloc]init];
    [self.view.layer addSublayer:_emitterLayer];
    return _emitterLayer;
    
}

@end
