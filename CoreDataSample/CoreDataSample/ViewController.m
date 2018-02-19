//
//  ViewController.m
//  CoreDataSample
//
//  Created by Ashok Parthiban D on 19/02/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

#import "ViewController.h"
#import "UserManager.h"
#import "UserModel.h"

@interface ViewController ()
{
    UserManager * manager;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    manager = [[UserManager alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnAdd:(id)sender
{
//    NSMutableArray * arrUsers = [[NSMutableArray alloc] init];
    
    UserModel * model = [[UserModel alloc] init];
    model.name = @"Ashok";
    model.age = 25;
    model.sex = 1;
    model.userId = 1013;
    
    [manager addUser:[NSArray arrayWithObject:model]];
    
    NSArray * result = [manager getUsers];
    NSLog(@"Result : %@",result);
}

@end
