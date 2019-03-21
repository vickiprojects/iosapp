//
//  QCListViewController.m
//  QCSliderTableView
//


#import "QCListViewController.h"
#import "MJRefresh.h"
#import "UJSAppDelegate.h"
#import "MJExtension.h"
#import "NewslistTableViewCell.h"
#import "WebViewController.h"
#import "UJSViewController.h"
#import "RootViewController.h"


NSString *const MJTableViewCellIdentifier = @"NewslistTableViewCellIdentifier";

@interface QCListViewController ()
{
    MKNetworkEngine   *engine ;
    //NSMutableArray *fakeData;
    }
/**
 *  存放假数据
 */
@property (retain, nonatomic) NSMutableArray *fakeData;
@property ( nonatomic,assign) int mpage;
@property ( nonatomic,assign) int first;
@end
/**
 *  随机数据
 */
//#define MJRandomData [NSString stringWithFormat:@"随机数据---%d", arc4random_uniform(1000000)]
@implementation QCListViewController
@synthesize catid;

@synthesize customCell;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - 初始化
/**
 *  数据的懒加载
 */
- (NSMutableArray *)fakeData
{
    if (!_fakeData) {
        self.fakeData = [NSMutableArray array];
    
       
    }
    return _fakeData;
}
- (int )mpage
{
 
    return _mpage;
}
- (int )first
{
    
    return _first;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    //NSLog(@"viewDidLoad title = %@",self.title);
    
     UJSAppDelegate *delegate=(UJSAppDelegate*)[[UIApplication sharedApplication]delegate];
    engine = delegate.networkengin;
    [engine useCache];
    _mpage=1;
    _first = 1;
    // 1.注册cell
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MJTableViewCellIdentifier];
    
    // 2.集成刷新控件
    [self setupRefresh];
    
    
}
/**
 *  集成刷新控件
 */
- (void)setupRefresh
{
    // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
    [self.tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
#warning 自动刷新(一进入程序就下拉刷新)
    [self.tableView headerBeginRefreshing];
    
    // 2.上拉加载更多(进入刷新状态就会调用self的footerRereshing)
    [self.tableView addFooterWithTarget:self action:@selector(footerRereshing)];
}
#pragma mark 开始进入刷新状态
- (void)headerRereshing
{
    // 1.添加数据

    
    NSMutableArray *tmplist =[NSMutableArray array];
   // int index= self.fakeData.count;
  //  DLog(@"刷新前个数－－－－%i", index);
     NSString *url =[NSString stringWithFormat:@"index.php/api/news/listview/%@/%d",catid,1];
   
    NSString *httpMethod;
    if (self.first==1) {
        httpMethod=@"GET";
        self.first=2;
    }
    else
    {
        httpMethod=@"POST";
    }
    MKNetworkOperation *op =  [engine operationWithPath:url params:nil httpMethod:httpMethod];
    if (tmplist.count>0) {
        [tmplist removeAllObjects];
        
    }
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSDictionary *newslistDic =[operation responseJSON];
       
        
         NSArray *newslist = [newslistDic objectForKey:@"LIST"];
        
        for(int i=0;i<newslist.count;i++)
        {
             NSDictionary *dict =[newslist objectAtIndex:i];
            Article *art = [Article objectWithKeyValues:dict];
            
         
            
            int index= tmplist.count;
         

             [tmplist insertObject:art atIndex:index];
         
        }
        
        self.fakeData = tmplist;
       // DLog(@"%@", newslist);
      //  DLog(@"%@-----%i",catid, newslist.count);
        
        
        // 2.2秒后刷新表格UI
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 刷新表格
            
            
            
            [self.tableView reloadData];
            
            // (最好在刷新表格后调用)调用endRefreshing可以结束刷新状态
            [self.tableView headerEndRefreshing];
        });
//DLog(@"%@-----刷新后个数－－－%i",catid, self.fakeData.count);
        
        
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        
        DLog(@"%@", [error localizedDescription]);
    }];
    [engine enqueueOperation:op];
    
    

    
    }

- (void)footerRereshing
{
    
  
    
    // 1.添加假数据
       _mpage++;
    NSString *url =[NSString stringWithFormat:@"index.php/api/news/listview/%@/%d",catid,_mpage];
    
    MKNetworkOperation *op =  [engine operationWithPath:url params:nil httpMethod:@"GET"];
    
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        NSDictionary *newslistDic =[operation responseJSON];
        
        
        NSArray *newslist = [newslistDic objectForKey:@"LIST"];
        
        for(int i=0;i<newslist.count;i++)
        {
            NSDictionary *dict =[newslist objectAtIndex:i];
            Article *art = [Article objectWithKeyValues:dict];
            
            int index= self.fakeData.count;
            [self.fakeData insertObject:art atIndex:index];

            
        }
        
        
      //  DLog(@"%@", newslist);
      //  DLog(@"%@-----%i",catid, newslist.count);
        
        
        // 2.2秒后刷新表格UI
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 刷新表格
            [self.tableView reloadData];
            
            // (最好在刷新表格后调用)调用endRefreshing可以结束刷新状态
            [self.tableView footerEndRefreshing];
            
          //  [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.fakeData.count-10 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        });
        
        
        
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        
        DLog(@"%@", [error localizedDescription]);
    }];
    [engine enqueueOperation:op];
    

    
    
    
}

- (void)viewDidCurrentView
{
    NSLog(@"加载为当前视图 = %@",self.title);
}


#pragma mark - 表格视图数据源代理方法



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"当前个数 = %i",self.fakeData.count);

     return self.fakeData.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     int row = indexPath.row;
  // NSLog(@"当前 = %i",row);
    NSArray *nibViews=[[NSBundle mainBundle] loadNibNamed:@"CustomCellNib" owner:self options:nil];
    NewslistTableViewCell  *cell  = [nibViews objectAtIndex:0];
      UILabel *textTarget;
   
  

    
    if (row<self.fakeData.count) {
        
        
        
        Article *art =(Article *)self.fakeData[row];
        
        
        textTarget = (UILabel *)[cell viewWithTag:1]; //name
        textTarget.text =art.TITLE;
                
        textTarget = (UILabel *)[cell viewWithTag:2]; //name
        textTarget.text =art.TIME;
        textTarget = (UILabel *)[cell viewWithTag:3]; //name
        textTarget.text =art.DESCRIPTION;
       
        
    }
    
    
       return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Article *art =(Article *)self.fakeData[indexPath.row];
    
    WebViewController *webview = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    webview.artid = art.ARTICLEID;
    webview.webviewaction = Action_News;
 // [self presentViewController:webview animated:YES completion:nil];
   
  
     // [self.navigationController pushViewController:webview animated:YES];
      UJSAppDelegate *delegate=(UJSAppDelegate*)[[UIApplication sharedApplication]delegate];
    UIViewController *cc =delegate.window.rootViewController;
    webview.forwardview = cc;
    delegate.window.rootViewController =webview;
  
    [delegate.window makeKeyAndVisible];
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
