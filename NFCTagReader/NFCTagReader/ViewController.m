//
//  ViewController.m
//  NFCTagReader
//
//  Created by liuyalu on 2021/11/19.
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
    
    
    UIButton * swiftBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 100, 30)];
    [swiftBtn addTarget:self action:@selector(swiftBtnScan) forControlEvents:UIControlEventTouchUpInside];
    
    [swiftBtn setTitle:@"Swift扫NFC" forState:UIControlStateNormal];
    swiftBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [swiftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:swiftBtn];
    
}

// 开始扫描
- (void)startScan
{

    [[NFCManager sharedInstance] scanTagWithSuccessBlock:^(NFCNDEFMessage * _Nonnull message) {

        } andErrorBlock:^(NSError * _Nonnull error) {

        }];


    
}

-(void)swiftBtnScan{
    SwiftNFCViewController * vc = [[SwiftNFCViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
