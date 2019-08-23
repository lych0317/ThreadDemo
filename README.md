# 介绍
> Dispatch, also known as Grand Central Dispatch (GCD), contains language features, runtime libraries, and system enhancements that provide systemic, comprehensive improvements to the support for concurrent code execution on multicore hardware in macOS, iOS, watchOS, and tvOS.

# 优势
* GCD 会`自动管理`线程的生命周期
* RD 只需要将`指定任务`以`特定方式`提交到`相应队列`

# 概念
## 指定任务
> 将要执行的操作
> `typedef void (^dispatch_block_t)(void);`

## 特定方式
### 同步执行(sync)
1. 等待同步任务结束后再继续执行当前任务
2. 两个任务在同一线程执行，`不`具备开启线程能力

![同步执行](https://upload-images.jianshu.io/upload_images/3246932-3104a41bfbcfb0d4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 异步执行(async)
1. 提交异步任务后`立即`继续执行当前任务
2. 两个任务可以在不同线程中执行，具备开启线程能力

![异步执行](https://upload-images.jianshu.io/upload_images/3246932-c96455e2972f0d98.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> 异步执行虽然具有开启新线程的能力，但是并不一定开启新线程

## 相应队列
### 队列概念
队列是一种特殊的线性表，采用 FIFO（先进先出）的原则
![队列](https://upload-images.jianshu.io/upload_images/3246932-28b39be4c200d636.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### 串行队列
1. 所有任务按顺序依次执行，结束顺序固定
2. 队列头部的任务等待上一个任务执行完毕后才出队列

![串行队列](https://upload-images.jianshu.io/upload_images/3246932-868d895861f8b0b9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 并发队列
1. 所有任务可以同时执行，结束顺序`不`固定
2. 只要有可用线程，则队列头部任务将持续出队列

![并发队列](https://upload-images.jianshu.io/upload_images/3246932-9a861f65838859bb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> 队列和线程没有必然联系，队列只是一系列任务的容器，而线程才是执行任务的载体。
> `所以，不要认为串行队列中的所有任务都在同一个线程中。`

# 实战
## 实战 1
> 在主线程中执行如下代码

```
    self.serial_queue = dispatch_queue_create("def.test.serial", DISPATCH_QUEUE_SERIAL);
    
    NSLog(@"liyc: a thread %@", [NSThread currentThread]);
    for (NSUInteger i = 0; i < 5; i++) {
        dispatch_async(self.serial_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
    
    NSLog(@"liyc: b thread %@", [NSThread currentThread]);
    for (NSUInteger i = 5; i < 10; i++) {
        dispatch_sync(self.serial_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
```
分析如下：
在主线程中提交五个异步任务，由于是异步，所以继续在主线程执行当前任务。第二个`for`循环将要添加五个同步任务，此时需要等待新添加的同步任务执行完毕，而在这之前队列中已经存在五个任务，所以要先依次执行完毕后才能继续执行。那么得到如下结果：

```
2019-08-22 16:04:19.610366+0800 ThreadDemo[81233:4928855] liyc: a thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.610560+0800 ThreadDemo[81233:4928855] liyc: b thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.610597+0800 ThreadDemo[81233:4928907] liyc: 0 thread <NSThread: 0x600001d54700>{number = 3, name = (null)}
2019-08-22 16:04:19.610699+0800 ThreadDemo[81233:4928907] liyc: 1 thread <NSThread: 0x600001d54700>{number = 3, name = (null)}
2019-08-22 16:04:19.610802+0800 ThreadDemo[81233:4928907] liyc: 2 thread <NSThread: 0x600001d54700>{number = 3, name = (null)}
2019-08-22 16:04:19.610895+0800 ThreadDemo[81233:4928907] liyc: 3 thread <NSThread: 0x600001d54700>{number = 3, name = (null)}
2019-08-22 16:04:19.610999+0800 ThreadDemo[81233:4928907] liyc: 4 thread <NSThread: 0x600001d54700>{number = 3, name = (null)}
2019-08-22 16:04:19.611128+0800 ThreadDemo[81233:4928855] liyc: 5 thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.611225+0800 ThreadDemo[81233:4928855] liyc: 6 thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.611310+0800 ThreadDemo[81233:4928855] liyc: 7 thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.759665+0800 ThreadDemo[81233:4928855] liyc: 8 thread <NSThread: 0x600001d213c0>{number = 1, name = main}
2019-08-22 16:04:19.759772+0800 ThreadDemo[81233:4928855] liyc: 9 thread <NSThread: 0x600001d213c0>{number = 1, name = main}
```

> 问题：`b`一定紧随`a`之后输出吗？
> 回答：不是的。大家看到`1～4`在子线程中，所以理论上`b`有可能在`a`之后`5`之前的任意位置。
> 大家感兴趣的话可以自己测试一下，在两个`for`循环之间加个耗时操作。

## 实战 2
> 在主线程中执行如下代码

```
    self.serial_queue = dispatch_get_main_queue();
    
    NSLog(@"liyc: a thread %@", [NSThread currentThread]);
    for (NSUInteger i = 0; i < 5; i++) {
        dispatch_async(self.serial_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
    
    NSLog(@"liyc: b thread %@", [NSThread currentThread]);
    for (NSUInteger i = 5; i < 10; i++) {
        dispatch_sync(self.serial_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
```

分析如下：
在主线程中提交五个异步任务，由于是异步，所以继续在主线程执行当前任务。第二个`for`循环将要添加五个同步任务，此时需要等待新添加的同步任务执行完毕，而在这之前队列中已经存在五个任务，所以要先依次执行完毕后才能继续执行。
以上与刚才一样，但是，问题来了：当前任务是在主队列里出来的，并没有执行完毕，此时又想将主队列里的头部任务取出，而主队列是串行队列，取出队列头部又需要已经出队列的任务执行完毕。造成相互等待，程序无法继续执行。那么得到如下结果：

```
2019-08-22 16:12:23.248246+0800 ThreadDemo[81337:4935835] liyc: a thread <NSThread: 0x600003ac1dc0>{number = 1, name = main}
2019-08-22 16:12:23.248468+0800 ThreadDemo[81337:4935835] liyc: b thread <NSThread: 0x600003ac1dc0>{number = 1, name = main}
```
## 实战 3
> 在主线程中执行如下代码

```
    self.concurrent_queue = dispatch_queue_create("def.test.concurrent", DISPATCH_QUEUE_CONCURRENT);

    NSLog(@"liyc: c thread %@", [NSThread currentThread]);
    for (NSUInteger i = 10; i < 15; i++) {
        dispatch_sync(self.concurrent_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
    
    NSLog(@"liyc: d thread %@", [NSThread currentThread]);
    for (NSUInteger i = 15; i < 20; i++) {
        dispatch_async(self.concurrent_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }    
```

分析如下：
将要在主线程中提交五个同步任务，由于是同步，所以五个任务依次被加入队列，并且执行。之后异步加入并发队列，所以乱序的情况下在不同线程里被执行。那么得到如下结果：

```
2019-08-22 16:27:17.104961+0800 ThreadDemo[81497:4949380] liyc: c thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105134+0800 ThreadDemo[81497:4949380] liyc: 10 thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105239+0800 ThreadDemo[81497:4949380] liyc: 11 thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105332+0800 ThreadDemo[81497:4949380] liyc: 12 thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105434+0800 ThreadDemo[81497:4949380] liyc: 13 thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105523+0800 ThreadDemo[81497:4949380] liyc: 14 thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105625+0800 ThreadDemo[81497:4949380] liyc: d thread <NSThread: 0x600001b692c0>{number = 1, name = main}
2019-08-22 16:27:17.105767+0800 ThreadDemo[81497:4949454] liyc: 15 thread <NSThread: 0x600001b0cdc0>{number = 3, name = (null)}
2019-08-22 16:27:17.105778+0800 ThreadDemo[81497:4949452] liyc: 16 thread <NSThread: 0x600001b02d00>{number = 4, name = (null)}
2019-08-22 16:27:17.105815+0800 ThreadDemo[81497:4949453] liyc: 17 thread <NSThread: 0x600001b60100>{number = 5, name = (null)}
2019-08-22 16:27:17.105821+0800 ThreadDemo[81497:4949451] liyc: 19 thread <NSThread: 0x600001b287c0>{number = 6, name = (null)}
2019-08-22 16:27:17.105834+0800 ThreadDemo[81497:4949464] liyc: 18 thread <NSThread: 0x600001b02ac0>{number = 7, name = (null)}
```

> 问题：`d`一定在`14`之后输出吗？
> 回答：是的。因为上边是同步任务。

## 实战 4
> 在主线程中执行如下代码

```
    self.concurrent_queue = dispatch_queue_create("def.test.concurrent", DISPATCH_QUEUE_CONCURRENT);

    NSLog(@"liyc: c thread %@", [NSThread currentThread]);
    for (NSUInteger i = 10; i < 15; i++) {
        NSLog(@"liyc: i-%@ thread %@", @(i), [NSThread currentThread]);
        dispatch_sync(self.concurrent_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }
    
    NSLog(@"liyc: d thread %@", [NSThread currentThread]);
    for (NSUInteger i = 15; i < 20; i++) {
        NSLog(@"liyc: i-%@ thread %@", @(i), [NSThread currentThread]);
        dispatch_async(self.concurrent_queue, ^{
            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
        });
    }    
```

分析如下：
这里和实战 3的区别是在`for`循环里添加了`i-`输出。主要是理解`for`循环是连续执行，还是等待加入的任务执行完毕后再继续执行循环。那么得到如下结果：

```
2019-08-22 16:43:37.960402+0800 ThreadDemo[81711:4964687] liyc: c thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.960534+0800 ThreadDemo[81711:4964687] liyc: i-10 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.960652+0800 ThreadDemo[81711:4964687] liyc: 10 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.960768+0800 ThreadDemo[81711:4964687] liyc: i-11 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.960911+0800 ThreadDemo[81711:4964687] liyc: 11 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961027+0800 ThreadDemo[81711:4964687] liyc: i-12 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961127+0800 ThreadDemo[81711:4964687] liyc: 12 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961254+0800 ThreadDemo[81711:4964687] liyc: i-13 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961358+0800 ThreadDemo[81711:4964687] liyc: 13 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961474+0800 ThreadDemo[81711:4964687] liyc: i-14 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961581+0800 ThreadDemo[81711:4964687] liyc: 14 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.961690+0800 ThreadDemo[81711:4964687] liyc: d thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.966989+0800 ThreadDemo[81711:4964687] liyc: i-15 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.967175+0800 ThreadDemo[81711:4964687] liyc: i-16 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.967201+0800 ThreadDemo[81711:4964889] liyc: 15 thread <NSThread: 0x6000000b03c0>{number = 3, name = (null)}
2019-08-22 16:43:37.967363+0800 ThreadDemo[81711:4964687] liyc: i-17 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.967380+0800 ThreadDemo[81711:4964889] liyc: 16 thread <NSThread: 0x6000000b03c0>{number = 3, name = (null)}
2019-08-22 16:43:37.967492+0800 ThreadDemo[81711:4964687] liyc: i-18 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.967496+0800 ThreadDemo[81711:4964889] liyc: 17 thread <NSThread: 0x6000000b03c0>{number = 3, name = (null)}
2019-08-22 16:43:37.967625+0800 ThreadDemo[81711:4964889] liyc: 18 thread <NSThread: 0x6000000b03c0>{number = 3, name = (null)}
2019-08-22 16:43:37.967626+0800 ThreadDemo[81711:4964687] liyc: i-19 thread <NSThread: 0x6000000c13c0>{number = 1, name = main}
2019-08-22 16:43:37.967802+0800 ThreadDemo[81711:4964891] liyc: 19 thread <NSThread: 0x6000000bc000>{number = 4, name = (null)}
```

如果以上这些内容全部理解了，那么关于`GCD`的使用问题应该就不大了。[实战代码看这里](https://github.com/lych0317/ThreadDemo)
# 其他
* dispatch_barrier_async
* dispatch_after
* dispatch_once
* dispatch_apply
* dispatch_group
  * dispatch_group_notify
  * dispatch_group_wait
  * dispatch_group_enter/dispatch_group_leave
* dispatch_semaphore
# 最后
线程切换存在成本，需要酌情使用。但是如果只是把任务抛到子线程去处理，那么几乎没有开销。所以大可以放心使用，比如，监控、埋点相关操作，都可以放到子线程中执行。

# 引用
* https://www.jianshu.com/p/cbe141e34ca7
* https://developer.apple.com/documentation/dispatch?language=objc
* https://en.wikipedia.org/wiki/Grand_Central_Dispatch
* https://juejin.im/post/5a90de68f265da4e9b592b40


