//
//  ViewController.m
//  NFCScan
//
//  Created by Riffle on 2021/11/18.
//

#import "ViewController.h"
#import "NFCManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton * scanBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 30)];
    [scanBtn addTarget:self action:@selector(startScan) forControlEvents:UIControlEventTouchUpInside];
    
    [scanBtn setTitle:@"开始扫描" forState:UIControlStateNormal];
    [scanBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    scanBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:scanBtn];
}

// 开始扫描
- (void)startScan
{

    [[NFCManager sharedInstance] scanTagWithSuccessBlock:^(NFCNDEFMessage * _Nonnull message) {

        } andErrorBlock:^(NSError * _Nonnull error) {

        }];
}


@end
