//
//  PickUpViewController.m
//  Eorder
//
//  Created by ZhangLi on 16/12/16.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import "PickUpViewController.h"
#import "AddrTableViewCell.h"
#import "FlightViewController.h"

@interface PickUpViewController ()
{
}







@end

@implementation PickUpViewController
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
    self.mOrder.OrderType=0;
    self.mOrder.StartLocation=@"浦东机场";
}
-(CGFloat)setHeightbyrowtitle:(NSString *)title
{
    if ([title isEqualToString:@"地址"]) {
        return 60;
    }
    return 44;
}
/*
 table内容显示配置
 */
-(void)setChildTableviewbyTemplatesShow{
    [super setChildTableviewbyTemplatesShow];
    NSArray *title= @[@"地址"];
    [self.tvtitles addObjectsFromArray:title];
}
-(void)setChildMapShow
{
    //地图查看 1
    //状态显示 2
    BOOL isshowmap = YES;
    BOOL isshowstatus=NO;

    if (self.mIsEdit) {
        if (self.mOrder.Status==3 &&(self.mOrder.ShowWaitingCount|| self.mOrder.ShowDriverCount)) {
            isshowstatus=YES;
        }
    }
    if (isshowmap || isshowstatus) {
         [self.tvtitles addObject:@"地图查看"];
    }
    [self.tvtitles addObject:@"航班号"];

}

-(UITableViewCell *)setcellForRow:title cell:(UITableViewCell * )cell
           indexpath:(NSIndexPath *)indexPath
          tableview:(UITableView *)tableView
{
   
    if ([title isEqualToString:@"地址"])
    {
        AddrTableViewCell * addrcell = [tableView dequeueReusableCellWithIdentifier:@"pickupaddr"];
        if (!addrcell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"AddrTableViewCell" bundle:nil] forCellReuseIdentifier:@"pickupaddr"];
            addrcell = [tableView dequeueReusableCellWithIdentifier:@"pickupaddr"];
            
            
        }
        [addrcell.turnleft2right addTarget:self action:@selector(turnleft2rightButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        addrcell.left.tag=0;
        addrcell.right.tag=1;
        [addrcell.left addTarget:self action:@selector(goAddress:) forControlEvents:UIControlEventTouchUpInside];
        [addrcell.right addTarget:self action:@selector(goAddress:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.mOrder !=nil) {
            NSString * start =self.mOrder.StartLocation;
            
            if (start.length>10) {
                start = [[start substringToIndex:10] stringByAppendingString:@"..."];
                
            }
            [addrcell.left setTitle:start forState:UIControlStateNormal];
            NSString * end =self.mOrder.Destination;
            if (end.length>10) {
                end = [[end substringToIndex:10] stringByAppendingString:@"..."];
                
            }
            [addrcell.right setTitle:end forState:UIControlStateNormal];
        }
        if (self.mIsEdit && self.mIsOrderLock) {
            addrcell.userInteractionEnabled=NO;
        }
        return addrcell;

        
    }

    if ([title isEqualToString:@"航班号"]) {
        cell.detailTextLabel.text=[self.mOrder.FlightNo isEqual:[NSNull null]]?@"":self.mOrder.FlightNo;
        
    }
    return cell;
}


#pragma mark rowbutton
- (void)turnleft2rightButtonClicked:(UIButton *)sender{
    [self clearpickupview];
    AddrTableViewCell * cell = (AddrTableViewCell *)[[sender superview] superview];
    NSString *left = cell.left.titleLabel.text;
    NSString *right = cell.right.titleLabel.text;
    [cell.left setTitle:right forState:UIControlStateNormal];
    [cell.right setTitle:left forState:UIControlStateNormal];
    NSString *dest=self.mOrder.Destination;
    
    self.mOrder.Destination=self.mOrder.StartLocation;
    self.mOrder.StartLocation=dest ;
    self.svinfo.hidden=NO;
    [self setButton];
    if (self.mOrder.PriceType>=1) {
        [self CalePrice];
    }
    
    
}
-(void)goAddress:(UIButton *)sender{
    [self clearpickupview];

    self.svinfo.hidden=NO;
    [self setButton];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    NSString *msg = @"";
    
    AddressViewController *view =[storyboard
                                      instantiateViewControllerWithIdentifier:@"addressview"];
        
        if (sender.tag==0) {
            view.AddrType=@"出发地";
            msg=self.mOrder.StartLocation;
        }else
            if (sender.tag==1) {
                view.AddrType=@"目的地";
                msg=self.mOrder.Destination;
            }
        view.Address=msg;
        view.delegate = self;
       [self pressviewcontroller:view];
    
        
        
        
    
    
    
}
-(BOOL)didcellForRow:title
           indexpath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    BOOL result = YES;
    if ([title isEqualToString:@"航班号"]) {
        FlightViewController *view =[storyboard
                                     instantiateViewControllerWithIdentifier:@"flightView"];
        view.mflightno = self.mOrder.FlightNo;
        view.delegate=self;
         [self pressviewcontroller:view];
       
    }
    return result;
}
-(void)passFlightNoValue:(NSString *)value
{
    self.mOrder.FlightNo=value;
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
//    if ([self.mOrder.FlightNo isEqualToString:@""]
//        || self.mOrder.FlightNo ==nil) {
//        [self alertviewclick:@"航班号必须填写"];
//        return NO;
//        
//    }
    return YES;
}
@end
