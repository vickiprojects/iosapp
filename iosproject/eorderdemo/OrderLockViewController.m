//
//  OrderLockViewController.m
//  Eorder
//
//  Created by ZhangLi on 16/11/3.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import "OrderLockViewController.h"
#import "ContentViewController.h"
#import "PrintObject.h"
#import "AppDelegate.h"
#import "OrderEditViewController.h"
#import "UIView+Toast.h"
#import "RMMapper.h"
#import "AFNetworking.h"
#import "UIView+MJExtension.h"
#import "OrderInfo.h"
#import "PickUpViewController.h"
#import "ByDayViewController.h"
#import "NewPoint2PointViewController.h"
#import "OrderBaseViewController.h"

@interface OrderLockViewController ()
{
    OrderBaseViewController *view;
    AppDelegate* myAppDelegate;
}
@end

@implementation OrderLockViewController


@synthesize morderID;
@synthesize mtype;
@synthesize mtypedetail;
@synthesize morderinfo;
- (void)viewDidLoad {
    [super viewDidLoad];
     myAppDelegate= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    self.lb_id.text = [NSString stringWithFormat:@"订单编号:%d",morderID];
    self.lb_ordertype.text=mtypedetail;
    [self addContainerView];

     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)addContainerView
{
    //1.创建containerView目标控制器
    if (self.morderinfo.OrderType==0) {
        view =  [[PickUpViewController alloc]initWithNibName:@"OrderBaseViewController" bundle:nil];
    }
    else if (self.morderinfo.OrderType==1)
    {
        view =  [[ByDayViewController alloc]initWithNibName:@"OrderBaseViewController" bundle:nil];
    }else if (self.morderinfo.OrderType==3)
    {
        view =  [[NewPoint2PointViewController alloc]initWithNibName:@"OrderBaseViewController" bundle:nil];
    }
    
    view.mOrder = morderinfo;
    view.mIsEdit = YES;
    view.mIsOrderLock=YES;
    view.lockview = self;
    //2.将目标控制器的视图赋值给容器视图(不能用addSubView,否则设置frame无效)
    self.containerView = view.view;
    //设置显示大小
    self.containerView.frame = CGRectMake(0, 96, self.view.bounds.size.width, self.view.bounds.size.height-96);
    //3.添加到当前视图
    [self.view addSubview:self.containerView];
    
    //4.获取到Containerview的目标控制器
    NSLog(@"%@",self.containerView.nextResponder);
    
//    if (self.morderinfo.Status==3 || self.morderinfo.Status==12) {
//        [self alertMsg];
//    }
    
}
//#pragma makr - 场景切换,适合通过storyboard拖拽的切换
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"orderlock"]) {
//        ContentViewController *destinationController=[segue destinationViewController];
//        destinationController.mIsEdit = YES;
//        destinationController.mIsOrderLock = YES;
//        destinationController.mEditOrderID = morderID;
//        destinationController.orderType = mtype;
//        destinationController.mOrder = morderinfo;
//        view = destinationController;
//    }
//    
//    
//    
//    
//}


//UIViewController对象的视图即将消失、被覆盖或是隐藏时调用；
-(void)viewWillDisappear:(BOOL)animated
{
    if (view.nsTime!=nil) {
        [view.nsTime invalidate];
        view.nsTime=nil;
    }
    
}

-(void)viewWillAppear:(BOOL)animated {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
   
        view.nsTime=  [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(setOrderDefault) userInfo:nil repeats:YES];
    
    

}
-(void)setOrderDefault
{
    [view setOrderDefault];
}
- (void) appWillEnterForegroundNotification{
    NSLog(@"trigger event when will enter foreground.");
 
    [view viewDidLoad];
}
- (void)alertMsg
{
      [self.view hideToastActivity];
    NSString *str = @"";
    if (self.morderinfo.IsCompanyPush) {
        str = [str stringByAppendingString:@"提交中，通常情况下，提交过程不超过30秒，谢谢耐心等待。"];
    }else   {
        if (self.morderinfo.WaitingCount>0 || self.morderinfo.DriverCount>0) {
            str = [str stringByAppendingString:@"已通知"];
            if (self.morderinfo.WaitingCount>0) {
                str = [NSString stringWithFormat:@"%@%@家租赁公司.",str,self.morderinfo.WaitingCount];
            }
            if (self.morderinfo.DriverCount>0) {
                str = [NSString stringWithFormat:@"%@%@个司机.",str,self.morderinfo.DriverCount];
            }
            if (self.morderinfo.PriceType==1) {
                  str = [str stringByAppendingString:@"请耐心等待，或撤销此单，或调整价格增加司机接单成功率。"];
            }else{
                str = [str stringByAppendingString:@"请耐心等待，或撤销此单。"];
            }
        }
    }
    if (str.length>0) {
           [self.view hideToastActivity];
        [self.view makeToast:str duration:30*60*30 position:[NSValue valueWithCGPoint:CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height-100)]];
    }
}
- (void)gotoMain
{
//    if (self.miscacel) {
//        [self.view hideToastActivity];
//        [self.view makeToast:@"撤销成功"];
//        self.miscacel =NO;
//    }
    
        NSString *str1 =@"%@Order/GetMyWaitingOrder";
        
        NSString *urlstr = [NSString stringWithFormat:str1,[AppDelegate GetServerRootURL]];
        NSLog(@"%@",urlstr);
        // 初始化Manager
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager GET:urlstr parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            // 这里可以获取到目前的数据请求的进度
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            // 请求成功，解析数据
            // NSLog(@"success--%@", responseObject);
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
            
            NSLog(@"dic--%@", dic);
            NSString* Successed =(NSString*)[dic objectForKey:@"Successed"];
            NSString* flag =(NSString*)[dic objectForKey:@"Flag"];
            
            if ([Successed longLongValue]==(long)1){
                
                
                id responseJSONResult =[dic objectForKey:@"Data"] ;
                OrderInfo *info= [RMMapper objectWithClass:[OrderInfo class] fromDictionary:responseJSONResult];
                
                if (info!=nil && info.OrderID>0) {
                   
                    self.mtype =info.OrderType;
                    self.morderID = info.OrderID;
                    self.mtypedetail = info.OrderTypeDescription;
                    self.lb_id.text = [NSString stringWithFormat:@"订单编号:%d",morderID];
                    self.lb_ordertype.text=mtypedetail;
                    
                    view.mOrder = morderinfo;
                    view.mIsEdit = YES;
                    view.mIsOrderLock=YES;
                   
                   [view viewDidLoad];
                  
                    
                }
                else{
                    [self closeValue];
                  //[self dismissViewControllerAnimated:YES completion:nil];
                }
                
                
            }
            if([flag longLongValue]==(long)-2)
            {
                //返回登陆
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                // 获取故事板中某个View
                UIViewController *next= [board instantiateViewControllerWithIdentifier:@"Login"];
                // 跳转
                [self presentModalViewController:next animated:YES];
                
            }
            if([flag longLongValue]==(long)0 && [Successed longLongValue]!=(long)1)
            {
                [self closeValue];
                //[self dismissViewControllerAnimated:YES completion:nil];
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self alerterror:error  url:str1];

            [myAppDelegate onhttpfailed:self error:[error localizedDescription]];
            // 请求失败
            NSLog(@"error--%@", [error localizedDescription]);
        }];
        
        
    

}
-(void)alerterror:(NSError * _Nonnull)  error url:(NSString*)url
{
    NSString * msg = [NSString stringWithFormat:@"请求失败--[链接地址：%@-- 错误信息：%@]",url, [error localizedDescription]];
    [self alertviewclick:msg];
}
-(void)alertviewclick:(NSString *)msg
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
    
    [alter show];
}
- (void)gotoEditOrderView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    
    OrderEditViewController *eview =[storyboard
                                    instantiateViewControllerWithIdentifier:@"ordereditView"];
    eview.mOrderInfo = morderinfo;
    eview.mtype =morderinfo.OrderType;
    eview.morderID = morderinfo.OrderID;
    eview.mtypedetail = morderinfo.OrderTypeDescription;
    NSString *phone =morderinfo.Supplier.SupplierPhone;
    if (morderinfo.Supplier.SupplierPhone.length>11) {
        phone = [morderinfo.Supplier.SupplierPhone substringToIndex:11];
    }
    eview.mtelphone = phone;
    eview.delegate=self;
     eview.mstartMsg=@"提交成功，如有问题可直接联系司机.";
    if (morderinfo.IsDriverGrab || morderinfo.IsCompanyPush) {
        eview.mstartMsg=@"提交成功，如有问题可直接联系司机.";
    }else{
        if (self.morderinfo.Status!=19) {
              eview.mstartMsg=@"接单成功，如有问题可直接联系租赁公司.";
        }
       
    }
   // [self dismissViewControllerAnimated:YES completion:nil];

    [self presentViewController:eview
                       animated:YES
                     completion:^(void){
                         if (view.nsTime!=nil) {
                             [view.nsTime invalidate];
                             view.nsTime = nil;
                         }
                        
                          }];

    
   
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"orderlock-------viewDidAppear");
}



- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"orderlock-------viewDidDisappear");
    if (view.nsTime!=nil) {
        [view.nsTime invalidate];
        view.nsTime = nil;
    }
}

-(void)closeValue
{
   
    if (view.nsTime!=nil) {
        [view.nsTime invalidate];
        view.nsTime = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}
-(void)reloadValue
{
    [self closeValue];
}
@end
