//
//  Point2PointViewController.m
//  Eorder
//
//  Created by ZhangLi on 16/12/20.
//  Copyright © 2016年 ZhangLi. All rights reserved.
//

#import "Point2PointViewController.h"
#import "P2PTableViewCell.h"
#import "SearchViewController.h"
#import "RouteAnnotation.h"
@interface Point2PointViewController ()
{
    BMKPointAnnotation* startPointAnnotation;
    BMKPointAnnotation* endPointAnnotation;
    BMKPointAnnotation* mPointAnnotation;
    BOOL mIsStartLoction;
    BOOL mfirstsearch;
     BOOL misRouteSearch;
    BOOL mRouteSearchSuccess;
    BOOL misCheckStartPoint;
    BOOL misCheckEndPoint;
    BOOL misLocation;
    BOOL misfirstedit;
    BMKMapView *mapview;
    UIButton* mapcheckbutton;
    NSNumber *mdistance;
    
}

@property(nonatomic,strong)BMKRouteSearch* routeSearch;
@property(nonatomic,strong)BMKSuggestionSearch* suggestionSearch;
@property (nonatomic, assign) CGFloat longitude;  // 经度
@property (nonatomic, assign) CGFloat latitude; // 纬度
@end

@implementation Point2PointViewController
-(void)setCleanOrder
{
    [super setCleanOrder];
    self.mOrder.OrderType=3;
    [self cleanOrder];
    
}
-(void)cleanOrder{
    startPointAnnotation = nil;
    endPointAnnotation = nil;
    mPointAnnotation = [[BMKPointAnnotation alloc]init];
    misCheckStartPoint=misCheckEndPoint= NO;
    mRouteSearchSuccess = NO;
    misRouteSearch= NO;
    mfirstsearch=NO;
    mIsStartLoction=NO;
    NSString* companyName=@"";
    if(self.mUser!=nil)
    {
        if (self.mUser.DefaultDestination ==nil || [self.mUser.DefaultDestination isEqual:[NSNull null]] || [self.mUser.DefaultDestination isEqualToString:@""]) {
            companyName=@"";
            mIsStartLoction=YES;
        }else{
            companyName = self.mUser.DefaultDestination;
            mfirstsearch=YES;
            
        }
    }
    
    self.mOrder.StartLocation=companyName;
    self.mOrder.Destination=@"";
    self.mOrder.KiloMeters = [NSNumber numberWithInt:50];
}
-(void)setOrderLogic
{
    [super setOrderLogic];
    startPointAnnotation = [[BMKPointAnnotation alloc]init];
    startPointAnnotation.title = self.mOrder.StartLocation;
    
    if (self.mOrder.Start_latitude>0 && self.mOrder.Start_longitude>0) {
        CLLocationCoordinate2D coor;
        coor.latitude =self.mOrder.Start_latitude ;
        coor.longitude = self.mOrder.Start_longitude ;
        startPointAnnotation.coordinate = coor;
        
    }
    
    endPointAnnotation =[[BMKPointAnnotation alloc]init];
    endPointAnnotation.title = self.mOrder.Destination;
    if (self.mOrder.End_latitude>0 && self.mOrder.End_longitude>0) {
        CLLocationCoordinate2D coor;
        coor.latitude =self.mOrder.End_latitude ;
        coor.longitude = self.mOrder.End_longitude ;
        endPointAnnotation.coordinate = coor;
    }
    misCheckEndPoint = YES;
    misCheckStartPoint=YES;
    misRouteSearch= YES;
    misfirstedit=YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
 table内容显示配置
 */
-(void)setChildTableviewbyTemplatesShow{
    [super setChildTableviewbyTemplatesShow];
    NSArray *title= @[@"地图地址"];
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
-(CGFloat)setHeightbyrowtitle:(NSString *)title
{
    if ([title isEqualToString:@"地图地址"]) {
        return 350;
    }
    return 44;
}
-(UITableViewCell *)setcellForRow:title cell:(UITableViewCell * )cell
                        indexpath:(NSIndexPath *)indexPath
                        tableview:(UITableView *)tableView{
    if ([title isEqualToString:@"地图地址"])
    {
        P2PTableViewCell* mcell = [tableView dequeueReusableCellWithIdentifier:@"mapaddr"];
        if (!mcell)
        {
            [tableView registerNib:[UINib nibWithNibName:@"P2PTableViewCell" bundle:nil] forCellReuseIdentifier:@"mapaddr"];
            mcell = [tableView dequeueReusableCellWithIdentifier:@"mapaddr"];
            
            
        }
        CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.myAppDelegate.latitude,self.myAppDelegate.longitude);
        if (mPointAnnotation!=nil) {
            coords = mPointAnnotation.coordinate;
        }
        BMKCoordinateRegion region ;//表示范围的结构体
        region.center=coords;
        region.span.latitudeDelta = 0.1;//经度范围（设置为0.1表示显示范围为0.2的纬度范围）
        region.span.longitudeDelta = 0.1;//纬度范围
        mcell.mapView.showMapScaleBar = YES;//比例尺
        [mcell.mapView setRegion:region animated:YES];
        mcell.mapView.scrollEnabled = YES;
        mcell.mapView.delegate=self;
        mcell.mapView.zoomEnabled = YES; // 多点缩放手势
        
       // mcell.mapView.zoomLevel = 15;//地图显示比例
        NSLog(@"zoomLevel-%f",mcell.mapView.zoomLevel);
        
        [mcell.turnleft2right addTarget:self action:@selector(turnleft2rightButtonClicked2:) forControlEvents:UIControlEventTouchUpInside];
        mcell.left.tag=101;
        mcell.right.tag=102;
        [mcell.left addTarget:self action:@selector(Actiondo:) forControlEvents:UIControlEventTouchUpInside];
        [mcell.right addTarget:self action:@selector(Actiondo:) forControlEvents:UIControlEventTouchUpInside];
        
        
        mapview =mcell.mapView;
        
        [self setMapCheckButton];
        if (self.mOrder !=nil) {
            NSString * start =self.mOrder.StartLocation;
            
            if (start.length>10) {
                start = [[start substringToIndex:10] stringByAppendingString:@"..."];
                
            }
            [mcell.left setTitle:start forState:UIControlStateNormal];
            NSString * end =self.mOrder.Destination;
            if (end.length>10) {
                end = [[end substringToIndex:10] stringByAppendingString:@"..."];
                
            }
            [mcell.right setTitle:end forState:UIControlStateNormal];
        }
        
        
        mapview.isSelectedAnnotationViewFront = YES;
      
        if (misCheckEndPoint && misCheckStartPoint && misRouteSearch) {
             [self onClickDriveSearch];
        }else{
             misRouteSearch=NO;
            if ([self.mOrder.StartLocation isEqualToString:@""]) {
                [self geoloction];
            }else if(mfirstsearch){
                
                [self onSuggestSearch:self.mOrder.StartLocation ];
                
            }
        }
        
        return mcell;

       
       
    }
      NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    if ([title isEqualToString:@"大约里程数(公里)"]) {
        if (misRouteSearch && mRouteSearchSuccess && !misfirstedit ) {
            self.mOrder.KiloMeters = mdistance;
            if (self.mOrder.PriceType>0) {
                [self CalePrice];
            }
        }
        
        cell.detailTextLabel.text=[numberFormatter stringFromNumber:self.mOrder.KiloMeters];
    }
    return cell;
}
-(BOOL)didcellForRow:title
           indexpath:(NSIndexPath *)indexPath{
    BOOL result = YES;
    if ([title isEqualToString:@"大约里程数(公里)"]) {
        if (mRouteSearchSuccess) {
            result=NO;
        }
    }
    return result;
}


- (void)setMapCheckButton {
    NSString*msg = @"重置起始点";
    int tag = 200;
    if(!misCheckStartPoint)
    {
        msg = @"确认出发地";
        tag=201;
    }else if(misCheckStartPoint   && !misCheckEndPoint)
    {
        msg = @"确认目的地";
        tag=202;
    }
    
    ///地图预留边界，默认：UIEdgeInsetsZero。设置后，会根据mapPadding调整logo、比例尺、指南针的位置，以及targetScreenPt(BMKMapStatus.targetScreenPt)
    mapview.mapPadding = UIEdgeInsetsMake(0, 0, 28, 0);
    for (UIView *view in  mapview.subviews) {
        if (view.tag >=200 && view.tag<=202) {
            [view removeFromSuperview];
        }
    }
    UIButton *label = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //给定button在view上的位置
    label.frame = CGRectMake(2, 2, 120, 40);
    
    [label setTitle:msg forState:UIControlStateNormal];
    label.titleLabel.font = [UIFont systemFontOfSize:15];
    
    label.backgroundColor = [UIColor whiteColor];
    
    label.tag=tag;
    mapcheckbutton = label;
    [mapcheckbutton addTarget:self
                       action:@selector(CheckButtonDo:)
             forControlEvents:UIControlEventTouchUpInside
     ];
    [mapview  addSubview:label];
    [mapview bringSubviewToFront:label];
}
-(void)Actiondo:(UIButton*)sender{
    [self clearpickupview];
    mRouteSearchSuccess = NO;
    self.svinfo.hidden=NO;
    [self setButton];
    bool iscanclick=YES;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    
    
    SearchViewController *view =[storyboard
                                 instantiateViewControllerWithIdentifier:@"searchView"];
    
    if (sender.tag==101) {
        view.mtitle=@"出发地";
        view.mtype=0;
        mIsStartLoction=YES;
    }else if (sender.tag==102) {
            if (!misCheckStartPoint) {
                iscanclick=NO;
            }
            view.mtitle=@"目的地";
            view.mtype=1;
            mIsStartLoction=NO;
        }

    
    
    view.delegate = self;
    if (iscanclick) {
        [self presentViewController:view
                       animated:YES
                     completion:^(void){}];
    
    
    }
}
- (void)turnleft2rightButtonClicked2:(UIButton *)sender{
    [self clearpickupview];
   mRouteSearchSuccess = NO;
    
    BMKPointAnnotation*  spoint =[startPointAnnotation copy];
    BMKPointAnnotation*  epoint =[endPointAnnotation copy];
    startPointAnnotation = epoint;
    endPointAnnotation = spoint;
    if (endPointAnnotation==nil) {
        endPointAnnotation = mPointAnnotation;
    }
    if (startPointAnnotation==nil) {
        startPointAnnotation = mPointAnnotation;
    }
    NSString *left = self.mOrder.StartLocation;
    NSString *right = self.mOrder.Destination;
    self.mOrder.StartLocation=right;
    self.mOrder.Destination=left;
    self.svinfo.hidden=NO;
    [self setButton];
    [self.tableView reloadData];
    
}
-(void)CheckButtonDo:(UIButton*)sender{
    [self clearpickupview];

    NSLog(@"CheckButtonDo: %ld",sender.tag);
    long tag =sender.tag;
    switch (tag) {
        case 200:
        {
             mRouteSearchSuccess = NO;
            [self cleanOrder];

            
        }
            break;
        case 201:
        {
             mRouteSearchSuccess = NO;
            misCheckStartPoint=YES;
            mIsStartLoction=NO;
            startPointAnnotation = [[BMKPointAnnotation alloc]init];
            startPointAnnotation.coordinate= mPointAnnotation.coordinate;
            startPointAnnotation.title= mPointAnnotation.title;
            self.mOrder.StartLocation = mPointAnnotation.title;
            self.mOrder.Destination = mPointAnnotation.title;
            sender.tag =202;
            [sender setTitle:@"确认目的地" forState:UIControlStateNormal];
        }
            break;
        case 202:
        {
             misRouteSearch=YES;
            misCheckEndPoint=YES;
            mIsStartLoction=NO;
            endPointAnnotation = [[BMKPointAnnotation alloc]init];
            endPointAnnotation.coordinate= mPointAnnotation.coordinate;
            endPointAnnotation.title= mPointAnnotation.title;
            self.mOrder.Destination = mPointAnnotation.title;
            sender.tag =200;
            [sender setTitle:@"重置起始点" forState:UIControlStateNormal];
            //[self onClickDriveSearch];
        }
            break;
        default:
            break;
    }
    [self.tableView reloadData];
    
}
//根据polyline设置地图范围
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    [mapview setVisibleMapRect:rect];
    mapview.zoomLevel = mapview.zoomLevel - 0.3;
}

