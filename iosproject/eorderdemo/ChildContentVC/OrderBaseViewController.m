//
//  OrderBaseViewController.m
//  Eorder
//
//  Created by ZhangLi on 16/12/19.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import "OrderBaseViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MyBaiduTTS.h"
static SystemSoundID shake_sound_male_id = 0;
@interface OrderBaseViewController ()<DateTimePickerViewDelegate>
{
    NSNumber *mdistance;
    NSArray *VGtitles ;
    NSArray *VTtitles ;
    NSArray * mCanShowDriverStatus;
    NSArray * mSubmitChangeStatus;
    NSMutableArray*rankcheckboxes;
    NSArray* RanksArray;
   
    UILabel* mlblprice;
    UILabel*mareadypay;
    BOOL isGetDefaultPriceType;
    BOOL isstop;
    NSTimer* nearnstime;
    BOOL isnearstop;
}
@property(nonatomic,retain)MyBaiduTTS *mMyBaiduTTS;
@property(nonatomic,strong)VehiclePickView *pickview;
@end

@implementation OrderBaseViewController
@synthesize mIsEdit;
@synthesize mIsOrderLock;
@synthesize myAppDelegate;
@synthesize tvtitles;
@synthesize templates;
@synthesize mUIConfig;
@synthesize mOrder;
@synthesize mUser;
@synthesize mServerUrl;
@synthesize mDriverServerUrl;
@synthesize mOrderType;
@synthesize mcarCount;
@synthesize moldorder;
@synthesize mIsHome;
@synthesize nsTime;
@synthesize lblcarcount;
- (MyBaiduTTS *)mMyBaiduTTS
{
    if (!_mMyBaiduTTS)
    {
        _mMyBaiduTTS = [[MyBaiduTTS alloc] init];
        [_mMyBaiduTTS configureSDK];
    }
    return _mMyBaiduTTS;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    isstop =NO;
    [self initializeData];
    [self firstloadData];
    [self SetUIControl];
    [self setOrderDefault];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
    
}
-(void)viewWillAppear:(BOOL)animated {
    if (!mIsEdit) {
        if (nearnstime ==nil) {
            nearnstime= [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(GetNearCarCount) userInfo:nil repeats:YES];
        }
        if (self.mOrder.IsWithinCall) {
            [self GetNearCarCount];
           
        }else{
            isnearstop = YES;
            [self stopnearnstime];
        }
    }
   
    
    
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (nearnstime!=nil) {
        [nearnstime invalidate];
        nearnstime = nil;
    }
}
- (BMKGeoCodeSearch *)geoCode
{
    if (!_geoCode)
    {
        _geoCode = [[BMKGeoCodeSearch alloc] init];
        _geoCode.delegate = self;
    }
    return _geoCode;
}
#pragma mark 页面初始化
-(void)initializeData
{
   myAppDelegate= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    if (tvtitles==nil) {
        tvtitles = [[NSMutableArray alloc]init];
    }
    templates = myAppDelegate.mTemplates;
    mUIConfig = myAppDelegate.mUIConfig;
    if (mOrder==nil) {
        mOrder = [[OrderInfo alloc]init];
    }
    mUser = [myAppDelegate getUser];
    mServerUrl = [AppDelegate GetServerRootURL];
    mDriverServerUrl = [AppDelegate GetDriverServerRootURL];
    moldorder= [[OrderInfo alloc]init];
    isGetDefaultPriceType = YES;
}
-(void) firstloadData
{
       mcarCount = @"0";
    mdistance = [NSNumber numberWithInt:50];
    mSubmitChangeStatus=[NSArray arrayWithObjects:@"4",@"5",@"11",@"12",nil];
    mCanShowDriverStatus=[NSArray arrayWithObjects:@"11",@"12",@"21",@"22",@"23",@"24",nil];
    RanksArray=@[@"全部",@"1",@"2",@"3"];
    VGtitles=@[@"小车",@"商务",@"中巴",@"大巴"];
    VTtitles=@[@"不限",@"经济",@"舒适",@"豪华"];
    rankcheckboxes = [[NSMutableArray alloc] initWithCapacity:RanksArray.count];
    
    
    
}
-(void) SetUIControl
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // 设置回调（一旦进入刷新状态，就调用target的action，
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(setOrderDefault)];
    
    // 设置文字
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"下拉刷新" forState:MJRefreshStatePulling];
    [header setTitle:@"Loading ..." forState:MJRefreshStateRefreshing];
    
    // 设置字体
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];
    
    
    // 马上进入刷新状态
    // [header beginRefreshing];
    
    // 设置刷新控件
    self.tableView.mj_header = header;
    
    [self setButtonClick];
    
    self.svinfo.hidden=YES;

    
}
-(void)stopload{
   
    if (nsTime !=nil) {
         isstop =YES;
        [nsTime setFireDate:[NSDate distantFuture]];
    }
}

-(void)restartload{
    
    if (nsTime!=nil) {
        [nsTime setFireDate:[[NSDate alloc]initWithTimeIntervalSinceNow:6]];
    }
}
#pragma mark 模版操作
/*
 根据选择的车型获取对应设置的模版
 */
-(TemplateInfo * ) GetTemplateInfoByOrder
{
    for (TemplateInfo * info in self.templates)
    {
        if ((self.mOrder.VehicleCategory<2 && self.mOrder.VehicleCategory == info.VehicleCategory
             && self.mOrder.VehicleType ==info.VehicleType )|| (self.mOrder.VehicleCategory>=2  && self.mOrder.VehicleCategory ==info.VehicleCategory)) {
            return info;
        }
    }
    return nil;
}
/*
 获取默认的模版（CategoryDefault＝＝true && IsDefault ＝＝true）
 */
-(TemplateInfo * ) GetDefaultTemplateInfo
{
    TemplateInfo *CategoryDefault = nil;
    TemplateInfo *result = nil;
    for (TemplateInfo * info in self.templates)
    {
        if (info.CategoryDefault) {
            CategoryDefault= info;
            break;
        }
    }
    if (CategoryDefault!=nil) {
        int vc = CategoryDefault.VehicleCategory;
        for (TemplateInfo * info in self.templates)
        {
            if (info.VehicleCategory==vc && info.IsDefault) {
                result= info;
                break;
            }
        }
        
    }
    return result;
}
/*
 根据选择的车型获取该车型下默认的预约车型
 */
-(TemplateInfo * ) GetIsDefaultTemplateInfo
{
    for (TemplateInfo * info in self.templates)
    {
        if (info.VehicleCategory == self.mOrder.VehicleCategory && info.IsDefault) {
            return info;
        }
    }
    return nil;
}
/*
 获取当前用户的上调基数
 */
-(NSNumber* )GetMarketPriceRatio
{
    NSNumber*  result =  [NSNumber numberWithDouble:1.0];
    
    result=mUser.MarketPriceRatio;
    return result;
    
}/*
  获取当前车型模版下的价格同步
  */
-(BOOL)GetSyncPay
{
    BOOL SyncPay=YES;
    TemplateInfo * info = [self GetTemplateInfoByOrder];
    if (info !=NULL) {
        SyncPay=info.SyncPay;
    }
    return SyncPay;
    
}
/*
 新增时获取配置的默认车型和预约车型,并设置order
 */
-(void)setOrderDefaultTempalteWhenNew
{
    if (!mIsEdit) {
        TemplateInfo *info=[self GetDefaultTemplateInfo];
        if (info!=NULL) {
            self.mOrder.VehicleCategory = info.VehicleCategory;
            self.mOrder.VehicleType = info.VehicleType;
            self.mOrder.SeatCount = info.SeatCount;
            
            [self setOrderByTempalte:info];
            
        }
       

    }
    
}
/*
 新增订单车型和预约车型变化后，获取对应模版下的默认价格类型
 */
-(void)setPriceTypeTempalteWhenNew
{
    if (!self.mIsEdit && isGetDefaultPriceType ) {
        TemplateInfo *info=[self GetTemplateInfoByOrder];
        [self setOrderByTempalte:info];
    }
}
/*
 根据模版设置默认的价格类型
 */
-(void)setOrderByTempalte:(TemplateInfo *)info
{
    if (info!=nil) {
        
        switch (info.PriceType) {
            case 1:
            case 3:
                self.mOrder.PriceType = 1;
                break;
            case 2:
          
                self.mOrder.PriceType = 2;
                break;
            case 4:
            case 5:
            case 6:
            case 7:
                self.mOrder.PriceType = 0;
                break;
            default:
                self.mOrder.PriceType = 0;
                break;
        }

    }

}
#pragma mark 页面数据处理
/*
 设置 新增 下 的订单的默认值
 */
