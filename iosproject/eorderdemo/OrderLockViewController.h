//
//  OrderLockViewController.h
//  Eorder
//
//  Created by ZhangLi on 16/11/3.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewReloadValueDelegate.h"
#import "OrderInfo.h"
@interface OrderLockViewController : UIViewController<UIViewReloadValueDelegate>
@property(strong,nonatomic)IBOutlet UILabel *lb_id;
@property(strong,nonatomic)IBOutlet UILabel *lb_ordertype;
@property(strong,nonatomic)IBOutlet UIView *containerView;
@property(strong,nonatomic)IBOutlet UIView *viewcontenter;
@property(strong,nonatomic)OrderInfo* morderinfo;
@property(strong,nonatomic)NSString* mtypedetail;
@property int mtype;
@property int morderID;
@property BOOL miscacel;
- (void)gotoEditOrderView;
- (void)gotoMain;
- (void)alertMsg;
@property(nonatomic, retain) NSObject<UIViewReloadValueDelegate> * delegate;
@end