//反编译地理位置
-(void)geoloction
{
    misLocation=YES;
    self.longitude =self.myAppDelegate.longitude;
    self.latitude =self.myAppDelegate.latitude ;
    // 地图定位显示
    BMKCoordinateRegion region;
    region.center.latitude  = self.latitude ;
    region.center.longitude = self.longitude ;
    region.span.latitudeDelta  = 0;
    region.span.longitudeDelta = 0;
    [UIView animateWithDuration:1 animations:^{
        mapview.region = region;
    }];
     CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.latitude,self.longitude);
    [mapview setCenterCoordinate:coords animated:YES];
   // [mapview updateLocationData:userLocation];
    
    //     }
    [self outputAdd];
}
//#pragma mark 获取地理位置按钮事件
- (void)outputAdd
{
    misfirstedit=NO;
    // 初始化反地址编码选项（数据模型）
    BMKReverseGeoCodeOption *option = [[BMKReverseGeoCodeOption alloc] init];
    // 将数据传到反地址编码模型
    option.reverseGeoPoint = CLLocationCoordinate2DMake(self.latitude, self.longitude);
    NSLog(@"%f - %f", option.reverseGeoPoint.latitude, option.reverseGeoPoint.longitude);
    // 调用反地址编码方法，让其在代理方法中输出
    [self.geoCode reverseGeoCode:option];
}