-(void)setCleanOrder
{
    
    self.mIsEdit = NO;
    self.mIsOrderLock = NO;
    self.mOrder = [[OrderInfo alloc]init];
    self.mOrder.OrderID=0;
    NSString * companyName =@"";
    if(self.mUser!=nil)
    {
        if (self.mUser.DefaultDestination ==nil || [self.mUser.DefaultDestination isEqual:[NSNull null]] || [self.mUser.DefaultDestination isEqualToString:@""]) {
               companyName=self.mUser.CompanyName;
            
        }else{
            companyName = self.mUser.DefaultDestination;
        }
    }
    
    self.mOrder.StartLocation=companyName;
    self.mOrder.Destination=companyName;
   
    self.mOrder.KiloMeters=[NSNumber numberWithInt: 50];;
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    
    NSDate *nextDate = [NSDate dateWithTimeInterval:60 * 60 * 24 sinceDate:currentDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy年MM月dd"];
    NSString *destDateString = [formatter stringFromDate:nextDate];
    destDateString=[destDateString stringByAppendingString:@" 06:00"];
    formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy年MM月dd HH:mm"];
    self.mOrder.LaunchDateTime=[formatter dateFromString:destDateString];
    self.mOrder.AlreadyPay=[NSNumber numberWithDouble:0];
    self.mOrder.VehicleCategory=0;
    self.mOrder.PriceType=0;
    self.mOrder.VehicleType=0;
    self.mOrder.ContractFinalPrice=[NSNumber numberWithDouble:0];
    self.mOrder.SeatCount=5;
    self.mOrder.FinalPrice=[NSNumber numberWithDouble:800];
    self.mOrder.BasePrice=[NSNumber numberWithDouble:800];
    isGetDefaultPriceType=YES;
    self.mOrder.Status=0;
    self.mOrder.StatusDetail=@"新增中";
    self.mOrder.TimeStamp=nil;
    self.mOrder.PriorityList=nil;
    self.mOrder.IsWithinCall=YES;
}
-(void) setOrderDefault
{
    
    if(!mIsEdit)
    {
      [self setCleanOrder];
      [self setOrderDefaultTempalteWhenNew];
        [self setDefaultPriority];
     // [self setStatus];
       if (self.mOrder.PriceType>0) {
           [self reloadTableview];
            [self CalePrice];
       }else{
           
            [self reloadTableview];
       }
      [self.tableView.mj_header endRefreshing];
    }else{
        [self setStatus];
        if (self.mOrder!=nil) {
           [self reloadTableview];
        }
        [self getOrderByID];
    }
   
}
#pragma mark 数据获取
-(void) getOrderByID
{
    [self stopload];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText =@"Loading...";
    
        NSString *str1 =[NSString stringWithFormat:@"%@Order/QueryByID?csvOrderId=%d",mServerUrl,self.mOrder.OrderID];
        
        NSLog(@"%@",str1);
        // 初始化Manager
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [manager GET:str1 parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            // 这里可以获取到目前的数据请求的进度
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
            // 请求成功，解析数据
            // NSLog(@"success--%@", responseObject);
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
#if defined(DEBUG)||defined(_DEBUG)
            
            NSLog(@"dic--%@", dic);
            
#endif
           
            NSDictionary *result =[dic objectForKey:@"result"] ;
            // NSLog(@"dic--%@", result) ;
            NSString* flag =(NSString*)[result objectForKey:@"Flag"];
            // NSLog(@"dic--%@", flag) ;
            //  NSLog(@"dic--%d", [flag longLongValue]==(long)1) ;
            if ([flag longLongValue]==(long)1){
                
                id responseJSONResult =[dic objectForKey:@"Orders"] ;
                NSMutableArray * data= [RMMapper mutableArrayOfClass:[OrderInfo class]  fromArrayOfDictionary:responseJSONResult];
                if (data.count>0) {
                    self.mOrder =data[0];
                    if (mIsEdit && mIsOrderLock && self.mOrder.IsWithinCall) {
                        [self PostGetNearCarCount];
                    }
                    [self setOrderLogic];
                    moldorder = [self.mOrder copy];
                    [self reloadTableview];
                }
                               
              
                
            }else if([flag longLongValue]==(long)-2)
            {
               
                //返回登陆
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                // 获取故事板中某个View
                UIViewController *next= [board instantiateViewControllerWithIdentifier:@"Login"];
                // 跳转
                [self presentModalViewController:next animated:YES];
                
            }else{
                              // 拿到当前的下拉刷新控件，结束刷新状态
                [self.tableView.mj_header endRefreshing];
                
            }
         
            if (isstop) {
                [self restartload];
            }
            
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [myAppDelegate onhttpfailed:self error:[error localizedDescription]];
            
            if (isstop) {
                [self restartload];
            }

            // 拿到当前的下拉刷新控件，结束刷新状态
            [self.tableView.mj_header endRefreshing];
            NSLog(@"error--%@", [error localizedDescription]);
        }];
        
 
}

-(void)alertviewclick:(NSString *)msg
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
    
    [alter show];
}

#pragma mark 页面逻辑设置
-(void) setOrderLogic
{
    @try {
        NSString * str = (NSString*)self.mOrder.LaunchDateTime;
        str= [[str substringFromIndex:6] substringToIndex:10];
        NSLog(@"xx = %@",str);
        
        NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:str.integerValue];
        
        self.mOrder.LaunchDateTime =confromTimesp;
        
        if (mIsEdit && mIsOrderLock && self.mOrder.Status>=3 ) {
            //
            
            if (self.lockview !=nil) {
                
                self.lockview.morderinfo = self.mOrder;
                if (self.mOrder.Status==3 ||self.mOrder.Status==12) {
                    //锁住状态  提示信息
                    [self.lockview alertMsg];
                    
                }else{//锁住状态 刷新 跳转至 编辑界面
                    if (nsTime!=nil) {
                        [nsTime invalidate];
                        nsTime=nil;
                    }
                    [self.lockview gotoEditOrderView];
                }
                
            }
        }

        
    } @catch (NSException *exception) {
          NSLog(@"catch = %@",exception.description);
    } @finally {
        
    }
    
    
    
  
    
    
    
    
   
}
/*
 重新 刷新列表
 */
-(void)reloadTableview{
    @try {
         [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.tableView.mj_header endRefreshing];
        [self setStatus];
        [self setTableviewbyTemplatesShow];
        [self setButton];
        
        [self.tableView reloadData];
        
    } @catch (NSException *exception) {
         NSLog(@"catch = %@",exception.description);
    } @finally {
         [self.tableView.mj_header endRefreshing];
    }
    
}
/*
 table内容显示配置
 */
-(void)setTableviewbyTemplatesShow{
    
    [self setPriceTypeTempalteWhenNew];
    self.tvtitles = [[NSMutableArray alloc]init];
    [self setChildTableviewbyTemplatesShow];
    
    [self setChildMapShow];
     [self.tvtitles addObject:@"预约时间"];
    //订单逻辑1－－－－
    
    if (self.mOrder.OrderType>0) {
        [self.tvtitles addObject:@"大约里程数(公里)"];
        
    }
    

    
    
    
    [self.tvtitles addObject:@"车型"];
    //－－－－－－－
    //模版逻辑1－－－－
    NSMutableArray * arrPricetype = [[NSMutableArray alloc]init];
    //价格配置
    TemplateInfo *info=[self GetTemplateInfoByOrder];
    if (info!=nil) {
        if ((info.PriceType & 4)>0) {
            [arrPricetype addObject:@"合同价"];
        }
        if ((info.PriceType & 1)>0) {
            [arrPricetype addObject:@"竞价"];
        }
        if ((info.PriceType & 2)>0) {
            [arrPricetype addObject:@"市场价"];
        }
    }else{
        NSArray *arr = @[@"合同价",@"竞价",@"市场价"];
        [arrPricetype addObjectsFromArray:arr];
    }
    //价格是否显示
    if (arrPricetype.count>1) {
        [self.tvtitles addObject:@"价格类型"];
    }
    //－－－－－－－
    //订单逻辑2－－－－－－－
    //合同价
    if (self.mOrder.PriceType ==0) {
        [self.tvtitles addObject:@"价格"];
        [self.tvtitles addObject:@"已收款额"];
    }
    //竞价+市场价
    if (self.mOrder.PriceType >=1) {
        [self.tvtitles addObject:@"竞价"];
        
    }
    //市场价
    if (self.mOrder.PriceType ==2) {
        [self.tvtitles addObject:@"已收款额"];
        if (mUser.CanLoadTransactionRecord) {
             [self.tvtitles addObject:@"上调基数"];
        }
       
    }
    //－－－－－－－
    //模版逻辑2－－－－－
    if (info.DisplayPriority) {
        [self.tvtitles addObject:@"优先级"];
    }
    if (info.ShowCustomerName) {
        [self.tvtitles addObject:@"客人姓名"];
    }
    if (info.ShowCustomerPhone) {
        [self.tvtitles addObject:@"客人电话"];
    }
    if (info.ShowRoomSN) {
        [self.tvtitles addObject:@"房间号"];
    }
    if (info.ShowCheckDocumentSN) {
        [self.tvtitles addObject:@"车单号"];
    }
    [self.tvtitles addObject:@"备注"];
    if (info.ShowInsideRemark) {
        [self.tvtitles addObject:@"内部备注"];
    }
    
}
-(void)setChildTableviewbyTemplatesShow{

}
/*
 按钮逻辑显示
 */
