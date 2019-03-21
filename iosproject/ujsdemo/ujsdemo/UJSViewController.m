//
//  UJSViewController.m
//  UJSIOS
//


#import "UJSViewController.h"
#import "QCListViewController.h"
#import "MKNetworkEngine.h"
#import "MKNetworkOperation.h"
#import "MBProgressHUD.h"
@interface UJSViewController ()
{
    NSMutableArray *categoriesInfo;
    NSMutableArray *cateidinfo;
    NSMutableDictionary *vclist;
}
@end

@implementation UJSViewController

- (IBAction)showMenu
{
    [self.frostedViewController presentMenuViewController];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.titletext==nil) {
        self.titletext = @"新闻资讯";
    }
    self.navigationItem.title = self.titletext;

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
   
    self.slideSwitchView.tabItemNormalColor = [QCSlideSwitchView colorFromHexRGB:@"868686"];
    self.slideSwitchView.tabItemSelectedColor = [QCSlideSwitchView colorFromHexRGB:@"006d5a"];
    self.slideSwitchView.shadowImage = [[UIImage imageNamed:@"green_line_and_shadow.png"]
                                        stretchableImageWithLeftCapWidth:60.0f topCapHeight:0.0f];
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading...";

    MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:@"mobile.ujs.edu.cn"
                                                     ];
    [engine useCache];
    MKNetworkOperation *op =  [engine operationWithPath:@"index.php/api/news/index" params:nil httpMethod:@"GET"];
    
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSDictionary *categoriesDic =[operation responseJSON];
        vclist = [[NSMutableDictionary alloc]init];
        NSArray *catlist = [categoriesDic objectForKey:@"CATEGORIES"];
        
        categoriesInfo = [[NSMutableArray alloc]init];
        cateidinfo= [[NSMutableArray alloc]init];
        for(int i=0;i<catlist.count;i++)
        {
            NSDictionary *cate =[catlist objectAtIndex:i];
          
            NSString *name =[cate objectForKey:@"NAME" ];
            [categoriesInfo addObject:name];
            NSString *uid =[cate objectForKey:@"UID" ];
            [cateidinfo addObject:uid];
            
            QCListViewController *vc =[self.storyboard instantiateViewControllerWithIdentifier:@"newslistviewcontroller"];
            vc.title = name;
            vc.catid = uid;
            [vclist setValue:vc forKey:uid];
            
        }
        UIButton *rightSideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [rightSideButton setImage:[UIImage imageNamed:@"icon_rightarrow.png"] forState:UIControlStateNormal];
        [rightSideButton setImage:[UIImage imageNamed:@"icon_rightarrow.png"]  forState:UIControlStateHighlighted];
        rightSideButton.frame = CGRectMake(0, 0, 20.0f, 44.0f);
        rightSideButton.userInteractionEnabled = NO;
        self.slideSwitchView.rigthSideButton = rightSideButton;
        
        [self.slideSwitchView buildUI];

          [MBProgressHUD hideHUDForView:self.view animated:YES];
        
      //  DLog(@"%@", vclist);
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
          [MBProgressHUD hideHUDForView:self.view animated:YES];
        DLog(@"%@", [error localizedDescription]);
    }];
    [engine enqueueOperation:op];
    
    
    
    

}
#pragma mark - 滑动tab视图代理方法


- (NSUInteger)numberOfTab:(QCSlideSwitchView *)view
{
    // you can set the best you can do it ;
    return vclist.count;
}

- (UIViewController *)slideSwitchView:(QCSlideSwitchView *)view viewOfTab:(NSUInteger)number
{
    if (number < cateidinfo.count) {
        return (QCListViewController*)[vclist objectForKey:[cateidinfo objectAtIndex:number]];
    
    } else {
        return nil;
    }
}



- (void)slideSwitchView:(QCSlideSwitchView *)view didselectTab:(NSUInteger)number
{
    QCListViewController *vc = nil;
    if (number < cateidinfo.count) {
        vc= [vclist objectForKey:[cateidinfo objectAtIndex:number]];
        
    }
    [vc viewDidCurrentView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