- (BMKRouteSearch *)routeSearch
{
    if (!_routeSearch)
    {
        _routeSearch = [[BMKRouteSearch alloc] init];
        _routeSearch.delegate = self;
    }
    return _routeSearch;
}
- (BMKSuggestionSearch *)suggestionSearch
{
    if (!_suggestionSearch)
    {
        _suggestionSearch = [[BMKSuggestionSearch alloc] init];
        _suggestionSearch.delegate = self;
    }
    return _suggestionSearch;
}



#pragma mark 代理方法返回反地理编码结果
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    
    if (result) {
             NSLog(@"位置结果是：%@ - %@", result.address, result.addressDetail.city);
       [self clearmapview];
        
        if (misLocation) {
            // 一开始显示的(大头针)
            mPointAnnotation = [[BMKPointAnnotation alloc]init];
            CLLocationCoordinate2D coor;
            coor.latitude =self.latitude ;
            coor.longitude =  self.longitude ;
            mPointAnnotation.coordinate = coor;
            mPointAnnotation.title =  result.address;
            [mapview addAnnotation:mPointAnnotation];
            //[mapview selectAnnotation:startPointAnnotation animated:YES];//标题和子标题自动显示
           
            self.mOrder.StartLocation = mPointAnnotation.title;
            self.mOrder.Start_latitude = coor.latitude ;
            self.mOrder.Start_longitude = coor.longitude;
            misLocation=NO;
            [self.tableView reloadData];
        }else{
            CLLocationCoordinate2D coor=mPointAnnotation.coordinate ;
            
            if (mIsStartLoction) {
                self.mOrder.StartLocation= result.address;
                self.mOrder.Start_latitude = self.latitude;
                self.mOrder.Start_longitude = self.longitude;
                
                
            }else{
                self.mOrder.Destination = result.address;
                self.mOrder.End_latitude = self.latitude;
                self.mOrder.End_longitude = self.longitude;
                
            }
            [self.tableView reloadData];
        
            
            NSMutableArray *annotations = [NSMutableArray array];
            
            BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
            item.coordinate = coor;
            item.title = result.address;
            
            [annotations addObject:item];
            
            mPointAnnotation = item;
            [mapview addAnnotations:annotations];
            [mapview showAnnotations:annotations animated:YES];
            
                    
        }
        
    }else{
        NSLog(@"%@", @"找不到相对应的位置");
        [self.view makeToast:@"抱歉，找不到相对应的位置"];
        
    }
    
}
#pragma mark implement BMKMapViewDelegate
- (BMKOverlayView*)mapView:(BMKMapView *)map viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor alloc] initWithRed:0 green:1 blue:1 alpha:1];
        polylineView.strokeColor = [[UIColor alloc] initWithRed:0 green:0 blue:1 alpha:0.7];
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}
/**
 *根据anntation生成对应的View
 *@param mapView 地图View
 *@param annotation 指定的标注
 *@return 生成的标注View
 */
