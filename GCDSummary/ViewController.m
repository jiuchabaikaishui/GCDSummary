//
//  ViewController.m
//  GCDSummary
//
//  Created by apple on 16/5/19.
//  Copyright © 2016年 QSP. All rights reserved.
//
/**
    一.执行GCD的同步与异步方法
        串行与并行针对的是队列，而同步与异步，针对的则是线程。最大的区别在于，同步线程要阻塞当前线程，必须要等待同步线程中的任务执行完，返回以后，才能继续执行下一任务；而异步线程则是不用等待。
         1.dispatch_async(dispatch_queue_t queue, ^{}):
        此方法为异步方法，即不需要等待block中的代码执行完毕就返回执行后面的代码。
         2.dispatch_sync(dispatch_queue_t queue, ^{}):
        此方法为同步方法，即需要等待block中的代码执行完毕再返回执行下面的代码。
    二.GCD队列
        在使用GCD的时候我们会把需要处理的任务放到block中，	然后追加到相应的队列里面。iOS中存在两种队列即串行队列和并行队列，串行队列是要等待上一个执行完，再执行下一个的Serial Dispatch Queue，这叫做串行队列；并行队列，则是不需要上一个执行完，就能执行下一个的Concurrent Dispatch Queue，叫做并行队列。这两种，均遵循FIFO原则。
        GCD中准确的说只有两种队列即：串行队列、并行队列。但是有四种方式获得队列或者创建队列。
        1.串行队列：
            dispatch_get_main_queue():主队列，正常情况所有任务都是在组队列中执行的，主队列是串行队列.
            dispatch_queue_create(const char *label, DISPATCH_QUEUE_SERIAL):此方法是创建一个串行队列，第一个参数是队列的标签，第二个参数为队列的类型即是串行队列还是并行队列。
        2.并行队列：
            dispatch_get_global_queue(long identifier, unsigned long flags):全局队列，全局队列是一个并行队列，第一个参数为队列的优先级，通常设为默认的DISPATCH_QUEUE_PRIORITY_BACKGROUND；第二个参数为队列标志。
            dispatch_queue_create(const char *label, DISPATCH_QUEUE_CONCURRENT):此方法是创建一个并行队列，第一个参数是队列的标签，第二个参数为队列的类型即是串行队列还是并行队列。
    三.GCD死锁
        1.死锁：是指多个进程循环等待它方占有的资源而无限期地僵持下去的局面。很显然，如果没有外力的作用，那麽死锁涉及到的各个进程都将永远处于封锁状态。
        2.死锁产生的原因：第一，因为系统资源不足；第二，进程运行推进的顺序不合适；第三，资源分配不当。
        3.产生死锁的四个必要条件：
         （1） 互斥条件：一个资源每次只能被一个进程使用。
         （2） 请求与保持条件：一个进程因请求资源而阻塞时，对已获得的资源保持不放。
         （3） 不剥夺条件:进程已获得的资源，在末使用完之前，不能强行剥夺。
         （4） 循环等待条件:若干进程之间形成一种头尾相接的循环等待资源关系。
        4.GCD死锁的情况：多个任务在同步方法的同一个串行队列中执行，造成相互等待的现象，形成死锁。
            注意：
                （1）在同步方法中
                （2）在同一个串行队列中
        5.GCD案例分析
 */
#import "ViewController.h"

typedef NS_ENUM(NSInteger,QueueType) {
    QueueTypeMain = 0,//主队列
    QueueTypeSerial = 1,//串行队列
    QueueTypeGlobal = 2,//全局队列
    QueueTypeConcurrent = 3//并行队列
};

@interface ViewController ()
@property (strong,nonatomic) NSArray *queueArr;
@property (strong,nonatomic) NSArray *testButtonArr;
@property (weak, nonatomic) IBOutlet UIButton *syncButton;
@property (weak, nonatomic) IBOutlet UIButton *asyncButton;
@property (weak, nonatomic) IBOutlet UIButton *testButton1;
@property (weak, nonatomic) IBOutlet UIButton *testButton2;
@property (weak, nonatomic) IBOutlet UIButton *testButton3;
@property (weak, nonatomic) IBOutlet UIButton *mainQueueButton;

@end

@implementation ViewController

#pragma mark - 属性方法
- (NSArray *)queueArr
{
    if (_queueArr == nil) {
        _queueArr = @[
                      dispatch_get_main_queue(),//主队列
                      dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL),//串行队列
                      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),//全局队列
                      dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT)//并行队列
                      ];
    }
    
    return _queueArr;
}
- (NSArray *)testButtonArr
{
    if (_testButtonArr == nil) {
        _testButtonArr = @[
                           self.testButton1,
                           self.testButton2,
                           self.testButton3
                           ];
    }
    
    return _testButtonArr;
}

#pragma mark - 控制器周期
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - 触摸点击方法
/**
 *  同步按钮方法
 */
- (IBAction)syncButtonAction:(UIButton *)sender {
    [self changeSyncOrAsyncFunction];
    self.mainQueueButton.enabled = NO;
}
/**
 *  异步按钮方法
 */
- (IBAction)asyncButtonAction:(UIButton *)sender {
    [self changeSyncOrAsyncFunction];
    self.mainQueueButton.enabled = YES;
}
/**
 *  主队列方法
 */
- (IBAction)mainQueueButtonAction:(UIButton *)sender {
    [self executeGCD:[self currentIsSync] queueType:QueueTypeMain];
}
/**
 *  串行队列方法
 */
