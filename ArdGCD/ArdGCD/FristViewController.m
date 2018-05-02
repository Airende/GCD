//
//  FristViewController.m
//  ArdGCD
//
//  Created by airende on 2018/5/2.
//  Copyright © 2018年 airende. All rights reserved.
//

#import "FristViewController.h"

@interface FristViewController ()

@end

@implementation FristViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createQueue];
//    [self globalAndMainQueue];
//    [self dispatch_set_target_queue];
//    [self dispatch_group];
//    [self dispatch_barrier_async];
//    [self dispatch_sync];
//    [self dispatch_apply];
//    [self dispatch_once];
    
}
//DISPATCH_QUEUE_SERIAL
- (void)createQueue{
    //当任务相互依赖，具有明显的先后顺序的时候，使用串行队列是一个不错的选择 创建一个串行队列：
    dispatch_queue_t serialDispatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_SERIAL);
    //第一个参数为队列名，第二个参数为队列类型，当然，第二个参数如果写NULL，创建出来的也是一个串行队列。然后我们在异步线程来执行这个队列：
    dispatch_async(serialDispatchQueue, ^{
        NSLog(@"1");
    });
    
    dispatch_async(serialDispatchQueue, ^{
        sleep(2);
        NSLog(@"2");
    });
    
    dispatch_async(serialDispatchQueue, ^{
        sleep(1);
        NSLog(@"3");
    });
    
    //比较2个队列的创建，我们发现只有第二个参数从DISPATCH_QUEUE_SERIAL变成了对应的DISPATCH_QUEUE_CONCURRENT，其他完全一样。
    dispatch_queue_t concurrentDispatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentDispatchQueue, ^{
        NSLog(@"1");
    });
    dispatch_async(concurrentDispatchQueue, ^{
        sleep(2);
        NSLog(@"2");
    });
    dispatch_async(concurrentDispatchQueue, ^{
        sleep(1);
        NSLog(@"3");
    });
    //我们发现，log的输出在3个不同编号的线程中进行，而且相互不依赖，不阻塞。
}
- (void)globalAndMainQueue{
    /*
     这是系统为我们准备的2个队列：
     Global Queue其实就是系统创建的Concurrent Diapatch Queue
     Main Queue 其实就是系统创建的位于主线程的Serial Diapatch Queue
     */
    
    //通常情况我们会把这2个队列放在一起使用，也是我们最常用的开异步线程-执行异步任务-回主线程的一种方式：
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"异步线程");
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"异步主线程");
        });
    });
    
    /*
     通过上面的代码我们发现了2个有意思的点：
     
     dispatch_get_global_queue存在优先级，没错，他一共有4个优先级：
     #define DISPATCH_QUEUE_PRIORITY_HIGH 2
     #define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
     #define DISPATCH_QUEUE_PRIORITY_LOW (-2)
     #define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
     */
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSLog(@"4");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"3");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"2");
    });//跟1同等级
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"1");
    });
    
}
- (void)dispatch_set_target_queue{
    //刚刚我们说了系统的Global Queue是可以指定优先级的，那我们如何给自己创建的队列执行优先级呢？这里我们就可以用到dispatch_set_target_queue这个方法：
    dispatch_queue_t serialDispatchQueue=dispatch_queue_create("com.test.queue", NULL);
    dispatch_queue_t dispatchgetglobalqueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_set_target_queue(serialDispatchQueue, dispatchgetglobalqueue);
    dispatch_async(serialDispatchQueue, ^{
        NSLog(@"我优先级低，先让让");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"我优先级高,我先block");
    });
    //我把自己创建的队列塞到了系统提供的global_queue队列中，我们可以理解为：我们自己创建的queue其实是位于global_queue中执行,所以改变global_queue的优先级，也就改变了我们自己所创建的queue的优先级。所以我们常用这种方式来管理子队列。
}
- (void)dispatch_after{
    //这个是最常用的，用来延迟执行的GCD方法，因为在主线程中我们不能用sleep来延迟方法的调用，所以用它是最合适的，我们做一个简单的例子：
    NSLog(@"小破孩-波波1");
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"小破孩-波波2");
    });
    
    //我们看到他就是在主线程，就是刚好延迟了2秒，当然，我说这个2秒并不是绝对的，为什么这么说？还记得我之前在介绍dispatch_async这个特性的时候提到的吗？他的block中方法的执行会放在主线程runloop之后，所以，如果此时runloop周期较长的时候，可能会有一些时差产生。
}
- (void)dispatch_group{
    //当我们需要监听一个并发队列中，所有任务都完成了，就可以用到这个group，因为并发队列你并不知道哪一个是最后执行的，所以以单独一个任务是无法监听到这个点的，如果把这些单任务都放到同一个group，那么，我们就能通过dispatch_group_notify方法知道什么时候这些任务全部执行完成了。
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group=dispatch_group_create();
    dispatch_group_async(group, queue, ^{NSLog(@"0");});
    dispatch_group_async(group, queue, ^{NSLog(@"1");});
    dispatch_group_async(group, queue, ^{NSLog(@"2");});
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"down");
    });
    
    //在例子中，我把3个log分别放在并发队列中，通过把这个并发队列任务统一加入group中，group每次runloop的时候都会调用一个方法dispatch_group_wait(group, DISPATCH_TIME_NOW)，用来检查group中的任务是否已经完成，如果已经完成了，那么会执行dispatch_group_notify的block，输出’down’
}
- (void)dispatch_barrier_async{
    //此方法的作用是在并发队列中，完成在它之前提交到队列中的任务后打断，单独执行其block，并在执行完成之后才能继续执行在他之后提交到队列中的任务：
    dispatch_queue_t concurrentDispatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"0");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"1");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"2");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"3");});
    dispatch_barrier_async(concurrentDispatchQueue, ^{
        sleep(1);
        NSLog(@"4");
    });
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"5");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"6");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"7");});
    dispatch_async(concurrentDispatchQueue, ^{NSLog(@"8");});
}
- (void)dispatch_sync{
    //dispatch_sync 会在当前线程执行队列，并且阻塞当前线程中之后运行的代码，所以，同步线程非常有可能导致死锁现象，我们这边就举一个死锁的例子，直接在主线程调用以下代码：
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        NSLog(@"有没有同步主线程?");
//    });
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{sleep(1);NSLog(@"1");});
    dispatch_sync(queue, ^{sleep(1);NSLog(@"2");});
    dispatch_sync(queue, ^{sleep(1);NSLog(@"3");});
    NSLog(@"4");
    //从线程编号中我们发现，同步方法没有去开新的线程，而是在当前线程中执行队列，会有人问，上文说dispatch_get_global_queue不是并发队列，并发队列不是应该会在开启多个线程吗？这个前提是用异步方法。GCD其实是弱化了线程的管理，强化了队列管理，这使我们理解变得比较形象。
}
- (void)dispatch_apply{
    //这个方法用于无序查找，在一个数组中，我们能开启多个线程来查找所需要的值，我这边也举个例子：
    NSArray *array=[[NSArray alloc]initWithObjects:@"0",@"1",@"2",@"3",@"4",@"5",@"6", nil];
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([array count], queue, ^(size_t index) {
        NSLog(@"%zu=%@",index,[array objectAtIndex:index]);
    });
    NSLog(@"阻塞");
    //通过输出log，我们发现这个方法虽然会开启多个线程来遍历这个数组，但是在遍历完成之前会阻塞主线程。
}
- (void)dispatch_once{
    //这个函数一般是用来做一个真的单例，也是非常常用的，在这里就举一个单例的例子吧：
//    static SingletonTimer * instance;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [[SingletonTimer alloc] init];
//    });
//
//    return instance;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