- (BMKAnnotationView *)mapView:(BMKMapView *)view viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return [(RouteAnnotation*)annotation getRouteAnnotationView:view];
    }
    
    // 生成重用标示identifier
    NSString *AnnotationViewID = @"xidanMark";
    
    // 检查是否有重用的缓存
    BMKAnnotationView* annotationView = [view dequeueReusableAnnotationViewWithIdentifier:AnnotationViewID];
    
    // 缓存没有命中，自己构造一个，一般首次添加annotation代码会运行到此处
    if (annotationView == nil) {
        annotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID];
        
    }
    // 设置重天上掉下的效果(annotation)
    ((BMKPinAnnotationView*)annotationView).animatesDrop = YES;
    
    if (mIsStartLoction) {
        ((BMKPinAnnotationView*)annotationView).pinColor =BMKPinAnnotationColorGreen;
        //  if (startPointAnnotation!=nil) {
        annotationView.tag=10;//起点
        // }
    }
    else{
        ((BMKPinAnnotationView*)annotationView).pinColor = BMKPinAnnotationColorRed;
        //  if (endPointAnnotation!=nil) {
        annotationView.tag=11;//终点
        // }
        
    }
    //  [self setMapCheckButton:@"起点"];
    // 设置位置
    annotationView.centerOffset = CGPointMake(0, -(annotationView.frame.size.height * 0.5));
    annotationView.annotation = annotation;
    
    //annotationView.tag=101;
    // 单击弹出泡泡，弹出泡泡前提annotation必须实现title属性
    annotationView.canShowCallout = YES;
    // 设置是否可以拖拽
    annotationView.draggable = YES;
    
    return annotationView;
}
- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view
{
    [self clearpickupview];

    [mapView bringSubviewToFront:view];
    [mapView setNeedsDisplay];
    if (view.tag>=10 && view.tag<=11) {
        // 当选中标注的之后，设置开始拖动状态
        view.dragState = BMKAnnotationViewDragStateStarting;
    }
    
}