- (IBAction)serialQueueButtonAction:(UIButton *)sender {
    [self executeGCD:[self currentIsSync] queueType:QueueTypeSerial];
}
/**
 *  全局队列方法
 */
- (IBAction)globalQueueButtonAction:(UIButton *)sender {
    [self executeGCD:[self currentIsSync] queueType:QueueTypeGlobal];
}
/**
 *  并行方法
 */
- (IBAction)concurrentQueueButtonAction:(UIButton *)sender {
    [self executeGCD:[self currentIsSync] queueType:QueueTypeConcurrent];
}
/**
 *  测试按钮方法：设置各测试按钮是否可用
 *
 *  @param button 出发时间的按钮
 */
- (IBAction)settingTestButtons:(UIButton *)sender
{
    for (UIButton *button in self.testButtonArr) {
        if (sender == button) {
            button.enabled = NO;
        }
        else
        {
            button.enabled = YES;
        }
    }
}
/**
 *  空白区域点击触发的方法
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //GCD死锁案例分析
    [self GCDdeadlockCases];
}

#pragma mark - 自定义方法
/**
 *  切换同异步方法
 */
- (void)changeSyncOrAsyncFunction
{
    self.syncButton.enabled = !self.syncButton.enabled;
    self.asyncButton.enabled = !self.asyncButton.enabled;
}
/**
 *  当前是否为同步方法
 */
- (BOOL)currentIsSync
{
    if (self.syncButton.enabled && (!self.asyncButton.enabled)) {
        return NO;
    }
    
    return YES;
}
/**
 *  执行GCD
 *
 *  @param isSycn 是否同步执行
 *  @param type   所在执行队列的类型
 */
- (void)executeGCD:(BOOL)isSycn queueType:(QueueType)type
{
    switch (type) {
        case QueueTypeMain:
            NSLog(@"%i主队列",(int)type);
            break;
        case QueueTypeSerial:
            NSLog(@"%i串行队列",(int)type);
            break;
        case QueueTypeGlobal:
            NSLog(@"%i全局队列",(int)type);
            break;
        case QueueTypeConcurrent:
            NSLog(@"%i并行队列",(int)type);
            break;
            
        default:
            break;
    }
    
    if (isSycn) {
        NSLog(@"同步");
    }
    else
    {
        NSLog(@"异步");
    }
    
    if (!self.testButton1.enabled) {
        if (isSycn) {
            NSLog(@"同步");
            dispatch_sync(self.queueArr[type], ^{
                NSLog(@"1");
            });
            
            NSLog(@"2");
        }
        else
        {
            NSLog(@"异步");
            dispatch_async(self.queueArr[type], ^{
                NSLog(@"1");
            });
            
            NSLog(@"2");
        }
    }
    else if (!self.testButton2.enabled)
    {
        if (isSycn) {
            dispatch_sync(self.queueArr[type], ^{
                NSLog(@"%@",[NSThread currentThread]);
            });
        }
        else
        {
            dispatch_async(self.queueArr[type], ^{
                NSLog(@"%@",[NSThread currentThread]);
            });
        }
    }
    else if (!self.testButton3.enabled)
    {
        if (isSycn) {
            dispatch_sync(self.queueArr[type], ^{
                NSLog(@"任务1：1");
            });
            dispatch_sync(self.queueArr[type], ^{
                NSLog(@"任务2：2");
            });
            dispatch_sync(self.queueArr[type], ^{
                NSLog(@"任务3：3");
            });
        }
        else
        {
            dispatch_async(self.queueArr[type], ^{
                NSLog(@"任务1：1");
            });
            dispatch_async(self.queueArr[type], ^{
                NSLog(@"任务2：2");
            });
            dispatch_async(self.queueArr[type], ^{
                NSLog(@"任务3：3");
            });
        }
    }
}
/**
 *  GCD死锁案例分析
 */
- (void)GCDdeadlockCases
{
    //案例1
    dispatch_sync(self.queueArr[QueueTypeMain], ^{
        NSLog(@"1"); // 任务1
    });
    NSLog(@"2"); // 任务2
    
    //案例2
    dispatch_async(self.queueArr[QueueTypeMain], ^{
        NSLog(@"1"); // 任务1
    });
    NSLog(@"2"); // 任务2
    
    //案例3
    dispatch_sync(self.queueArr[QueueTypeSerial], ^{
        NSLog(@"1"); // 任务1
    });
    NSLog(@"2"); // 任务2
    
    //案例4
    dispatch_sync(self.queueArr[QueueTypeSerial], ^{
        dispatch_sync(self.queueArr[QueueTypeMain], ^{
            NSLog(@"1"); // 任务1
        });
        NSLog(@"2"); // 任务2
    });
    NSLog(@"3"); // 任务3

    //案例5
    dispatch_sync(self.queueArr[QueueTypeSerial], ^{
        dispatch_sync(self.queueArr[QueueTypeSerial], ^{
            NSLog(@"1"); // 任务1
        });
        NSLog(@"2"); // 任务2
    });
    NSLog(@"3"); // 任务3

    //案例六
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"1"); // 任务1
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"2"); // 任务2
        });
        NSLog(@"3"); // 任务3
    });
    NSLog(@"4"); // 任务4
    while (1) {
    }
    NSLog(@"5"); // 任务5
}

@end
