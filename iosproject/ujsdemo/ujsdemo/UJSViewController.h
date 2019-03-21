//
//  UJSViewController.h
//  UJSIOS
//
//  Created by ujsinfo on 14-6-6.
//  Copyright (c) 2014年 UJS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REFrostedViewController.h"
#import "BaseViewController.h"
#import "QCSlideSwitchView.h"
#import "QCListViewController.h"

@interface UJSViewController : BaseViewController<QCSlideSwitchViewDelegate>
{
    QCSlideSwitchView *_slideSwitchView;
   }

- (IBAction)showMenu;

@property (nonatomic, strong) IBOutlet QCSlideSwitchView *slideSwitchView;


@end