- (void)mapView:(BMKMapView *)mapView  didDeselectAnnotationView:(BMKAnnotationView *)annotationView
{
     misfirstedit=NO;
    if (annotationView.tag>=10 && annotationView.tag<=11 && annotationView.dragState == BMKAnnotationViewDragStateStarting) {
        
        // 取消选中标注后，停止拖动状态
        annotationView.dragState = BMKAnnotationViewDragStateEnding;
        // 设置转换的坐标会有一些偏差，具体可以再调节坐标的 (x, y) 值
        CGPoint dropPoint = CGPointMake(annotationView.center.x, CGRectGetMaxY(annotationView.frame));
        CLLocationCoordinate2D newCoordinate = [mapView convertPoint:dropPoint toCoordinateFromView:annotationView.superview];
        if (mPointAnnotation==nil) {
            mPointAnnotation = [[BMKPointAnnotation alloc]init];
        }
        mPointAnnotation.coordinate = newCoordinate;
        BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
        reverseGeocodeSearchOption.reverseGeoPoint = newCoordinate;
        BOOL flag = [self.geoCode reverseGeoCode:reverseGeocodeSearchOption];
        if(flag)
        {
            NSLog(@"反geo检索发送成功");
        }
        else
        {
            NSLog(@"反geo检索发送失败");
        }
        
    }
}
- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    NSLog(@"didAddAnnotationViews");
}

