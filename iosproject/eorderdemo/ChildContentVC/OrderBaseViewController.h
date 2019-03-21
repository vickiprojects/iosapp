//
//  OrderBaseViewController.h
//  Eorder
//
//  Created by ZhangLi on 16/12/19.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCTableView.h"
#import "UIConfigInfo.h"
#import "OrderInfo.h"
#import "TemplateInfo.h"
#import "UIParameter.h"
#import "RMMapper.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
#import "UserInfo.h"
#import "UIView+MJExtension.h"
#import "MJRefresh.h"
#import <Masonry/Masonry.h>
#import "PrintObject.h"
#import "UIView+Toast.h"
#import "MBProgressHUD.h"
#import "OrderLockViewController.h"
#import "FooterView.h"
#import "NearMapViewController.h"
#import "LanuchTableViewCell.h"
#import "MapTableViewCell.h"
#import "RebateTableViewCell.h"
#import "FinalTableViewCell.h"
#import "RankTableViewCell.h"
#import "SSCheckBoxView.h"
#import "DateTimePickerView.h"
#import "RemarkViewController.h"
#import "VehiclePickView.h"
#import "MMAlertView.h"
#import "UIViewPassValueDelegate.h"
#import "MapViewController.h"
#import "ZHPickView.h"
#import "AddressViewController.h"
#import "OrderEditViewController.h"
@interface OrderBaseViewController : UIViewController<UIViewPassValueDelegate,ZHPickViewDelegate,VehiclePickViewDelegate,BMKGeoCodeSearchDelegate,BMKSuggestionSearchDelegate>
@property(weak,nonatomic) IBOutlet UIView *svaddnew;
@property(weak,nonatomic) IBOutlet UIView *svcopy;
@property(weak,nonatomic) IBOutlet UIView *svsubmit;
@property(weak,nonatomic) IBOutlet UIView *svcancer;
@property(weak,nonatomic) IBOutlet UIView *svcancelwhite;
@property(weak,nonatomic) IBOutlet UIView *svinfo;
@property(weak,nonatomic) IBOutlet HCTableView *tableView;
@property(weak,nonatomic) IBOutlet UIView *svbtn;
@property(weak,nonatomic) IBOutlet UIView *svstatus;
@property(weak,nonatomic) IBOutlet UILabel *lb_statuskey;
@property(weak,nonatomic) IBOutlet UILabel *lb_status;
@property(weak,nonatomic) IBOutlet UILabel *lb_title;
@property int mOrderType;
@property bool mIsEdit;
@property bool mIsOrderLock;
@property bool mIsHome;
@property (strong, nonatomic) AppDelegate *myAppDelegate;
@property (strong, nonatomic) NSMutableArray *tvtitles;
@property (strong, nonatomic) NSMutableArray *templates;
@property (strong, nonatomic) NSMutableArray *ranks;
@property (strong, nonatomic) UIConfigInfo *mUIConfig;
@property (strong, nonatomic) OrderInfo *mOrder;
@property  (nonatomic, strong) UserInfo *mUser;
@property  (nonatomic, strong) NSString *mServerUrl;
@property  (nonatomic, strong) NSString *mDriverServerUrl;
@property  (nonatomic, strong) NSString *mcarCount;

@property (nonatomic,retain) DateTimePickerView *datePicker1;
@property(nonatomic,strong)ZHPickView *zhpickview;
-(void)selectDate:(NSString *)result;


@property (strong, nonatomic) OrderLockViewController* lockview;
@property (strong, nonatomic) OrderEditViewController* editview;
@property (strong, nonatomic) OrderInfo* moldorder;
@property (nonatomic, strong) BMKGeoCodeSearch *geoCode;        // 地理编码

@property  BOOL misRouteSearch;
-(TemplateInfo*)GetTemplateInfoByOrder;
-(void)pressviewcontroller:(UIViewController*)nview;
@property (nonatomic, strong)NSTimer*nsTime;

 @property  (nonatomic, strong) UILabel* lblcarcount;
/*
 设置 新增 下 的订单的默认值
 */
-(void)setCleanOrder;
/*
 页面逻辑设置
 */
-(void) setOrderLogic;
/*
 table内容显示配置
 */
-(void)setChildTableviewbyTemplatesShow;
/*
 table内容显示配置
 */
-(void)setChildMapShow;
/*
 设置每行的高度
 */
-(CGFloat)setHeightbyrowtitle:(NSString *)title;
/*
 设置定制行
 */
-(UITableViewCell *)setcellForRow:title cell:(UITableViewCell * )cell
           indexpath:(NSIndexPath *)indexPath
                        tableview:(UITableView *)tableView;
/*
 选择定制行
 */
-(BOOL)didcellForRow:title
           indexpath:(NSIndexPath *)indexPath;

/*
 计算价格
 */
-(void)CalePrice;
-(void)setButton;
/*
 子页设置订单
 */
-(void)childSetOrder;
/*
 子页提交前检查逻辑
 */
-(BOOL)checkOrder;
-(void)alertviewclick:(NSString *)msg;
-(void) setOrderDefault;
-(void)clearpickupview;
-(void) GetNearCarCount;
-(void) PostGetNearCarCount;
-(void)stopnearnstime;
-(void)restartnearnstime;


@end
