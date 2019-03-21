//
//  Point2PointViewController.h
//  Eorder
//
//  Created by ZhangLi on 16/12/20.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderBaseViewController.h"
@interface Point2PointViewController : OrderBaseViewController<BMKMapViewDelegate,BMKRouteSearchDelegate,BMKSuggestionSearchDelegate>

@end