-(void)setButton{
    
    self.svaddnew.hidden=YES;
    self.svcopy.hidden=YES;
    self.svsubmit.hidden=YES;
    self.svcancer.hidden=YES;
    self.svcancelwhite.hidden=YES;
    if (self.mIsEdit) {
        
        NSDictionary *olddic =[PrintObject getObjectData:self.moldorder];
        NSDictionary *dic =[PrintObject getObjectData:self.mOrder];
        
        if (self.mOrder.Status !=19 &&  (!self.svinfo.hidden || ![dic isEqual:olddic])) {
            self.svsubmit.hidden=NO;
        }
        
    }else{
        self.svaddnew.hidden=NO;
        if (self.mOrder.Status !=19 ) {
            self.svsubmit.hidden=NO;
        }
    }
    
    if (self.mOrder.OrderID>0 && !self.mIsOrderLock) {
        self.svcopy.hidden=NO;
    }
    
    if (self.mOrder.Status>1 && self.mOrder.Status !=19 ) {
        self.svcancer.hidden=NO;
    }
    if (!self.mIsOrderLock) {
        if (self.mIsEdit ) {
            if (!self.svinfo.hidden ) {
                self.svcancelwhite.hidden=NO;
                
            }
        }else{
            self.svcancelwhite.hidden=NO;
        }
        
    }
    
    
}
-(void)setButtonClick
{
   
    
    UITapGestureRecognizer *addtg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonActiondo:)];
    [self.svaddnew addGestureRecognizer:addtg];
     addtg.view.tag = 101;
    
    UITapGestureRecognizer *copytg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonActiondo:)];
    [self.svcopy addGestureRecognizer:copytg];
     copytg.view.tag = 102;
    
    UITapGestureRecognizer *submittg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonActiondo:)];
    [self.svsubmit addGestureRecognizer:submittg];
     submittg.view.tag = 104;
    
    UITapGestureRecognizer *cancertg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonActiondo:)];
    [self.svcancer addGestureRecognizer:cancertg];
     cancertg.view.tag = 105;
    
    UITapGestureRecognizer *canceltg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonActiondo:)];
    [self.svcancelwhite addGestureRecognizer:canceltg];
     canceltg.view.tag = 106;
}
#pragma  mark 按钮操作
-(void)buttonActiondo:(id)sender
{
    UIAlertView *alertview;
    UITapGestureRecognizer *uitg = (UITapGestureRecognizer*)sender;
    UIView *view = (UIView*)uitg.view;
    NSString *msg=@"";
    BOOL showalert=YES;
    switch (view.tag) {
        case 101:
             msg=@"确认新增新的订单？";
            break;
        case 102:
            msg=@"确认复制拷贝当前订单？";
            break;
        case 104:
        {
            showalert=NO;
            if ([self  checkOrder]) {
                 [self getRanks];
            }
           
        }
            break;
        case 105:
            msg=@"确定撤销当前订单？";
            break;
        case 106:
        {
            msg=@"确认取消新增此单？";
            if (self.mOrder.OrderID>0) {
                msg=@"确认取消编辑此单？";
            }
        }
            break;
        default:
            break;
    }
    if (showalert) {
        alertview =[[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles: @"取消",nil];
        
        alertview.tag = view.tag;
        [alertview show];
    }
    
    
}
-(void) getRanks
{
    NSString *str1 =[NSString stringWithFormat: @"%@Configuration/Ranks",mServerUrl];
    //  NSString *str1 =@"http://publish.1dabus.com/Order.MVC/Configuration/Ranks";
    NSLog(@"%@",str1);
    // 初始化Manager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:str1 parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        // 这里可以获取到目前的数据请求的进度
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 请求成功，解析数据
        // NSLog(@"success--%@", responseObject);
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
        
        NSLog(@"dic--%@", dic);
        NSDictionary *result =[dic objectForKey:@"result"] ;
        // NSLog(@"dic--%@", result) ;
        NSString* flag =(NSString*)[result objectForKey:@"Flag"];
        // NSLog(@"dic--%@", flag) ;
        //  NSLog(@"dic--%d", [flag longLongValue]==(long)1) ;
        if ([flag longLongValue]==(long)1){
            
            id responseJSONResult =[dic objectForKey:@"Ranks"] ;
            self.ranks = [RMMapper mutableArrayOfClass:[Supplier class]
                                 fromArrayOfDictionary:responseJSONResult];
            
            //1. isactive
            NSMutableArray *rankarr = [[NSMutableArray alloc]init];
            for (int i=0; i<self.ranks.count; i++) {
                Supplier * rank = self.ranks[i];
                if (rank.IsActive) {
                    [rankarr addObject:rank];
                }
            }
            NSMutableArray *rankslist = [[NSMutableArray alloc]init];
            if (self.mOrder.PriorityList ==nil || self.mOrder.PriorityList.count==0) {
                rankslist = rankarr;
            }
            else{
                for (NSNumber * num in self.mOrder.PriorityList) {
                    for (int i=0; i<rankarr.count ;i++) {
                        Supplier * rank = rankarr[i];
                        if ((rank.Rank !=nil || ![rank.Rank isEqual:[NSNull null]]) && rank.Rank ==num && rank.IsActive) {
                            [rankslist addObject:rank];
                        }
                    }
                }
            }
            bool IsShowAD=YES;
            if (rankslist.count==0) {
                UIAlertView* alertview =[[UIAlertView alloc] initWithTitle:@"提示" message:@"没有符合订单优先级设置的租车公司，继续提交订单？" delegate:self cancelButtonTitle:@"提交订单" otherButtonTitles: @"取消",nil];
                alertview.tag = 1040;
                [alertview show];
            }
            else{
                
                if (rankslist.count == 1 ) {
                    Supplier * rank = rankslist[0];
                    if (rank.AllowAutoPush) {
                        IsShowAD=NO;
                    }
                }
                NSString *strmsg=@"";
                if (self.mOrder.IsWithinCall) {
                    strmsg = @"%@如需取消此单，请联系司机撤单。\n继续提交该订单？";
                }else{
                    strmsg=@"%@如驾驶员或车辆已安排，则不能在业务发生前%@内通过系统撤单，如需撤单，请直接联系租赁公司客服。\n继续提交该订单？";
                }
                
                NSString *fmsg=@"";
                NSString* smsg=@"";
                if (IsShowAD) {
                    if (self.mOrder.IsWithinCall) {
                        fmsg = @"订单一旦提交并且被抢单成功后，不能撤单。";
                    }else{
                        fmsg = @"订单一旦提交并且被抢单成功后，除撤单外数据不能修改（除去合同价）。";
                    }
                    
                }else
                {//直推
                    fmsg = @"此单成功上传后。";
                    //                    [self SubmitFun];
                }
                if (self.mOrder.SeatCount>19) {
                    smsg=@"24小时（大巴）";
                }else{
                    smsg=@"2小时";
                }
                NSString *msg =@"";
                if (self.mOrder.IsWithinCall) {
                    msg = [NSString stringWithFormat:strmsg,fmsg];
                }else{
                    msg = [NSString stringWithFormat:strmsg,fmsg,smsg];
                }
                UIAlertView* alertview =[[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles: @"取消",nil];
                alertview.tag = 1041;
                [alertview show];
            }
            
        }else if([flag longLongValue]==(long)-2)
        {
            //返回登陆
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            // 获取故事板中某个View
            UIViewController *next= [board instantiateViewControllerWithIdentifier:@"Login"];
            // 跳转
            [self presentModalViewController:next animated:YES];
            
        }else{
            NSString *msg = @"提交失败";
            if([result objectForKey:@"Msg"] !=nil)
            {
                msg =[result objectForKey:@"Msg"];
            }
           // [self alertviewclick:msg];
            [myAppDelegate ontostmsg:self error:msg];
            return;
            
        }
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (!mIsEdit) {
            // [myAppDelegate LogOut:self];
            [myAppDelegate onhttpfailed:self error: [error localizedDescription]];
        }
        else if(self.lockview!=nil)
        {
            [myAppDelegate onhttpfailed:self.lockview error: [error localizedDescription]];
            
            
        }else if(self.editview!=nil)
        {
            [myAppDelegate onhttpfailed:self.editview error: [error localizedDescription]];
            
            
        }

//        [self alertviewclick:[error localizedDescription]];
//        if (!mIsEdit) {
//             [myAppDelegate LogOut:self];
//        }
//        else if(self.lockview!=nil)
//        {
//         [myAppDelegate LogOut:self.lockview];
//        }else if(self.editview!=nil)
//        {
//            [myAppDelegate LogOut:self.editview];
//        }
    //    [self alerterror:error  url:str1];
        // 请求失败
        NSLog(@"error--%@", [error localizedDescription]);
    }];
    
    
}
-(void)alerterror:(NSError * _Nonnull)  error url:(NSString*)url
{
    NSString * msg = [NSString stringWithFormat:@"请求失败--[链接地址：%@-- 错误信息：%@]",url, [error localizedDescription]];
     [self alertviewclick:msg];
}
/*新增*/
-(void)AddNewFun{
    mIsEdit=NO;
    [self setOrderDefault];
}
/*复制*/
-(void)CopyFun{
    self.mOrder.OrderID=0;
    self.mOrder.Status=0;
    self.mOrder.StatusDetail=@"新增中";
    self.mOrder.IsCompanyPush = NO;
    self.mOrder.IsDriverGrab= NO;
    self.mOrder.IsCompanyPush= NO;
    self.mOrder.SerialNo=@"";
    self.mOrder.CheckDocumentSN=@"";
    self.mOrder.RoomSN=@"";
    self.mOrder.Supplier = nil;
    self.mOrder.CreatedTime = nil;
    self.mOrder.OrderDateTime = nil;
    self.mOrder.TimeStamp=nil;
    self.mOrder.LastUpdatedAt = nil;
    self.svinfo.hidden=NO;
    mIsEdit=NO;
    if (self.mOrder.PriceType>0) {
        [self CalePrice];
    }
    [self reloadTableview];
    if (self.editview !=nil) {
        self.editview.lb_id.text=@"";
    }
//    if ([self.parentViewController isKindOfClass:[OrderEditViewController class]]) {
//        OrderEditViewController *edit = (OrderEditViewController *)self.parentViewController;
//        edit.lb_id.text = @"";
//    }
}
/*提交*/
-(void)SubmitFun{
    [self PostOrder:@"Order/Submit" msg:@"提交中"];
}
/*撤销*/
-(void)CancerFun{
     [self PostOrder:@"Order/Cancel" msg:@"撤销中"];
}
/*取消*/
-(void)CancelFun{
    [self setOrderDefault];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (buttonIndex) {
        case 0:
        {
            switch (alertView.tag) {
                case 101:
                    [self AddNewFun];
                    break;
                case 102:
                    [self CopyFun];
                    break;
                
                case 1040:
                case 1041:
                    [self SubmitFun];
                    break;
                case 105:
                    [self CancerFun];
                    break;
                case 106:
                    [self CancelFun];
                    break;
                case 444://拨打电话
                {
                    
                    NSString *phone =self.mOrder.Supplier.SupplierPhone;
                    if (self.mOrder.Supplier.SupplierPhone.length>11) {
                        phone = [self.mOrder.Supplier.SupplierPhone substringToIndex:11];
                    }
                    NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"telprompt://%@",phone];
                    //            NSLog(@"str======%@",str);
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
                }
                    break;
                default:
                    break;
            }
        }
        default:
            break;
    }
    
}


#pragma mark 提交 撤销 订单
-(void)GoOrderLock:(OrderInfo*)info
{
    
    self.mIsEdit=self.mIsOrderLock=NO;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    
    OrderLockViewController*view =[storyboard
                                   instantiateViewControllerWithIdentifier:@"orderlockView"];
    view.mtype =info.OrderType;
    view.morderID = info.OrderID;
    view.mtypedetail = info.OrderTypeDescription;
    view.morderinfo = [info copy];

    
    [self presentViewController:view
                       animated:YES
                     completion:^(void){

                         self.lockview = nil;

                         
                     }];
    
}

