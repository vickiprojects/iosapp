//
//  ByDayViewController.m
//  Eorder
//
//  Created by ZhangLi on 16/12/19.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import "ByDayViewController.h"
#import "CitysViewController.h"
#import "AddressViewController.h"
@interface ByDayViewController ()

@end

@implementation ByDayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setCleanOrder
{
    [super setCleanOrder];
    self.mOrder.OrderType=1;
    self.mOrder.StartLocationCity=@"上海";
    self.mOrder.StartLocationProvince=@"上海";
    
    self.mOrder.DestinationCity=@"上海";
    self.mOrder.DestinationProvince=@"上海";
    self.mOrder.RentalDays= [NSNumber numberWithInt: 1];
    self.mOrder.AvgUsedHours=[NSNumber numberWithInt: 8];
    self.mOrder.StartLocation=self.mOrder.Destination;
}
/*
 table内容显示配置
 */
-(void)setChildTableviewbyTemplatesShow{
    [super setChildTableviewbyTemplatesShow];
    NSArray *title= @[@"出发城市", @"出发地" ,@"目的城市",@"行程描述",@"天数",@"平均每天用车时间(小时)"];
    [self.tvtitles addObjectsFromArray:title];
}
-(void)setChildMapShow
{
    //地图查看 1
    //状态显示 2
    BOOL isshowmap = NO;
    BOOL isshowstatus=NO;
   
    if (self.mIsEdit) {
        if (self.mOrder.Status==3 &&(self.mOrder.ShowWaitingCount|| self.mOrder.ShowDriverCount)) {
            isshowstatus=YES;
        }
    }
    if (isshowmap || isshowstatus) {
        [self.tvtitles addObject:@"地图查看"];
    }

    
}

-(UITableViewCell *)setcellForRow:title cell:(UITableViewCell * )cell
           indexpath:(NSIndexPath *)indexPath
           tableview:(UITableView *)tableView
{
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    if ([title isEqualToString:@"出发城市"]) {
        NSString *str = [NSString stringWithFormat:@"%@ %@",self.mOrder.StartLocationProvince,self.mOrder.StartLocationCity];
        cell.detailTextLabel.text=str;
    }
    if ([title isEqualToString:@"出发地"])
    {
        
        cell.detailTextLabel.text=self.mOrder.StartLocation;
    }
    if ([title isEqualToString:@"目的城市"])
    {
        NSString *str = [NSString stringWithFormat:@"%@ %@",self.mOrder.DestinationProvince,self.mOrder.DestinationCity];
        cell.detailTextLabel.text=str;
    }
    
    if ([title isEqualToString:@"行程描述"])
    {
        
        cell.detailTextLabel.text=self.mOrder.Destination;
    }
    
    if ([title isEqualToString:@"天数"])
    {
        
        
        cell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.RentalDays];
    }
    
   if ([title isEqualToString:@"平均每天用车时间(小时)"])
    {

        cell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.AvgUsedHours];
    }
    return cell;
}
-(BOOL)didcellForRow:title
           indexpath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    BOOL result = YES;
    MMPopupCompletionBlock completeBlock = ^(MMPopupView *popupView, BOOL finished){
        NSLog(@"animation complete");
    };
    if ([title isEqualToString:@"出发城市"] || [title isEqualToString:@"目的城市"]) {
       
        
        CitysViewController *view =[storyboard
                                    instantiateViewControllerWithIdentifier:@"citysView"];
        view.mtitle=title;
        if ([title isEqualToString:@"出发城市"]) {
            view.mtype=0;
            view.mcity = self.mOrder.StartLocationCity;
        }
        else{
            view.mtype=1;
            view.mcity = self.mOrder.DestinationCity;
        }
        view.delegate=self;
         [self pressviewcontroller:view];
      
    }

   if ([title isEqualToString:@"出发地"]) {
    
    AddressViewController *view =[storyboard
                                  instantiateViewControllerWithIdentifier:@"addressview"];
    
    
    view.AddrType=title;
    view.Address=self.mOrder.StartLocation;
    
    view.delegate = self;
     [self pressviewcontroller:view];
   }
    if ([title isEqualToString:@"行程描述"]) {
        RemarkViewController *view =[storyboard
                                     instantiateViewControllerWithIdentifier:@"remarkView"];
        
        view.mtitle=title;
        
        view.remark=self.mOrder.Destination;
        view.delegate = self;
    [self pressviewcontroller:view];
    }
    if ([title isEqualToString:@"天数"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入天数" detail:@"1～365整数" placeholder:@"1～365的整数" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            int ivalue=[text intValue];
            if (ivalue>=1&& ivalue<=365) {
                self.mOrder.RentalDays=[NSNumber numberWithInt:ivalue];
                //刷新表格
                if (self.mOrder.PriceType>=1) {
                    [self CalePrice];
                }
                else{
                    [self.tableView reloadData];
                }
                
            }
            NSLog(@"intinput:%d",[text intValue]);
            
        } minvalue:1 maxvalue:365 nowvalue:self.mOrder.RentalDays] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];

    }
    if ([title isEqualToString:@"平均每天用车时间(小时)"]) {
        MMAlertView *alertView = [[MMAlertView alloc] initWithInputTitle:@"请输入平均每天用车小时" detail:@"1～24整数" placeholder:@"1～24的整数" handler:^(NSString *text) {
            NSLog(@"input:%@",text);
            int ivalue=[text intValue];
            if (ivalue>=1&& ivalue<=24) {
                self.mOrder.AvgUsedHours=[NSNumber numberWithInt:ivalue];
                if (self.mOrder.PriceType>=1) {
                    [self CalePrice];
                }
                else{
                    [self.tableView reloadData];
                }
                
            }
            NSLog(@"intinput:%d",[text intValue]);
            
        } minvalue:1 maxvalue:24 nowvalue:self.mOrder.AvgUsedHours] ;
        
        alertView.attachedView = self.view;
        alertView.attachedView.mm_dimBackgroundBlurEnabled = YES;
        alertView.attachedView.mm_dimBackgroundBlurEffectStyle = UIBlurEffectStyleExtraLight;
        [alertView showWithBlock:completeBlock];
    }
    return result;
}

-(void)passCityValue:(NSString *)cityvalue pvalue:(NSString *)provincevalue type:(int)type
{
    if (type==0) {
        self.mOrder.StartLocationCity = cityvalue;
        self.mOrder.StartLocationProvince=provincevalue;
    }else{
        self.mOrder.DestinationCity = cityvalue;
        self.mOrder.DestinationProvince=provincevalue;
        
    }
    //刷新表格
    [self.tableView reloadData];
}
-(void)childSetOrder
{
}
/*
 子页提交前检查逻辑
 */
-(BOOL)checkOrder{
    return  YES;
}
@end
