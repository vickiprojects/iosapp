//
//  QCListViewController.h
//  QCSliderTableView
//
//  Created by “ 邵鹏 on 14-4-16.
//  Copyright (c) 2014年 Scasy. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Article.h"
@interface QCListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    //UITableView *_tableViewList;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic,strong)NSString *catid;
- (void)viewDidCurrentView;
@property (nonatomic, strong) IBOutlet UITableViewCell *customCell;
@end