-(void)PostOrder:(NSString*)url msg:(NSString*)msg
{
    
    if (self.mOrder !=nil ) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText =[msg stringByAppendingString: @"..."];
        if (self.mOrder.IsWithinCall) {
            NSDate *currentDate = [NSDate date];//获取当前时间，日期
            self.mOrder.LaunchDateTime = currentDate;

        }
        
       
        [self childSetOrder];
        //重新加载订单数据
        NSString *str1 =[mServerUrl  stringByAppendingString:url];
        
        NSLog(@"%@",str1);
        // 初始化Manager
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        //如果报接受类型不一致请替换一致text/html或别的
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
        
        NSDictionary *parameters =[PrintObject getObjectData:self.mOrder];
#if defined(DEBUG)||defined(_DEBUG)
        
          NSLog(@"parameters－－%@",parameters);
        
#endif
     
        [manager POST:str1 parameters:parameters
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                  
                  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
                  
#if defined(DEBUG)||defined(_DEBUG)
                  
                  NSLog(@"dic--%@", dic);
                  
#endif
                  //                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                  NSDictionary *result =[dic objectForKey:@"result"] ;
                  // NSLog(@"dic--%@", result) ;
                  NSString* flag =(NSString*)[result objectForKey:@"Flag"];
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                  
                  if ([flag longLongValue]==(long)1){
                      id responseJSONResult =[dic objectForKey:@"Order"] ;
                      OrderInfo * data= [RMMapper objectWithClass:[OrderInfo class] fromDictionary:responseJSONResult];
                      if (!mIsEdit) {//主页
                          if (self.mOrder.IsWithinCall) {
                              [self playSound];
                          }
                          self.mOrder = [[OrderInfo alloc]init];

                          
                          [self setOrderDefault];
                          NSString * str = (NSString*)data.LaunchDateTime;
                          
                          str= [[str substringFromIndex:6] substringToIndex:10];
                          NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:str.integerValue];
                          self.mOrder.LaunchDateTime =confromTimesp;
                           [self reloadTableview];
                          

                          
                          
                          if (data.Status==3) {
                              [self getOrderLock];
                          }
                          else{
                              UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                                   bundle:nil];
                              
                              OrderEditViewController *eview =[storyboard
                                                               instantiateViewControllerWithIdentifier:@"ordereditView"];
                              eview.mOrderInfo = data;
                              eview.mtype =data.OrderType;
                              eview.morderID = data.OrderID;
                              eview.mtypedetail = data.OrderTypeDescription;
                              NSString *phone =data.Supplier==nil?@"":data.Supplier.SupplierPhone;
                              if (data.Supplier.SupplierPhone.length>11) {
                                  phone = [data.Supplier.SupplierPhone substringToIndex:11];
                              }
                              eview.mtelphone = phone;
                              
                              eview.mstartMsg=@"提交成功，如有问题可直接联系司机.";
                              if (data.IsDriverGrab) {
                                  eview.mstartMsg=@"提交成功，如有问题可直接联系司机.";
                              }else{
                                  
                                  eview.mstartMsg=@"接单成功，如有问题可直接联系租赁公司.";
                                  
                                  
                              }
                              // [self dismissViewControllerAnimated:YES completion:nil];
                              
                              [self presentViewController:eview
                                                 animated:YES
                                               completion:^(void){
                                                   
                                               }];
                              
                              
                          }
                          
                          return;

                          
                      }else{
                          NSString *msg = @"";
                          if([result objectForKey:@"Msg"] !=nil)
                          {
                              msg =[result objectForKey:@"Msg"];
                          }
                          if (![msg isEqualToString:@""]) {
                              [self.view hideToastActivity];
                              [self.view makeToast:msg];
                          }
                          self.mOrder = data;
                          if ([msg isEqualToString:@"撤销中"] &&  mIsOrderLock) {
                             
                              if (self.lockview !=nil) {
                                  self.lockview.miscacel = YES;
                                  self.lockview.morderinfo = self.mOrder;
                                  [self.lockview gotoMain];
                                  
                              }
                              return;
                          }
                          if ([msg isEqualToString:@"提交中"]  && mIsOrderLock && self.mOrder.Status>3) {

                              if (self.lockview !=nil) {
                                  
                                  self.lockview.morderinfo = self.mOrder;
                                  if (nsTime!=nil) {
                                      [nsTime invalidate];
                                      nsTime=nil;
                                  }
                                  [self.lockview gotoEditOrderView];
                                  
                              }
                   
                              return;
                          }
                          
                          
                          NSString * str = (NSString*)self.mOrder.LaunchDateTime;
                          
                          str= [[str substringFromIndex:6] substringToIndex:10];
                          NSLog(@"PriorityDescription = %@",self.mOrder.PriorityDescription);
                          
                          NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:str.integerValue];
                       
                          self.mOrder.LaunchDateTime =confromTimesp;
                          
                          
                      }
                      
                      
                      [self reloadTableview];
                     
                     

                      
                     
                      
                      
                  }else if([flag longLongValue]==(long)-2)
                  {
                      //返回登陆
                      UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                      // 获取故事板中某个View
                      UIViewController *next= [board instantiateViewControllerWithIdentifier:@"Login"];
                      // 跳转
                      [self presentModalViewController:next animated:YES];
                      
                  }else{
                      NSString *msg = @"提交失败";
                      if([result objectForKey:@"Msg"] !=nil)
                      {
                          msg =[result objectForKey:@"Msg"];
                      }
                      [self alertviewclick:msg];
                      return;
                      
                  }
                  
                  
                  
              } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                  //                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                //   [self alertviewclick:@"提交失败"];
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                  if (!mIsEdit) {
                      // [myAppDelegate LogOut:self];
                      [myAppDelegate onhttpfailed:self error: [error localizedDescription]];
                  }
                  else if(self.lockview!=nil)
                  {
                      [myAppDelegate onhttpfailed:self.lockview error: [error localizedDescription]];
                      
                      
                  }else if(self.editview!=nil)
                  {
                      [myAppDelegate onhttpfailed:self.editview error: [error localizedDescription]];
                      
                      
                  }
//                  // 请求失败
//                  [self alertviewclick:[error localizedDescription]];
//                  if (!mIsEdit) {
//                      [myAppDelegate LogOut:self];
//                  }
//                  else if(self.lockview!=nil)
//                  {
//                      [myAppDelegate LogOut:self.lockview];
//                  }else if(self.editview!=nil)
//                  {
//                      [myAppDelegate LogOut:self.editview];
//                  }
   
                  NSLog(@"error--%@", [error localizedDescription]);
                   // [self alerterror:error  url:str1];
              }];
        
    }
}



/*
 设置 订单编辑状态
 */
-(void) setStatus
{
    @try {
        if (!mIsEdit) {
            self.lb_status.text=@"新增中";
            self.lb_title.text=@"订单新增中...";
            
        }else{
            
            self.lb_status.text=self.mOrder.StatusDetail;
            if (mIsEdit) {
                self.lb_title.text=@"订单编辑中...";
            }else{
                self.lb_title.text=[NSString stringWithFormat:@"序号:%d 订单编辑中...",self.mOrder.OrderID];
            }
            if (self.mOrder.SerialNo !=nil && ![self.mOrder isEqual:[NSNull null]]&&![self.mOrder.SerialNo isEqualToString:@""]) {
                self.lb_statuskey.text=@"状态/序列号";
                
                self.lb_status.text = [NSString stringWithFormat:@"%@/%@",self.mOrder.StatusDetail,self.mOrder.SerialNo];
            }
            
        }

    } @catch (NSException *exception) {
         NSLog(@"catch = %@",exception.description);
    } @finally {
        
    }
    
    
    
}
#pragma mark 计算价格
#pragma mark 计算价格
-(void)CalePrice
{
   
    //竞价
    if (self.mOrder.PriceType>=1 && self.mOrder.Status<3) {
      
        if (self.mOrder !=nil ) {
             mlblprice.text=@"价格计算中...";
             [self stopload];
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//            hud.mode = MBProgressHUDModeIndeterminate;
//            hud.labelText =@"价格计算中...";
            //重新加载订单数据
            NSString *str1 =[NSString stringWithFormat: @"%@Order/Price",mServerUrl];
            //NSString *str1 =@"http://publish.1dabus.com/Order.MVC/Order/Price";
            
            NSLog(@"%@",str1);
            // 初始化Manager
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            //如果报接受类型不一致请替换一致text/html或别的
            //manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
            NSDictionary *parameters =[PrintObject getObjectData:self.mOrder];
            NSLog(@"%@",parameters);
            [manager POST:str1 parameters:parameters
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                      // 请求成功，解析数据
                      // NSLog(@"success--%@", responseObject);
                      NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
                      
                      NSLog(@"dic--%@", dic);
                  
                      NSDictionary *result =[dic objectForKey:@"result"] ;
                      // NSLog(@"dic--%@", result) ;
                      NSString* flag =(NSString*)[result objectForKey:@"Flag"];
           
                      if ([flag longLongValue]==(long)1){
                          NSNumber* price =( NSNumber*)[dic objectForKey:@"Price"];
                         
                          NSLog(@"dic--%@",price);
                          
                          
                          self.mOrder.BasePrice = price  ;
                          if (self.mOrder.PriceType==2) {
                              
                              self.mOrder.FinalPrice = price;
                              NSNumber* rebate =( NSNumber*)[dic objectForKey:@"Rebate"];
                              self.mOrder.Rebate =rebate;
                              
                              
                          }else{
                              self.mOrder.FinalPrice = price;
                          }
                          if ([self GetSyncPay]) {
                              self.mOrder.AlreadyPay = self.mOrder.FinalPrice;
                          }
                          else{
                              self.mOrder.AlreadyPay = [NSNumber numberWithDouble:0];
                          }

                          [self reloadTableview];
                          if (isstop) {
                              [self restartload];
                          }

                          
                          
                          
                          
                      }else if([flag longLongValue]==(long)-2)
                      {
                          //返回登陆
                          UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                          // 获取故事板中某个View
                          UIViewController *next= [board instantiateViewControllerWithIdentifier:@"Login"];
                          // 跳转
                          [self presentModalViewController:next animated:YES];
                          
                      }else{
                       
                          NSString *msg = @"计算价格错误";
                          if([result objectForKey:@"Msg"] !=nil)
                          {
                              msg =[result objectForKey:@"Msg"];
                          }
                        //  [self alertviewclick:msg];
                           [self reloadTableview];
                          [myAppDelegate ontostmsg:self error:msg];
                          return;
                          
                      }
                      
                      
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                    //  [self alertviewclick:@"计算价格错误"];
                       [self reloadTableview];
                      [myAppDelegate onhttpfailed: self error:[error localizedDescription]];
                      // 请求失败
                        //[self alerterror:error  url:str1];
                      NSLog(@"error--%@", [error localizedDescription]);
                  }];
            
        }
    }else{
     [self reloadTableview];
    }
}


- (UIColor *)getColor:(NSString*)hexColor
{
    unsigned int red,green,blue;
    NSRange range;
    range.length = 2;
    
    range.location = 0;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&red];
    
    range.location = 2;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&green];
    
    range.location = 4;
    [[NSScanner scannerWithString:[hexColor substringWithRange:range]]scanHexInt:&blue];
    
    return [UIColor colorWithRed:(float)(red/255.0f)green:(float)(green / 255.0f) blue:(float)(blue / 255.0f)alpha:1.0f];
}