#pragma mark 路径规划
-(void)onClickDriveSearch
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText =@"路径规划中.....";
    BMKPlanNode* start = [[BMKPlanNode alloc]init];
    start.name = startPointAnnotation.title;
    start.pt = startPointAnnotation.coordinate;
    start.cityName = @"上海市";
    BMKPlanNode* end = [[BMKPlanNode alloc]init];
    end.name = endPointAnnotation.title;
    end.cityName = @"上海市";
    end.pt = endPointAnnotation.coordinate;
    BMKDrivingRoutePlanOption *drivingRouteSearchOption = [[BMKDrivingRoutePlanOption alloc]init];
    drivingRouteSearchOption.from = start;
    drivingRouteSearchOption.to = end;
    drivingRouteSearchOption.drivingRequestTrafficType = BMK_DRIVING_REQUEST_TRAFFICE_TYPE_NONE;//不获取路况信息
    BOOL flag = [self.routeSearch drivingSearch:drivingRouteSearchOption];
    if(flag)
    {
        misRouteSearch=NO;
       // misRouteSearch=YES;
        NSLog(@"car检索发送成功");
    }
    else
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSLog(@"car检索发送失败");
    }
    
}
- (void)onGetDrivingRouteResult:(BMKRouteSearch*)searcher result:(BMKDrivingRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    
    for (UIView *view in  mapview.subviews) {
        if (view.tag ==111) {
            [view removeFromSuperview];
        }
    }
    NSArray* array = [NSArray arrayWithArray:mapview.annotations];
    [mapview removeAnnotations:array];
    array = [NSArray arrayWithArray:mapview.overlays];
    [mapview removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKDrivingRouteLine* plan = (BMKDrivingRouteLine*)[result.routes objectAtIndex:0];
        float distance = plan.distance/1000.f;
            mdistance =[NSNumber numberWithFloat:  ceilf(distance)];
        NSString *msg = [NSString stringWithFormat:@"  距离:%f千米",distance];
      
        [self setMapPadding:msg];
        // 计算路线方案中的路段数目
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKDrivingStep* transitStep = [plan.steps objectAtIndex:i];
            if(i==0){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.starting.location;
                item.title = @"起点";
                item.type = 0;
                [mapview addAnnotation:item]; // 添加起点标注
                
            }else if(i==size-1){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.terminal.location;
                item.title = @"终点";
                item.type = 1;
                [mapview addAnnotation:item]; // 添加起点标注
            }
            //添加annotation节点
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.entraceInstruction;
            item.degree = transitStep.direction * 30;
            item.type = 4;
            [mapview addAnnotation:item];
            
          //  NSLog(@"%@   %@    %@", transitStep.entraceInstruction, transitStep.exitInstruction, transitStep.instruction);
            
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        // 添加途经点
        if (plan.wayPoints) {
            for (BMKPlanNode* tempNode in plan.wayPoints) {
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item = [[RouteAnnotation alloc]init];
                item.coordinate = tempNode.pt;
                item.type = 5;
                item.title = tempNode.name;
                [mapview addAnnotation:item];
            }
        }
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKDrivingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [mapview addOverlay:polyLine]; // 添加路线overlay
        delete []temppoints;
        [self mapViewFitPolyLine:polyLine];
        
        mRouteSearchSuccess=YES;
       
      
        
       
        
    }else{
        mRouteSearchSuccess=NO;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.view makeToast:@"抱歉，路径规划未找到结果"];
    }
}
- (void)setMapPadding :(NSString*)msg{
    ///地图预留边界，默认：UIEdgeInsetsZero。设置后，会根据mapPadding调整logo、比例尺、指南针的位置，以及targetScreenPt(BMKMapStatus.targetScreenPt)
    mapview.mapPadding = UIEdgeInsetsMake(0, 0, 28, 0);
    for (UIView *view in  mapview.subviews) {
        if (view.tag ==111) {
            [view removeFromSuperview];
        }
    }
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, mapview.frame.size.height-30, self.view.frame.size.width, 28)];
    label.text = msg;
    label.font = [UIFont systemFontOfSize:13];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    label.alpha = 0.7;
    label.tag=111;
    [mapview  addSubview:label];
    [mapview bringSubviewToFront:label];
//    int row = 2;
//    for (int i=0;i<self.tvtitles.count;i++) {
//        NSString *str = self.tvtitles[i];
//        if ([str isEqualToString:@"大约里程数(公里)"]) {
//            row=i;
//            break;
//        }
//    }
//    self.mOrder.KiloMeters = mdistance;
//    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:row inSection:0];
//    
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark 建议检索
-(void)onSuggestSearch:(NSString *)key
{
     misfirstedit=NO;
    BMKSuggestionSearchOption* option = [[BMKSuggestionSearchOption alloc] init];
    option.cityname = @"上海";
    option.keyword  = key;
    BOOL flag = [self.suggestionSearch suggestionSearch:option];
    if(flag)
    {
        if (mfirstsearch) {
            mfirstsearch=NO;
        }
        NSLog(@"建议检索发送成功");
    }
    else
    {
        [self geoloction];
        NSLog(@"建议检索发送失败");
    }
    
    
}
//实现Delegate处理回调结果
- (void)onGetSuggestionResult:(BMKSuggestionSearch*)searcher result:(BMKSuggestionResult*)result errorCode:(BMKSearchErrorCode)error{
    
    if (error == BMK_SEARCH_NO_ERROR) {
       
        //在此处理正常结果
        for (UIView *view in  mapview.subviews) {
            if (view.tag ==111) {
                [view removeFromSuperview];
            }
        }
        // 清楚屏幕中所有的annotation
        NSArray* array = [NSArray arrayWithArray:mapview.annotations];
        [mapview removeAnnotations:array];
        array = [NSArray arrayWithArray:mapview.overlays];
        [mapview removeOverlays:array];
        NSLog(@"%@---%@-----%@=====%@", result.keyList, result.cityList, result.districtList, result.ptList);
        
        NSMutableArray *annotations = [NSMutableArray array];
        CLLocationCoordinate2D coor;
        for (int i = 0; i < result.ptList.count; i++) {
            NSValue *poi = [result.ptList objectAtIndex:i];
            
            [poi getValue:&coor];
            if (coor.latitude!=0 && coor.longitude!=0) {
                BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
                item.coordinate = coor;
                item.title = [result.keyList objectAtIndex:i];
                self.mOrder.StartLocation = item.title;
                self.mOrder.Start_latitude = item.coordinate.latitude;
                self.mOrder.Start_longitude = item.coordinate.longitude;
                mPointAnnotation = item;
                [annotations addObject:item];
                break;
            }
            
        }
        [mapview addAnnotations:annotations];
        [mapview showAnnotations:annotations animated:YES];
        BMKCoordinateRegion region ;//表示范围的结构体
        region.center = coor;//中心点
        region.span.latitudeDelta = 0.1;//经度范围（设置为0.1表示显示范围为0.2的纬度范围）
        region.span.longitudeDelta = 0.1;//纬度范围
        [mapview setRegion:region animated:YES];
        [self.tableView reloadData];
        
        
    }
    else {
        [self geoloction];
        [self.view makeToast:@"抱歉，建议检索未找到结果"];
        NSLog(@"抱歉，未找到结果");
    }
}


