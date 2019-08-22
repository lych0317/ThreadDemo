//
//  ViewController.m
//  ThreadDemo
//
//  Created by li yuanchao on 2019/8/20.
//  Copyright © 2019 li yuanchao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) dispatch_queue_t serial_queue;
@property (nonatomic, strong) dispatch_queue_t concurrent_queue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.serial_queue = dispatch_get_main_queue();

//    self.serial_queue = dispatch_queue_create("def.test.serial", DISPATCH_QUEUE_SERIAL);
    
//    self.serial_queue = dispatch_get_main_queue();
//    
//    NSLog(@"liyc: a thread %@", [NSThread currentThread]);
//    for (NSUInteger i = 0; i < 5; i++) {
//        dispatch_async(self.serial_queue, ^{
//            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
//        });
//    }
//    
//    NSLog(@"liyc: b thread %@", [NSThread currentThread]);
//    for (NSUInteger i = 5; i < 10; i++) {
//        dispatch_sync(self.serial_queue, ^{
//            NSLog(@"liyc: %@ thread %@", @(i), [NSThread currentThread]);
//        });
//    }
    
    NSLog(@"%@", @"------------------------");
    
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
}

@end