#pragma mark - Table view data source
/*
 列表 司机信息
 */
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section==0) {
        if (mIsEdit) {
            
            return 90;
        }else{
            
            for (NSString * status in mCanShowDriverStatus) {
                NSString * orderstatus =[NSString stringWithFormat:@"%d",self.mOrder.Status] ;
                if ([status isEqualToString:orderstatus]) {
                    return 90;
                }
            }
            return 0;
        }
    }
    return 0;

}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    FooterView * cell = [[FooterView alloc] init ];
    cell.backgroundColor=[UIColor whiteColor];
    // 再自定义该类（UIView子类）的初始化操作。
    
    UIScrollView* _scrollView = [[UIScrollView alloc] initWithFrame:self.tableView.bounds];
    
    [_scrollView setFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 90)];
    
    _scrollView.contentSize = CGSizeMake(self.tableView.bounds.size.width, 30*3+3);
    
    NSArray *arr = @[@"驾驶员/公司",@"联系电话",@"车型/车牌"];
    for (int i=0; i<3; i++) {
        CGFloat floaty = i*30;
        if (i>0) {
            floaty+=i*1;
        }
        UIView * _fview = [[UIView alloc] initWithFrame:_scrollView.bounds];
        [_fview setFrame:CGRectMake(0, floaty, self.tableView.bounds.size.width, 30)];
        _fview.backgroundColor = [self getColor:@"FFEBCD"];
        
        UILabel * lbkey = [[UILabel alloc] initWithFrame:_fview.bounds];
        
        lbkey.center = CGPointMake(CGRectGetMidX(_fview.bounds), CGRectGetMidY(_fview.bounds));
        lbkey.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
        [lbkey setMj_x:10];
        lbkey.textColor =[UIColor darkGrayColor];
        lbkey.font=[UIFont systemFontOfSize:(14)];
        lbkey.text=[arr objectAtIndex:i];
        [_fview addSubview:lbkey];
        
        
        
        UILabel * lbvalue = [[UILabel alloc] initWithFrame:_fview.bounds];
        
        lbvalue.center = CGPointMake(CGRectGetMidX(_fview.bounds), CGRectGetMidY(_fview.bounds));
        lbvalue.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
        CGFloat x_y =_fview.bounds.size.width;
        
        NSString *str=@"";
        switch (i) {
            case 0:
            {
                NSString*  str1=@"";
                if ([self.mOrder.Supplier.SupplierName isEqual:[NSNull null]]) {
                    str1=@"";
                }else{
                    str1 = self.mOrder.Supplier.SupplierName;
                }
                
                NSString*  str2 =[self.mOrder.Supplier.SupplierDriver isEqual:[NSNull null]]?@"": self.mOrder.Supplier.SupplierDriver;
                str= [NSString stringWithFormat:@"%@/%@",str2,str1];
            }
                break;
            case 1:
                
                str = [self.mOrder.Supplier.SupplierPhone isEqual:[NSNull null]]?@"":self.mOrder.Supplier.SupplierPhone;
                break;
            case 2:{
                
                NSString *num =[self.mOrder.Supplier.SupplierPlateNum isEqual:[NSNull null]]?@"":self.mOrder.Supplier.SupplierPlateNum;
                num=num==nil?@"":num;
                NSString *vdstr=(self.mOrder.VehicleDetail ==nil||[self.mOrder.Supplier.SupplierPlateNum isEqual:[NSNull null]])?@"":self.mOrder.VehicleDetail;
                str=[NSString stringWithFormat:@"%@/%@",vdstr,num];
                break;
            }
            default:
                break;
        }
        UIFont *font=[UIFont systemFontOfSize:(14)];
        CGSize size = CGSizeMake(320,2000);
        CGSize labelsize = [str sizeWithFont:font constrainedToSize:size];
        
        if (i>0) {
            x_y-=20;
        }
        x_y -=10;
        [lbvalue setFrame:CGRectMake(x_y-labelsize.width,6, labelsize.width, labelsize.height)];
        
        lbvalue.textColor =[UIColor darkGrayColor];
        
        lbvalue.font=font;
        lbvalue.text=str;

        
        [_fview addSubview:lbvalue];
        if(i==1)
        {
            UITapGestureRecognizer *tapGestureTel = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(teleButtonEvent:)];
            [_fview addGestureRecognizer:tapGestureTel];
            UIImageView*img=  [[UIImageView alloc]initWithFrame:CGRectMake(_fview.bounds.size.width-30,6, 20,20)];
            img.image = [UIImage imageNamed:@"callImage.png"];
            [_fview addSubview:img];
            
        }
        if(i==2)
        {
            UITapGestureRecognizer *tapGestureMap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(mapButtonEvent:)];
            [_fview addGestureRecognizer:tapGestureMap];
            UIImageView*img=  [[UIImageView alloc]initWithFrame:CGRectMake(_fview.bounds.size.width-30,6, 20,20)];
            img.image = [UIImage imageNamed:@"map_24.png"];
            [_fview addSubview:img];
        }
        [_scrollView addSubview:_fview];
        
    }
    [cell addSubview:_scrollView];
    return cell;
}
-(void)pressviewcontroller:(UIViewController*)nview{
    if (!mIsEdit) {
        [self presentViewController:nview
                           animated:YES
                         completion:^(void){}];
    }
    else{
        if (self.editview !=nil) {
            [self.editview presentViewController:nview
                                        animated:YES
                                      completion:^(void){}];
            return;
        }
        if (self.lockview !=nil) {
            [self.lockview presentViewController:nview
                                        animated:YES
                                      completion:^(void){}];
            return;
        }
    }

}
/*跳转至 车辆位置*/
-(void)mapButtonEvent:(UITapGestureRecognizer *)tapGestureRecognizer
{
    
    if (![self.mOrder.Supplier.SupplierPlateNum isEqualToString:@""]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle:nil];

        //跳转至 车辆位置
        NearMapViewController *nview =[storyboard
                                       instantiateViewControllerWithIdentifier:@"nearmap"];
        
        nview.mOrderInfo  = self.mOrder;
        nview.isFromEdit = YES;
        [self pressviewcontroller:nview];
        
    }
}
/*电话拨打*/
-(void)teleButtonEvent:(UITapGestureRecognizer *)tapGestureRecognizer
{
    
    if (![self.mOrder.Supplier.SupplierPhone isEqualToString:@""]) {
        NSString *phone =self.mOrder.Supplier.SupplierPhone;
        if (self.mOrder.Supplier.SupplierPhone.length>11) {
            phone = [self.mOrder.Supplier.SupplierPhone substringToIndex:11];
        }
        NSString *msg = [NSString stringWithFormat:@"确定拨打:%@",phone];
        UIAlertView*  alertview =[[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles: @"取消",nil];
        alertview.tag=444;
        [alertview show];
    }
}
/*获取每行的高度*/
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 44;
    NSString* title = self.tvtitles[indexPath.row];
//    if ([title isEqualToString:@"地址"]) {
//        height=60;
//    }
    height = [self setHeightbyrowtitle:title];
    return height;
    
}
-(CGFloat)setHeightbyrowtitle:(NSString *)title{
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return self.tvtitles.count;
}
/*设置每行的布局*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]){
        static NSString *ID = @"cell";
        UITableViewCell *   ncell;
        ncell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
        ncell.textLabel.textColor =[UIColor lightGrayColor];
        ncell.textLabel.font=[UIFont systemFontOfSize:(14)];
        ncell.textLabel.text=self.tvtitles[indexPath.row] ;
        ncell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; //显示最右边的箭头
        
        ncell.detailTextLabel.textColor =[UIColor blackColor];
        
        NSString* title =self.tvtitles[indexPath.row];
        
        NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
        
       
        
        
      
        if ([title isEqualToString:@"预约时间"]) {
            LanuchTableViewCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"lanuchcell"];
            if (!fcell)
            {
                [tableView registerNib:[UINib nibWithNibName:@"LanuchTableViewCell" bundle:nil] forCellReuseIdentifier:@"lanuchcell"];
                fcell = [tableView dequeueReusableCellWithIdentifier:@"lanuchcell"];
                
                
            }
            
            if (self.mOrder.IsWithinCall  &&((mIsEdit && mIsOrderLock)|| !mIsEdit))
            {
                if ([mcarCount isEqual:[NSNull null]]) {
                    mcarCount=@"0";
                }
                NSString *str=[NSString stringWithFormat:@"附近有%@辆车",mcarCount];
                fcell.lb_key.text=str;
                // [fcell.radioButtonnow setSelected:YES];
                
            }
            else{
                NSDateFormatter*  formatter = [[NSDateFormatter alloc] init];
                
                [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
                fcell.lb_key.text =[formatter stringFromDate:self.mOrder.LaunchDateTime] ;
                // [fcell.radioButton setSelected:YES];
                
            }
            if (self.mOrder.IsWithinCall) {
                [fcell.radioButtonnow setSelected:YES];
            }else{
                [fcell.radioButton setSelected:YES];
            }
            
            [fcell.radioButton setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
            [fcell.radioButton setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
            [fcell.radioButtonnow setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
            [fcell.radioButtonnow setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
            [fcell.radioButton  addTarget:self action:@selector(onRadioButtonValueChanged:) forControlEvents:UIControlEventValueChanged];
            [fcell.radioButtonnow  addTarget:self action:@selector(onRadioButtonValueChanged:) forControlEvents:UIControlEventValueChanged];
            
          
            if (mIsEdit && mIsOrderLock) {
                fcell.userInteractionEnabled = NO;
                if (self.mOrder.IsWithinCall) {
                    fcell.radioButton.hidden=YES;
                    fcell.radioButtonnow.hidden=NO;
                }else{
                    fcell.radioButton.hidden=NO;
                    fcell.radioButtonnow.hidden=YES;
                }
                
            }else{
                fcell.userInteractionEnabled = YES;
            }

            lblcarcount= fcell.lb_key;
            return fcell;
            
            
        }
        if ([title isEqualToString:@"大约里程数(公里)"]) {
            ncell.detailTextLabel.text= [NSString stringWithFormat:@"%.1f",[self.mOrder.KiloMeters floatValue] ];
           // ncell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.KiloMeters];
        }
        
        if ([title isEqualToString:@"地图查看"])
        {
            
            
            MapTableViewCell *mcell = [tableView dequeueReusableCellWithIdentifier:@"map"];
            if (!mcell)
            {
                [tableView registerNib:[UINib nibWithNibName:@"MapTableViewCell" bundle:nil] forCellReuseIdentifier:@"map"];
                mcell = [tableView dequeueReusableCellWithIdentifier:@"map"];
                
                
            }
            if (self.mOrder.Status==3) {
//                mcell.lb_WaitingCount.text=@"";
//                mcell.lb_DeclineCount.text=@"";
//                mcell.lb_text1.text=@"";
//                mcell.lb_text3.text=@"";
//                mcell.lb_text2.text=@"";
//                mcell.lb_DeclineCount.hidden=YES;
//                mcell.lb_text1.hidden=YES;
                mcell.lb_text3.hidden=NO;
//                mcell.lb_text2.hidden=YES;
//                mcell.lb_WaitingCount.hidden=YES;
                if (!(self.mOrder.ShowWaitingCount || self.mOrder.ShowDriverCount)) {
//                    mcell.lb_WaitingCount.text=@"";
//                    mcell.lb_DeclineCount.text=@"";
//                    mcell.lb_text1.text=@"";
                    mcell.lb_text3.text=@"";
//                    mcell.lb_text2.text=@"";
                }
                else{
                    
                    NSInteger cr=0;
                    NSInteger cr1=0;
                    NSString *contentStr = @"已通知";
                    NSString *contentStr2 = @"";
                    if (self.mOrder.ShowWaitingCount) {
                        
                        NSString *strcount =[NSString stringWithFormat:@"%@",self.mOrder.WaitingCount];
                        contentStr  =[contentStr stringByAppendingString:strcount ];
                        
                        contentStr  =[contentStr stringByAppendingString:@"家租赁公司."];
                        
                        cr = strcount.length;
                        
                    }
                    
                    if (self.mOrder.ShowDriverCount) {
                        NSString *strcount =[NSString stringWithFormat:@"%@",self.mOrder.DriverCount];
                        contentStr2  =[contentStr2 stringByAppendingString: strcount];
                        cr1 = strcount.length;
                        contentStr2  =[contentStr2 stringByAppendingString:@"名司机."];
                    }
                    //NSString *contentStr3 = @"请耐心等待";
//                    if (self.mOrder.PriceType==1) {
//                        contentStr3 =[contentStr3 stringByAppendingString:@",或调整价格."];
//                        
//                    }else
//                    {
//                        contentStr3 =[contentStr3 stringByAppendingString:@"."];
//                    }
                      NSString *constr =[NSString stringWithFormat:@"%@%@",contentStr,contentStr2];
//                    NSString *constr =[NSString stringWithFormat:@"%@%@%@",contentStr,contentStr2,contentStr3];
                    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:constr];
                    if (cr>0 && contentStr.length>0) {
                        [str addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(3, cr)];
                    }
                    if (cr1>0) {
                        [str addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(contentStr.length, cr1)];
                    }
                    
                    mcell.lb_text3.attributedText = str;
                    
                }
                
            }else{
//                mcell.lb_DeclineCount.hidden=YES;
//                mcell.lb_text1.hidden=YES;
//                mcell.lb_text2.hidden=YES;
                mcell.lb_text3.hidden=YES;
//                mcell.lb_WaitingCount.hidden=YES;
            }
            if (self.mOrder.PriceType==0) {
                mcell.lb_map.hidden=YES;
                mcell.iv_map.hidden=YES;
            }else{
                mcell.lb_map.hidden=NO;
                mcell.iv_map.hidden=NO;
                
            }
            if(self.mOrder.OrderType>0)
            {
                mcell.lb_map.hidden=YES;
                mcell.iv_map.hidden=YES;
            }
            mcell.lb_map.hidden=NO;
            mcell.iv_map.hidden=NO;
            return mcell;
        }
        if ([title isEqualToString:@"车型"])
            
        {
            NSString * vc =[VGtitles objectAtIndex:self.mOrder.VehicleCategory];
            NSString *vt=@"";
            if (self.mOrder.VehicleCategory<=1) {
                vt=[VTtitles objectAtIndex:self.mOrder.VehicleType];
            }
            ncell.detailTextLabel.text=[NSString stringWithFormat:@"%@ %d座 %@",vc,self.mOrder.SeatCount,vt];
            
            
        }
        
        
        if ([title isEqualToString:@"价格类型"])
        {
            if (self.mOrder.PriceType==1) {
                ncell.detailTextLabel.text=@"竞价";
                
            }else  if (self.mOrder.PriceType==0){
                ncell.detailTextLabel.text=@"合同价";
                
            }else  if (self.mOrder.PriceType==2){
                ncell.detailTextLabel.text=@"市场价";
                
            }
        }
        
        if ([title isEqualToString:@"价格"])
        {
            ncell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.ContractFinalPrice];
        }
        if ([title isEqualToString:@"已收款额"])
        {
            mareadypay =ncell.detailTextLabel;
            ncell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.AlreadyPay];
        }
        
        if ([title isEqualToString:@"上调基数"])
        {
            
            RebateTableViewCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"rebatecell"];
            if (!fcell)
            {
                [tableView registerNib:[UINib nibWithNibName:@"RebateTableViewCell" bundle:nil] forCellReuseIdentifier:@"rebatecell"];
                fcell = [tableView dequeueReusableCellWithIdentifier:@"rebatecell"];
                
                
            }
            double rebate =[self.mOrder.Rebate doubleValue];
            rebate = round(rebate);
            NSString *str =[NSString stringWithFormat:@"上调基数:%@  返佣金额:%.0f",[self GetMarketPriceRatio],rebate];
            
            fcell.lbkey.text=str;
            return fcell;
        }
        
        if ([title isEqualToString:@"竞价"])
            
        {
            
            
            FinalTableViewCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"finalpcell"];
            if (!fcell)
            {
                [tableView registerNib:[UINib nibWithNibName:@"FinalTableViewCell" bundle:nil] forCellReuseIdentifier:@"finalpcell"];
                fcell = [tableView dequeueReusableCellWithIdentifier:@"finalpcell"];
                
                
            }
            
            fcell.lbPrice.text =[numberFormatter stringFromNumber:self.mOrder.FinalPrice];
            [fcell.left addTarget:self action:@selector(caleMinusPrice:) forControlEvents:UIControlEventTouchUpInside];
            [fcell.right addTarget:self action:@selector(caleAddPrice:) forControlEvents:UIControlEventTouchUpInside];
            fcell.left.layer.borderWidth = 1.f;//设置边框宽度
            
            fcell.left.layer.borderColor = [UIColor lightGrayColor].CGColor;//设置边框颜色
            
            fcell.left.layer.cornerRadius = 6.f;
            
            fcell.right.layer.borderWidth = 1.f;//设置边框宽度
            
            fcell.right.layer.borderColor = [UIColor lightGrayColor].CGColor;//设置边框颜色
            
            fcell.right.layer.cornerRadius = 6.f;
            
            if (self.mOrder.PriceType ==2) {
                fcell.left.hidden=YES;
                fcell.right.hidden=YES;
                
            }else{
                fcell.left.hidden=NO;
                fcell.right.hidden=NO;
            }
            mlblprice=fcell.lbPrice;
            return fcell;
        }
        
        if ([title isEqualToString:@"优先级"])
            
        {
            
            [rankcheckboxes removeAllObjects];
            
            RankTableViewCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"rankcell"];
            if (!fcell)
            {
                [tableView registerNib:[UINib nibWithNibName:@"RankTableViewCell" bundle:nil] forCellReuseIdentifier:@"rankcell"];
                fcell = [tableView dequeueReusableCellWithIdentifier:@"rankcell"];
                
                
            }
            
            SSCheckBoxView *cbv = nil;
            CGRect frame = CGRectMake(40, 0, 120, 0);
            for (int i = 0; i < RanksArray.count; ++i) {
                SSCheckBoxViewStyle style = kSSCheckBoxViewStylesYellow;
                BOOL checked =false;
                
                for (NSNumber * rankstr in self.mOrder.PriorityList) {
                    
                    if ([[rankstr stringValue] isEqualToString:RanksArray[i]]) {
                        checked=true;
                        break;
                    }
                }
                
                cbv = [[SSCheckBoxView alloc] initWithFrame:frame
                                                      style:style
                                                    checked:checked];
                [cbv setText:RanksArray[i]];
                [fcell.cbview addSubview: cbv];
                
                
                [rankcheckboxes addObject:cbv];
                
                if(i==0)
                {
                    frame.origin.x += 60;
                    [cbv setStateChangedBlock:^(SSCheckBoxView *v) {
                        [self checkBoxViewChangedState:v];
                    }];
                }
                else{
                    frame.origin.x += 45;
                    [cbv setStateChangedBlock:^(SSCheckBoxView *v) {
                        [self checkBoxViewChangedState2:v];
                    }];
                }
            }
            
            if (mIsEdit && mIsOrderLock) {
                fcell.userInteractionEnabled = NO;
            }else{
              fcell.userInteractionEnabled = YES;
            }
            
            return fcell;
            
        }
        if ([title isEqualToString:@"备注"])
        {
            ncell.detailTextLabel.text = [self.mOrder.Memo isEqual:[NSNull null]]?@"":self.mOrder.Memo;
        }
        if ([title isEqualToString:@"内部备注"])
        {
            ncell.detailTextLabel.text = [self.mOrder.InternalMemo isEqual:[NSNull null]]?@"":self.mOrder.InternalMemo;        }
        
        if ([title isEqualToString:@"客人姓名"]){
            ncell.detailTextLabel.text = [self.mOrder.CustomerName isEqual:[NSNull null]]?@"":self.mOrder.CustomerName;
        }
        if ([title isEqualToString:@"客人电话"]){
            ncell.detailTextLabel.text = [self.mOrder.CustomerName isEqual:[NSNull null]]?@"":self.mOrder.CustomerPhone
            ;
        }
        if ([title isEqualToString:@"车单号"])
            ncell.detailTextLabel.text =[self.mOrder.CheckDocumentSN isEqual:[NSNull null]]?@"":self.mOrder.CheckDocumentSN;
        
        if ([title isEqualToString:@"房间号"])
            ncell.detailTextLabel.text =[self.mOrder.RoomSN isEqual:[NSNull null]]?@"":self.mOrder.RoomSN;
        
        
        return [self setcellForRow:title cell:ncell indexpath:indexPath tableview:tableView];
        
    }
    return nil;

}

#pragma mark 操作
-(void)caleMinusPrice:(UIButton *)sender{
    [_pickview remove];
    [_zhpickview remove];
    self.svinfo.hidden=NO;
    [self setButton];
    double price =[self.mOrder.FinalPrice doubleValue]- [self.mOrder.BasePrice doubleValue] *0.05;
    price = price<=0?0:price;
    
    self.mOrder.FinalPrice = [NSNumber numberWithDouble:round(price) ];
    if ([self GetSyncPay]) {
        self.mOrder.AlreadyPay =self.mOrder.FinalPrice;
    }
    [self.tableView reloadData];
    
}
-(void)caleAddPrice:(UIButton *)sender{
    [_pickview remove];
    [_zhpickview remove];
    self.svinfo.hidden=NO;
    [self setButton];
    double price =[self.mOrder.FinalPrice doubleValue]+[self.mOrder.BasePrice doubleValue] *0.05;
    self.mOrder.FinalPrice = [NSNumber numberWithDouble: round(price) ];
    if ([self GetSyncPay]) {
        self.mOrder.AlreadyPay =self.mOrder.FinalPrice;
    }
    [self.tableView reloadData];
}

-(void) onRadioButtonValueChanged:(RadioButton*)sender
{
    [_pickview remove];
    [_zhpickview remove];
    // Lets handle ValueChanged event only for selected button, and ignore for deselected
    if(sender.selected) {
        self.svinfo.hidden=NO;
        [self setButton];
        NSLog(@"Selected color: %@", sender.titleLabel.text);
        if ([sender.titleLabel.text isEqualToString:@"现在"]) {
            self.mOrder.IsWithinCall=YES;
            if ((mIsOrderLock && mIsEdit)|| !mIsEdit) {
                LanuchTableViewCell * cell = (LanuchTableViewCell *)[[sender superview] superview];
                NSString *str=[NSString stringWithFormat:@"附近有%@辆车",mcarCount];
                cell.lb_key.text=str;
                [self GetNearCarCount];
                [self  restartnearnstime];
            }
            
        }else{
            [self stopnearnstime];
            self.mOrder.IsWithinCall=NO;
            [self reloadTableview];
        }
    }
    
}
-(void)geoCodeSearchbyAddress:(NSString*)addr isstop:(BOOL)isStop
{
    BMKGeoCodeSearchOption *geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc]init];
    geoCodeSearchOption.city= @"上海市";
    geoCodeSearchOption.address = addr;
    BOOL flag = [self.geoCode geoCode:geoCodeSearchOption];
    
    if(flag)
    {
        NSLog(@"geo检索发送成功");
    }
    else
    {
        //人民广场
        self.mOrder.Start_latitude = 31.235301;
        self.mOrder.Start_longitude = 121.481139;
        [self PostGetNearCarCount];
//        if (!isStop) {
//            [self geoCodeSearchbyAddress:@"人民广场" isstop:YES];
//        }
        NSLog(@"geo检索发送失败");
    }

}
-(void)stopnearnstime
{
    if (!mIsEdit) {
        isnearstop =YES;
        //stop
        if (nearnstime!=nil) {
            [nearnstime setFireDate:[NSDate distantFuture]];
        }
    }
}
-(void)restartnearnstime
{
    if (!mIsEdit && isnearstop) {
        if (nearnstime!=nil) {
            [nearnstime setFireDate:[[NSDate alloc]initWithTimeIntervalSinceNow:10]];
        }
    }
}
-(void) GetNearCarCount
{
    if (!self.mOrder.IsWithinCall) {
        return;
    }
    if ([self.mOrder.StartLocation isEqualToString:@""]) {
        return;
    }
    [self stopnearnstime];
    NSLog(@"GetNearCarCount--%d--%f--%f",self.mOrder.OrderType,self.mOrder.Start_longitude,self.mOrder.Start_latitude);
    if (self.mOrder.OrderType==3 && self.mOrder.Start_longitude>0 && self.mOrder.Start_latitude>0) {
        [self PostGetNearCarCount];
    }else{
     [self geoCodeSearchbyAddress:self.mOrder.StartLocation isstop:NO];
    }
       // [self PostGetNearCarCount];
}
//实现Deleage处理回调结果
//接收正向编码结果

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
        NSString *locationString = [NSString stringWithFormat:@"经度为：%.2f   纬度为：%.2f", result.location.longitude, result.location.latitude];
        NSLog(@"经纬度为：%@ 的位置结果是：%@", locationString, result.address);
        self.mOrder.Start_latitude=result.location.latitude;
        self.mOrder.Start_longitude=result.location.longitude;
        [self PostGetNearCarCount];
    }
    else {
        //人民广场
        self.mOrder.Start_latitude=31.235301;
        self.mOrder.Start_longitude=121.481139;
        [self PostGetNearCarCount];

      //   [self geoCodeSearchbyAddress:@"人民广场" isstop:YES];
        NSLog(@"抱歉，未找到结果");
    }
}
-(void) PostGetNearCarCount{
    NSString *carstr=@"附近车辆获取中...";
    lblcarcount.text=carstr;
    // 初始化Manager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为我们要获取text/plain类型数据
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //如果报接受类型不一致请替换一致text/html或别的
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    [parameters setValue:[NSString stringWithFormat:@"%f",self.mOrder.Start_longitude] forKey:@"lng"];
    [parameters setValue:[NSString stringWithFormat:@"%f",self.mOrder.Start_latitude] forKey:@"lat"];
    int booking_company_id=0;
    if (myAppDelegate.mCompanyInfo!=nil) {
        booking_company_id=myAppDelegate.mCompanyInfo.KeyID;
    }
    [parameters setValue:[NSString stringWithFormat:@"%d",booking_company_id] forKey:@"booking_company_id"];
    
    
    NSLog(@"GetNearCarCount-%d--%@",self.mOrder.OrderType, parameters);
    NSString *str = [mDriverServerUrl stringByAppendingString:@"Gps/GetNearCarCount"];
    [manager POST:str parameters:parameters
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              //  [MBProgressHUD hideHUDForView:self.view animated:YES];
              NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];
              
              NSLog(@"dic--%@", dic);
              NSString* result =(NSString*)[dic objectForKey:@"success"] ;
              if ([result longLongValue]==(long)1){
                  NSString *carcount =(NSString*)[dic objectForKey:@"carCount"] ;
                  mcarCount = carcount;
                   NSString *str=[NSString stringWithFormat:@"附近有%@辆车",mcarCount];
                  lblcarcount.text=str;
                 // [self reloadTableview];
                  
              }else{
                  lblcarcount.text=@"附近有0辆车";
//                  NSString *msg = @"提交失败";
//                  msg =[dic objectForKey:@"errMessage"] ;
//                  UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"提交失败" message:msg delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
//                  
//                  [alter show];
                  //return;
                  
              }
              [self restartnearnstime];
              
              
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
               lblcarcount.text=@"附近有0辆车";
              [myAppDelegate onhttpfailed:self error:[error localizedDescription]];
              //[self alertviewclick:@"请求失败"];
              //  [self alerterror:error  url:str];
              // 请求失败
              NSLog(@"error--%@", [error localizedDescription]);
          }
     ];
    
}
- (void) checkBoxViewChangedState:(SSCheckBoxView *)cbv
{
    [_pickview remove];
    [_zhpickview remove];
  
    if (self.mOrder.PriorityList==nil) {
        self.mOrder.PriorityList = [[NSMutableArray alloc]init];
    }
    if (cbv.checked) {
        for (int i = 1; i < rankcheckboxes.count; ++i) {
            SSCheckBoxView *bv= rankcheckboxes[i];
            bv.checked=false;
        }
        self.mOrder.PriorityList = [[NSMutableArray alloc]init];
    }
    
    if (self.mOrder.PriorityList==0) {
        cbv.checked=true;
    }
}
- (void) checkBoxViewChangedState2:(SSCheckBoxView *)cbv
{
    [_pickview remove];
    [_zhpickview remove];
   
    if (self.mOrder.PriorityList ==nil) {
        self.mOrder.PriorityList= [[NSMutableArray alloc]init];
    }
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    
    NSNumber* ranknum =[numberFormatter numberFromString: cbv.textLabel.text  ];
    if (cbv.checked) {
        
        int index =(int)self.mOrder.PriorityList.count;
        if (index==0 || ![self.mOrder.PriorityList containsObject:ranknum]) {
            
            [self.mOrder.PriorityList insertObject: ranknum atIndex: index];
        }
        if (self.mOrder.PriorityList>0) {
            SSCheckBoxView *bv= rankcheckboxes[0];
            bv.checked=false;
        }
    }
    else{
        
        [self.mOrder.PriorityList removeObject:ranknum];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* title = self.tvtitles[indexPath.row];
    if (self.mIsEdit && self.mIsOrderLock) {
        if (![title isEqualToString:@"价格"]) {
            return;
        }
        
    }
    self.svinfo.hidden=NO;
    [_pickview remove];
    [_zhpickview remove];
    MMPopupCompletionBlock completeBlock = ^(MMPopupView *popupView, BOOL finished){
        NSLog(@"animation complete");
    };
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];

   
    if( ![self didcellForRow: title  indexpath:indexPath])
        return;
    
    
    if ([title isEqualToString:@"预约时间"]) {
        if(self.mOrder.IsWithinCall &&  !mIsEdit)
        {
            
            NearMapViewController *view =[storyboard
                                          instantiateViewControllerWithIdentifier:@"nearmap"];
            view.address = self.mOrder.StartLocation;
            
           [self pressviewcontroller:view];
            
            
        }
        else{
            DateTimePickerView *selectDatePicker1 = [[DateTimePickerView alloc] initWithWidth:[UIScreen mainScreen].bounds.size.width Height:352 TimeType:timeDetail WithSheetTitle:@"预约时间"];
            selectDatePicker1.delegate = self;
            self.datePicker1 = selectDatePicker1;
            
            [self.datePicker1 viewLoad:self.mOrder.LaunchDateTime];
            [self.datePicker1 showInView:self.view];
        }
    }
    if ([title isEqualToString:@"大约里程数(公里)"]){
           NSString* msg = @"实际公里数超出大约总公里数5%的以上部分,将按照每公里5.00元额外收费。";
            if(self.mOrder.OrderType==0)
            {
                msg = [msg stringByAppendingString:@"(上海市外环线内接送机路程为50公里)"];
            }
            MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入大约公里数" detail:msg placeholder:@"1～10000的整数" handler:^(NSString *text) {
                NSLog(@"input:%@",text);
                int ivalue=[text intValue];
                if (ivalue>=1&& ivalue<=10000) {
                    self.mOrder.KiloMeters=[NSNumber numberWithInt:ivalue];
                    if (self.mOrder.PriceType>=1) {
                        [self CalePrice];
                    }
                    else{
                        [self.tableView reloadData];
                    }
                    
                }
                NSLog(@"intinput:%d",[text intValue]);
                
            } minvalue:1 maxvalue:10000 nowvalue:self.mOrder.KiloMeters] ;
            
            alertView.attachedView = self.view;
            alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
            alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
            [alertView showWithBlock:completeBlock];
        }
    if ([title isEqualToString:@"地图查看"]) {
        if (self.mOrder.PriceType>0 && self.mOrder.OrderType!=3) {
            
            
            
            MapViewController *view =[storyboard
                                      instantiateViewControllerWithIdentifier:@"mapView"];
            view.mStartLocation = self.mOrder.StartLocation;
            view.mDestination = self.mOrder.Destination;
            view.mDestinationCity = self.mOrder.DestinationCity ==nil?@"上海市":self.mOrder.DestinationCity;
            
            view.mStartLocationCity = self.mOrder.StartLocationCity == nil?@"上海市":self.mOrder.StartLocationCity;
            [self pressviewcontroller:view];
        }

    }
    
    if ([title isEqualToString:@"车型"]) {
        int DisableVehicleCategory=0;
        int DisableVehicleType=0;
        if (self.mUIConfig !=nil ) {
            
            DisableVehicleCategory = self.mUIConfig.DisableVehicleCategory;
            DisableVehicleType=self.mUIConfig.DisableVehicleType;
            if (self.mUIConfig.DisableVehicleCategory==15) {
                return;
            }
            
            
        }
        [_pickview remove];
        
        _pickview=[[VehiclePickView alloc] initPickviewWithPlistName:@"车型" isHaveNavControler:NO disableVehicleCategory:DisableVehicleCategory disableVehicleType:DisableVehicleType];
        _pickview.templates = self.templates;
        //  [_pickview setDefalutSelectValue:@"大巴" sec:@"37座" thi:@""];
        NSString * thstr=@"";
        if (self.mOrder.VehicleCategory<=1) {
            thstr = VTtitles[self.mOrder.VehicleType];
        }
        NSString * secstr = [NSString stringWithFormat:@"%d座",self.mOrder.SeatCount];
        
        [_pickview setDefalutSelectValue:VGtitles[self.mOrder.VehicleCategory] sec:secstr thi:thstr];
        _pickview.delegate=self;
        
        [_pickview show];

    }
    if ([title isEqualToString:@"价格类型"]) {
        [_zhpickview remove];
        NSArray *arr = @[@"合同价",@"竞价",@"市场价"];
        TemplateInfo *info=[self GetTemplateInfoByOrder];
        if (info!=nil) {
//            self.mOrder.VehicleCategory = info.VehicleCategory;
//            self.mOrder.VehicleType =info.VehicleCategory<2?info.VehicleType:0;
//            self.mOrder.SeatCount = info.SeatCount;
            switch (info.PriceType) {
                case 1:
                case 3:
                case 5:
                case 7:
                    if (info.PriceType==1) {
                        arr = @[@"竞价"];
                    }else if (info.PriceType==3){
                        arr = @[@"竞价",@"市场价"];
                    }else if (info.PriceType==5){
                        arr = @[@"合同价",@"竞价"];
                    }
                    break;
                case 2:
                case 6:
                    if (info.PriceType==2) {
                        arr = @[@"市场价"];
                    }else{
                        arr = @[@"合同价",@"市场价"];
                    }
                    break;
                case 4:
                    arr = @[@"合同价"];
                    break;
                default:
                    break;
            }
            
            
        }
        
        
        _zhpickview=[[ZHPickView alloc] initPickviewWithArray:arr isHaveNavControler:NO];
        
        
        NSString *str=@"合同价";
        if (self.mOrder.PriceType==1) {
            str=@"竞价";
            
        }else if (self.mOrder.PriceType==2) {
            str=@"市场价";
            
        }
        [_zhpickview setDefaultValue:str];
        _zhpickview.delegate=self;
        
        [_zhpickview show];
    }
    if ([title isEqualToString:@"价格"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入价格" detail:@"信用卡另收5%手续费" placeholder:@"" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            
            self.mOrder.ContractFinalPrice=[NSNumber numberWithFloat:[text floatValue]];
            if ([self GetSyncPay]) {
                self.mOrder.AlreadyPay=[NSNumber numberWithFloat:[text floatValue]];
            }else{
                self.mOrder.AlreadyPay=[NSNumber numberWithDouble:0];
            }
            //刷新表格
            [self.tableView reloadData];
            
            
            
        }keyboardType:UIKeyboardTypeDecimalPad  nowvalue:self.mOrder.ContractFinalPrice] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
    if ([title isEqualToString:@"已收款额"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入已收款额" detail:@"信用卡另收5%手续费" placeholder:@"" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            
            
            self.mOrder.AlreadyPay=[NSNumber numberWithFloat:[text floatValue]];
            //刷新表格
            [self.tableView reloadData];
            
            
            
        }keyboardType:UIKeyboardTypeDecimalPad  nowvalue:self.mOrder.AlreadyPay] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
    if ([title isEqualToString:@"备注"] || [title isEqualToString:@"内部备注"] ) {
        RemarkViewController *view =[storyboard
                                     instantiateViewControllerWithIdentifier:@"remarkView"];
         view.mtitle=title;
        if([title isEqualToString:@"备注"] )
        {
            view.remark=self.mOrder.Memo;
        }else {
            view.morderID=self.mOrder.OrderID;
            view.remark=self.mOrder.InternalMemo;
        }
        view.delegate = self;
       [self pressviewcontroller:view];
    }
    if ([title isEqualToString:@"客人姓名"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入客人姓名" detail:@"" placeholder:@"" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            
            self.mOrder.CustomerName=text;
            //刷新表格
            [self.tableView reloadData];
            
            
            
        }keyboardType:UIKeyboardTypeDefault  value:self.mOrder.CustomerName] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
    if ([title isEqualToString:@"客人电话"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入客人电话" detail:@"" placeholder:@"" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            
            self.mOrder.CustomerPhone=text;
            //刷新表格
            [self.tableView reloadData];
            
            
            
        }keyboardType:UIKeyboardTypePhonePad  value:self.mOrder.CustomerPhone] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
     if ([title isEqualToString:@"车单号"]) {
         MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入车单号" detail:@"" placeholder:@"" handler:^(NSString *text) {
             NSLog(@"input:%@",text);
             
             self.mOrder.CheckDocumentSN=text;
             //刷新表格
             [self.tableView reloadData];
             
             
             
         }keyboardType:UIKeyboardTypeDefault  value:self.mOrder.CheckDocumentSN] ;
         
         alertView.attachedView = self.view;
         alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
         alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
         [alertView showWithBlock:completeBlock];

    }
    if ([title isEqualToString:@"房间号"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入房间号" detail:@"" placeholder:@"" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            
            self.mOrder.RoomSN=text;
            //刷新表格
            [self.tableView reloadData];
            
            
            
        }keyboardType:UIKeyboardTypeDefault  value:self.mOrder.RoomSN] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
   
}

#pragma mark 代理方法
// 代理方法
-(void)selectDate:(NSString *)result{
    if (result == nil) {
        return;
    }
    NSDateFormatter *formater = [[NSDateFormatter alloc] init] ;
    
    
    [formater setDateFormat:@"yyyy年MM月dd日 HH时mm分"];
    NSDate *resultDate = [formater dateFromString:result];
    
    self.mOrder.LaunchDateTime =resultDate;
    //刷新表格
    [self.tableView reloadData];
    
    
    
}

#pragma mark - 窗口返回内容相关
- (void)passLeftAddressValue:(NSString *)value
{
    self.mOrder.StartLocation=value;
    if (self.mOrder.IsWithinCall) {
        [self GetNearCarCount];
    }
    //刷新表格
    [self.tableView reloadData];
    if (self.mOrder.PriceType>=1 && self.mOrder.OrderType==0) {
        [self CalePrice];
    }
  
    
    
}
- (void)passRightAddressValue:(NSString *)value
{
    self.mOrder.Destination=value;
    //刷新表格
    [self.tableView reloadData];
    if (self.mOrder.PriceType>=1&& self.mOrder.OrderType==0) {
        [self CalePrice];
    }
    
}
- (void)passMemoValue:(NSString *)value
{
    self.mOrder.Memo=value;
    //刷新表格
   // [self.tableView reloadData];
    [self reloadTableview];
    
}
- (void)passInternalMemoValue:(NSString *)value
{
    self.mOrder.InternalMemo=value;
    //刷新表格
   // [self.tableView reloadData];
     [self reloadTableview];
}
-(void) setDefaultPriority
{
     self.mOrder.PriorityList= [[NSMutableArray alloc]init];
    NSMutableArray * mrankarr=[[NSMutableArray alloc]init];
    
    
    TemplateInfo *info=[self GetTemplateInfoByOrder];
    if (info!=nil) {
        if ((info.Priority & 1)>0) {
            [mrankarr addObject:@"1"];
        }
        if ((info.Priority & 2)>0) {
            [mrankarr addObject:@"2"];
        }
        if ((info.Priority & 4)>0) {
            [mrankarr addObject:@"3"];
        }
        
        
       
        
        for (int j = 0; j < mrankarr.count; ++j)
        {
            NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
            
            NSNumber* ranknum =[numberFormatter numberFromString: mrankarr[j]];
            int index =self.mOrder.PriorityList.count ;
            if (index==0 || ![self.mOrder.PriorityList containsObject:ranknum]) {
                
                [self.mOrder.PriorityList insertObject: ranknum atIndex: index];
            }
        }
        
    }

}
/*车型*/
-(void)VCtoobarDonBtnHaveClick:(VehiclePickView *)pickView resultString:(NSString *)resultString{
    NSArray *aArray = [resultString componentsSeparatedByString:@" "];
    if (aArray.count==3) {
        NSString * fstr = aArray[0];
        for (int i=0; i<VGtitles.count; i++) {
            if ([VGtitles[i] isEqualToString:fstr]) {
                self.mOrder.VehicleCategory=i;
                break;
            }
        }
        NSString* secstr = aArray[1];
        self.mOrder.SeatCount = [secstr intValue];
        if (![aArray[2] isEqualToString:@""]) {
            for (int i=0; i<VTtitles.count; i++) {
                if ([VTtitles[i] isEqualToString:aArray[2]]) {
                    self.mOrder.VehicleType=i;
                    break;
                }
            }
        }
    }
    
    
    
    TemplateInfo *info=[self GetTemplateInfoByOrder];
    [self setDefaultPriority];
    
    
    [self setOrderByTempalte:info];
    if (aArray !=nil) {
        if (self.mOrder.PriceType>=1) {
            [self CalePrice];
        }
        else{
            if ([self GetSyncPay]) {
                self.mOrder.AlreadyPay=self.mOrder.ContractFinalPrice;
            }else{
              self.mOrder.AlreadyPay=0;
            }
            [self reloadTableview ];
            
        }
    }
    
}
/*价格*/
-(void)toobarDonBtnHaveClick:(ZHPickView *)pickView resultString:(NSString *)resultString{
    isGetDefaultPriceType = NO;
    if ([resultString isEqualToString:@"合同价"]) {
        self.mOrder.PriceType=0;
        [self reloadTableview];
    }else  if ([resultString isEqualToString:@"竞价"]) {
        self.mOrder.PriceType=1;
        [self CalePrice];
    }else  if ([resultString isEqualToString:@"市场价"]) {
        self.mOrder.PriceType=2;
        [self CalePrice];
    }
    
    
    
    
}
-(void)clearpickupview
{
    [_pickview remove];
    [_zhpickview remove];
}