#pragma  mark 建议检索返回
-(void)passPointAnnotationValue:(NSString *)keyvalue longitude:(CGFloat)longitudevalue latitude:(CGFloat)latitudevalue type:(int)typevalue
{
     misfirstedit=NO;
    [self clearmapview];
    CLLocationCoordinate2D coor;
    coor.latitude =latitudevalue ;
    coor.longitude =  longitudevalue ;
    BMKPointAnnotation* item = [[BMKPointAnnotation alloc]init];
    item.coordinate = coor;
    item.title = keyvalue;
    
    mPointAnnotation = item;
    if (typevalue==0) {
        mIsStartLoction=YES;
        self.mOrder.StartLocation = keyvalue;
        startPointAnnotation = [mPointAnnotation copy];
        misCheckStartPoint=YES;
        
    }else{
        mIsStartLoction=NO;
        
        self.mOrder.Destination = keyvalue;
        endPointAnnotation = [mPointAnnotation copy];
         misCheckEndPoint=YES;
    }
    if (misCheckEndPoint && misCheckStartPoint) {
        misRouteSearch=YES;
    }
    //刷新表格
    [self.tableView reloadData];
  
    NSMutableArray *annotations = [NSMutableArray array];
    
 
    [annotations addObject:item];
    [mapview addAnnotations:annotations];
    [mapview showAnnotations:annotations animated:YES];

    
    
}
-(void)clearmapview{
    for (UIView *view in  mapview.subviews) {
        if (view.tag ==111) {
            [view removeFromSuperview];
        }
    }
    NSArray* array = [NSArray arrayWithArray:mapview.annotations];
    [mapview removeAnnotations:array];
    array = [NSArray arrayWithArray:mapview.overlays];
    [mapview removeOverlays:array];

}
-(void)childSetOrder
{
    if (startPointAnnotation !=nil ) {
        self.mOrder.Start_longitude = startPointAnnotation.coordinate.longitude;
        self.mOrder.Start_latitude = startPointAnnotation.coordinate.latitude;
        
    }
    if (endPointAnnotation !=nil )
    {
        self.mOrder.End_longitude = endPointAnnotation.coordinate.longitude;
        self.mOrder.End_latitude = endPointAnnotation.coordinate.latitude;

    }
}
/*
 子页提交前检查逻辑
 */
-(BOOL)checkOrder{
    [self childSetOrder];
    if ([self.mOrder.StartLocation isEqualToString:@""] )
    {
        [self alertviewclick:@"出发地不能为空！"];
        return NO;
    }
    if ([self.mOrder.Destination isEqualToString:@""] )
    {
        [self alertviewclick:@"目的地不能为空！"];
        return NO;
    }
   
    
    if (self.mOrder.Start_latitude==0 || self.mOrder.Start_longitude==0) {
        [self alertviewclick:@"请在地图确认出发地或者搜索出发地！"];
        return NO;
    }
    if (self.mOrder.End_longitude==0 || self.mOrder.End_latitude==0) {
        [self alertviewclick:@"请在地图确认目的地或者搜索目的地！"];
        return NO;
    }
//    if (!mRouteSearchSuccess) {
//        [self alertviewclick:@"请正确填写地址并规划路径！"];
//        return NO;
//        
//    }
    return  YES;
}
@end