-(void)getOrderLock
{
    NSString *str1 =@"%@Order/GetMyWaitingOrder";
    
    NSString *urlstr = [NSString stringWithFormat:str1,mServerUrl];
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
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                     bundle:nil];
                
                OrderLockViewController*view =[storyboard
                                               instantiateViewControllerWithIdentifier:@"orderlockView"];
                view.mtype =info.OrderType;
                view.morderID = info.OrderID;
                view.mtypedetail = info.OrderTypeDescription;
                view.morderinfo = info;
                [self presentViewController:view
                                   animated:YES
                                 completion:^(void){
                                     
                                 }];
                
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
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       // [self alertviewclick:[error localizedDescription]];
        if (!mIsEdit) {
           // [myAppDelegate LogOut:self];
              [myAppDelegate onhttpfailed:self error: [error localizedDescription]];
        }
        else if(self.lockview!=nil)
        {
            [myAppDelegate onhttpfailed:self.lockview error: [error localizedDescription]];

          
        }else if(self.editview!=nil)
        {
            [myAppDelegate onhttpfailed:self.editview error: [error localizedDescription]];

      
        }

       // [self alerterror:error  url:str1];
        // 请求失败
        NSLog(@"error--%@", [error localizedDescription]);
    }];
    
    
}
-(void) playSound

{
    if (!self.mOrder.IsWithinCall) {
        return;
    }
      
      [self.mMyBaiduTTS playbaiduTTS:@"易搭已下，马上就到"];
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"YiDa2" ofType:@"wav"];
//    if (path) {
//        //注册声音到系统
//         AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:path]),&shake_sound_male_id);
//                AudioServicesPlaySystemSound(shake_sound_male_id);
//       
//        //        AudioServicesPlaySystemSound(shake_sound_male_id);//如果无法再下面播放，可以尝试在此播放
//    }
//    
//    AudioServicesPlaySystemSound(shake_sound_male_id);   //播放注册的声音，（此句代码，可以在本类中的任意位置调用，不限于本方法中）
//    
//    //    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);   //让手机震动
}




@end
