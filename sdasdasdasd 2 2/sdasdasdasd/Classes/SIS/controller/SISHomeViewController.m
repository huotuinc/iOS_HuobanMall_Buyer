//
//  SISHomeViewController.m
//  HuoBanMallBuy
//
//  Created by HuoTu-Mac on 15/10/31.
//  Copyright © 2015年 HT. All rights reserved.
//

#import "SISHomeViewController.h"
#import <UIView+BlocksKit.h>
#import <UIBarButtonItem+BlocksKit.h>
#import "SISWebViewController.h"
#import "SISSettingController.h"
#import "SISShopViewController.h"
#import "UIImage+LHB.h"
#import "SISBaseModel.h"
#import <UIImageView+WebCache.h>
#import "UserLoginTool.h"
#import "NSDictionary+HuoBanMallSign.h"
#import "SISCategory.h"
#import "SISGoodModel.h"
#import "UITableView+CJ.h"
#import "SISGoodsCell.h"
#import "KxMenu.h"
#import <MJRefresh.h>
#import <SVProgressHUD.h>
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import "SISWebViewController.h"

@interface SISHomeViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UIView *slidingView;

//用户数据
@property (nonatomic, strong) SISBaseModel *model;

//识别是销售中还是已下架
@property (nonatomic, assign) NSInteger type;

/**
 *  列表
 */
@property (nonatomic, strong) NSMutableArray *goodsArray;

//页码
@property (nonatomic, strong) NSString *rpageno;

//用于保存model
@property (nonatomic, strong) SISGoodModel *good;

@property (nonatomic, strong) NSIndexPath *selectIndexPath;

@property (nonatomic, strong) NSNumber *sisouttotal;

@property (nonatomic, strong) NSNumber *sisuptotal;

@end

@implementation SISHomeViewController

static NSString *homeCellIdentify = @"homeCellIdentify";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    self.goodsArray = [NSMutableArray array];
    
    [self _initNavBar];
    
    [self _initHeadViewAndButton];
    
    [self _initImagesAndAction];
    
    [self _initSliding];
    
    NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * filename = [[array objectAtIndex:0] stringByAppendingPathComponent:SISUserInfo];
    self.model = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
    
}

- (void)_initTableView {
    [self.tableView removeSpaces];
    [self.tableView registerNib:[UINib nibWithNibName:@"SISGoodsCell" bundle:nil] forCellReuseIdentifier:homeCellIdentify];
    
    [self setupRefresh];
}

- (void)setupRefresh
{
    
    
    MJRefreshNormalHeader * headRe = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewData)];
    self.tableView.mj_header = headRe;
    // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
//    [self.tableView addHeaderWithTarget:self action:@selector(getNewData)];
    //#warning 自动刷新(一进入程序就下拉刷新)
    //    [self.tableView headerBeginRefreshing];
    // 设置文字(也可以不设置,默认的文字在MJRefreshConst中修改)
//    self.tableView.headerPullToRefreshText = @"下拉可以刷新了";
//    self.tableView.headerReleaseToRefreshText = @"松开马上刷新了";
//    self.tableView.headerRefreshingText = @"正在刷新最新数据,请稍等";
    
    // 2.上拉加载更多(进入刷新状态就会调用self的footerRereshing)
    
    MJRefreshAutoNormalFooter * Footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(getMoreGoodList)];
    self.tableView.mj_footer = Footer;
    
//    [self.tableView addFooterWithTarget:self action:@selector(getMoreGoodList)];
    
//    self.tableView.footerPullToRefreshText = @"上拉可以加载更多数据了";
//    self.tableView.footerReleaseToRefreshText = @"松开马上加载更多数据了";
//    self.tableView.footerRefreshingText = @"正在加载更多数据,请稍等";
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _initImageAndLabel];
    
    [self getNewData];
    
    [self _initTableView];
}

/**
 *  设置图片和文字详细
 */
- (void)_initImageAndLabel {
    
    NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * filename = [[array objectAtIndex:0] stringByAppendingPathComponent:SISUserInfo];
    self.model = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
    
    [self.logoImage sd_setImageWithURL:[NSURL URLWithString:self.model.imgUrl] placeholderImage:nil options:SDWebImageRetryFailed];
    self.logoImage.userInteractionEnabled = YES;
    [self.logoImage bk_whenTapped:^{
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        SISSettingController *set = [story instantiateViewControllerWithIdentifier:@"SISSettingController"];
        \
        [self.navigationController pushViewController:set animated:YES];
    }];
    
    self.SISName.text = self.model.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_initNavBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"添加商品" style:UIBarButtonItemStylePlain handler:^(id sender) {
        
        NSMutableDictionary *parame = [NSMutableDictionary dictionary];
        parame[@"userid"] = self.model.userId;
        
        
        NSMutableString * url = [NSMutableString stringWithString:SISMainUrl];
        [url appendString:@"getCategoryList"];
        
        
        [SVProgressHUD showWithStatus:@"数据加载中"];
        parame = [NSDictionary asignWithMutableDictionary:parame];
        
       
        
        [UserLoginTool loginRequestGet:url parame:parame success:^(id json) {
            [SVProgressHUD dismiss];
            NSLog(@"%@",json);
            
            if ([json[@"systemResultCode"] intValue] == 1 && [json[@"resultCode"] intValue] == 1) {
                
                NSArray *cate = [SISCategory objectArrayWithKeyValuesArray:json[@"resultData"][@"list"]];
                
                SISShopViewController *shop = [[SISShopViewController alloc] init];
                SISCategory *all = [[SISCategory alloc] init];
                all.sisId = @"0";
                all.sisName = @"全部";
                NSMutableArray *arry = [NSMutableArray array];
                [arry addObject:all];
                [arry addObjectsFromArray:cate];
                shop.categroyArray = arry;
                [self.navigationController pushViewController:shop animated:YES];
            }else {
                
            }
            
            
            
            
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:@"网络异常，请检查网络"];
            
            
            NSLog(@"%@",error);
            
        }];
        
        
        
        
    }];
}

- (void)_initHeadViewAndButton {
    self.headView.backgroundColor = HuoBanMallBuyNavColor;
    
    [self.storeManagement setTitleColor:HuoBanMallBuyNavColor forState:UIControlStateNormal];
    [self.storeManagement setBackgroundColor:[UIColor whiteColor]];
    self.storeManagement.layer.cornerRadius = 5;
    
    
    /**去掉导航栏黑线*/
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    
}

- (void)_initImagesAndAction {
    
    /**
     *  二维码
     */
    self.QRCode.contentMode = UIViewContentModeScaleAspectFit;
    self.QRCode.image = [UIImage imageNamed:@"40"];
    
    [self.QRCode bk_whenTapped:^{
        
        
        UIView * black = [[UIView alloc] init];
        black.frame = CGRectMake(0, 0, SecrenWith, SecrenHeight);
        black.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.720];
//        black.alpha = 0.5;
        [self.view.window addSubview:black];
        
        UIImageView * QRCode = [[UIImageView alloc] init];
        QRCode.center = black.center;
        QRCode.bounds = CGRectMake(0, 0, SecrenWith * 0.5, SecrenWith * 0.5);
        QRCode.frame = CGRectMake(QRCode.frame.origin.x, QRCode.frame.origin.y, SecrenWith * 0.5, SecrenWith * 0.5);
        QRCode.image =  [UIImage ToCreateQRcodeWithInformation:self.model.indexUrl];
        QRCode.contentMode = UIViewContentModeScaleToFill;
        [black addSubview:QRCode];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(QRCode.frame.origin.x, QRCode.frame.origin.y + SecrenWith * 0.5 + 20 , SecrenWith * 0.5, 40)];
        [button setTitle:@"点击我分享" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(shareQRCode) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = HuoBanMallBuyNavColor;
        button.layer.cornerRadius = 5;
        
        [black addSubview:button];
        
        [black bk_whenTapped:^{
           
        [black removeFromSuperview];
            
        }];
    }];
    
    
}

- (void)shareQRCode{
    
    //1、创建分享参数
    NSArray* imageArray = @[self.model.imgUrl];
    if (imageArray) {
        NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
        [shareParams SSDKSetupShareParamsByText:self.model.shareDescription
                                         images:imageArray
                                            url:[NSURL URLWithString:self.model.indexUrl]
                                          title:self.model.shareTitle
                                           type:SSDKContentTypeAuto];
        //2、分享（可以弹出我们的分享菜单和编辑界面）
        [ShareSDK showShareActionSheet:nil //要显示菜单的视图, iPad版中此参数作为弹出菜单的参照视图，只有传这个才可以弹出我们的分享菜单，可以传分享的按钮对象或者自己创建小的view 对象，iPhone可以传nil不会影响
                                 items:nil
                           shareParams:shareParams
                   onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                       
                       switch (state) {
                           case SSDKResponseStateSuccess:
                           {
                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                                                                                   message:nil
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"确定"
                                                                         otherButtonTitles:nil];
                               [alertView show];
                               break;
                           }
                           case SSDKResponseStateFail:
                           {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                               message:[NSString stringWithFormat:@"%@",error]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil, nil];
                               [alert show];
                               break;
                           }
                           default:
                               break;
                       }
                       
                   }];
        
    }
}

- (void)_initOutUPLabel {
    self.saleLabel.text = [NSString stringWithFormat:@"销售中(%@)", self.sisuptotal];
    
    self.shelvesLabel.text = [NSString stringWithFormat:@"已下架(%@)", self.sisouttotal];
}

- (void)_initSliding {
    [self.bgView layoutIfNeeded];
    [self.sale layoutIfNeeded];
    [self.shelves layoutIfNeeded];
    
    self.type = 1;
    
    self.sale.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    
    CGFloat x = self.shelves.frame.origin.x;
    CGFloat y = self.shelves.frame.origin.y + self.shelves.frame.size.height;
    CGFloat width = self.sale.frame.size.width;
    
    
    self.slidingView = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, 2)];
    [self.slidingView setBackgroundColor:[UIColor redColor]];
    [self.bgView addSubview:self.slidingView];
    
    [self.sale bk_whenTapped:^{
        if (self.slidingView.frame.origin.x) {
            [UIView animateWithDuration:0.25 animations:^{
                self.slidingView.frame = CGRectMake(0, y, width, 2);
                self.sale.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
                self.shelves.backgroundColor = [UIColor whiteColor];
                self.type = 1;
                
                
            }];
            [self getNewData];
        }
    }];
    
    [self.shelves bk_whenTapped:^{
        if (self.slidingView.frame.origin.x == 0) {
            [UIView animateWithDuration:0.25 animations:^{
                self.slidingView.frame = CGRectMake(x, y, width, 2);
                self.shelves.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
                self.sale.backgroundColor = [UIColor whiteColor];
                self.type = 0;
            }];
            [self getNewData];
        }
    }];
    
    
}

- (IBAction)storeManagementAction:(id)sender {
    
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    SISSettingController *set = [story instantiateViewControllerWithIdentifier:@"SISSettingController"];
    
    [self.navigationController pushViewController:set animated:YES];
    
    
}

- (void)getNewData {
    
    NSMutableDictionary *parame = [NSMutableDictionary dictionary];
    parame[@"pageno"] = @"0";
    parame[@"userid"] = self.model.userId;
    parame[@"selected"]= [NSString stringWithFormat:@"%ld",(long)self.type];
    
//    parame = [NSDictionary asignWithMutableDictionary:parame];
    NSMutableString * url = [NSMutableString stringWithString:SISMainUrl];
    [url appendString:@"searchSisGoodsList"];
    
    [SVProgressHUD showWithStatus:@"数据加载中"];
    [UserLoginTool loginRequestGet:url parame:parame success:^(id json) {
        [SVProgressHUD dismiss];
        NSLog(@"%@",json);
        if ([json[@"systemResultCode"] intValue] == 1 && [json[@"resultCode"] intValue] == 1) {
            
            [self.goodsArray removeAllObjects];
            
            NSArray *array = [SISGoodModel objectArrayWithKeyValuesArray:json[@"resultData"][@"list"]];
            [self.goodsArray addObjectsFromArray:array];
            
            [self.tableView reloadData];
            
            self.rpageno = json[@"resultData"][@"rpageno"];
            
            self.sisuptotal = json[@"resultData"][@"sisuptotal"];
            self.sisouttotal = json[@"resultData"][@"sisouttotal"];
            [self _initOutUPLabel];
            // 拿到当前的下拉刷新控件，结束刷新状态
            [self.tableView.mj_header endRefreshing];
        }
        
//        [self.tableView.mj_header headerEndRefreshing];
    } failure:^(NSError *error) {
//        [self.tableView headerEndRefreshing];
        [SVProgressHUD showErrorWithStatus:@"网络异常，请检查网络"];
        NSLog(@"%@",error);
        // 拿到当前的下拉刷新控件，结束刷新状态
        [self.tableView.mj_header endRefreshing];
    }];
    
}

- (void)getMoreGoodList {
    
    NSMutableDictionary *parame = [NSMutableDictionary dictionary];
    parame[@"pageno"] = [NSString stringWithFormat:@"%@", self.rpageno];
    parame[@"userid"] = self.model.userId;
    parame[@"selected"]= [NSString stringWithFormat:@"%ld",(long)self.type];
    
    parame = [NSDictionary asignWithMutableDictionary:parame];
    NSMutableString * url = [NSMutableString stringWithString:SISMainUrl];
    [url appendString:@"searchSisGoodsList"];
    [UserLoginTool loginRequestGet:url parame:parame success:^(id json) {
//        [self.tableView footerEndRefreshing];
        NSLog(@"%@",json);
        if ([json[@"systemResultCode"] intValue] == 1 && [json[@"resultCode"] intValue] == 1) {
            
            
            NSArray *array = [SISGoodModel objectArrayWithKeyValuesArray:json[@"resultData"][@"list"]];
            NSMutableArray *temp = [NSMutableArray arrayWithArray:array];
            
            for (SISGoodModel *good1 in array) {
                for (SISGoodModel *goodTemp in self.goodsArray) {
                    if ([good1.goodsId isEqualToString:goodTemp.goodsId]) {
                        [temp removeObject:good1];
                    }
                }
            }
            
            [self.goodsArray addObjectsFromArray:temp];
            
            [self.tableView reloadData];
            
            self.rpageno = json[@"resultData"][@"rpageno"];
            
            self.sisuptotal = json[@"resultData"][@"sisuptotal"];
            self.sisouttotal = json[@"resultData"][@"sisouttotal"];
            // 拿到当前的下拉刷新控件，结束刷新状态
            [self.tableView.mj_footer endRefreshing];
            [self _initOutUPLabel];
        }else {
            
        }
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络异常，请检查网络"];
        NSLog(@"%@",error);
        // 拿到当前的下拉刷新控件，结束刷新状态
        [self.tableView.mj_footer endRefreshing];
    }];
    
}

#pragma mark tableView

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    SISGoodsCell *cell = [tableView dequeueReusableCellWithIdentifier:homeCellIdentify forIndexPath:indexPath];
    
    SISGoodModel *model = self.goodsArray[indexPath.row];
    
    cell.model = model;
    
    cell.more.tag = 10000 + indexPath.row;
    [cell.more addTarget:self action:@selector(tableViewCellMoreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.moreView bk_whenTapped:^{
        
        self.good = cell.model;
        
        CGRect rc = [cell convertRect:cell.more.frame toView:self.view];
        
        if (self.type == 0) {
            NSArray *menuItems =
            @[
              
              [KxMenuItem menuItem:@"推广"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"上架"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"删除"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"移到顶部"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              ];
            
            [KxMenu setTintColor:[UIColor colorWithWhite:0.945 alpha:1.000]];
            
            
            [KxMenu showMenuInView:self.view
                          fromRect:rc
                         menuItems:menuItems];
        }else {
            NSArray *menuItems =
            @[
              
              [KxMenuItem menuItem:@"推广"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"下架"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"删除"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              [KxMenuItem menuItem:@"移到顶部"
                             image:nil
                            target:self
                            action:@selector(pushMenuItem:)],
              
              ];
            
            [KxMenu setTintColor:[UIColor colorWithWhite:0.945 alpha:1.000]];
            
            
            [KxMenu showMenuInView:self.view
                          fromRect:rc
                         menuItems:menuItems];
        }
    }];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.goodsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SISGoodModel *model = self.goodsArray[indexPath.row];
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SISWebViewController *web = [story instantiateViewControllerWithIdentifier:@"SISWebViewController"];
    web.type = 1;
    web.goodUrl = model.detailsUrl;
    web.goodId = model.goodsId;
    web.goodSelected = model.goodSelected;
    
    [self.navigationController pushViewController:web animated:YES];
    
}



- (void)tableViewCellMoreButtonAction:(UIButton *) button {
    
    self.selectIndexPath = [NSIndexPath indexPathForRow:button.tag - 10000 inSection:0];
    
    SISGoodsCell *cell = [self.tableView cellForRowAtIndexPath:self.selectIndexPath];
    
    self.good = cell.model;
    
    
    CGRect rc = [cell convertRect:cell.more.frame toView:self.view];
    
    if (self.type == 0) {
        NSArray *menuItems =
        @[
          
          [KxMenuItem menuItem:@"推广"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"上架"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"删除"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"移到顶部"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          ];
        
        [KxMenu setTintColor:[UIColor colorWithWhite:0.945 alpha:1.000]];
        
        
        [KxMenu showMenuInView:self.view
                      fromRect:rc
                     menuItems:menuItems];
    }else {
        NSArray *menuItems =
        @[
          
          [KxMenuItem menuItem:@"推广"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"下架"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"删除"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          [KxMenuItem menuItem:@"移到顶部"
                         image:nil
                        target:self
                        action:@selector(pushMenuItem:)],
          
          ];
        
        [KxMenu setTintColor:[UIColor colorWithWhite:0.945 alpha:1.000]];
        
        
        [KxMenu showMenuInView:self.view
                      fromRect:rc
                     menuItems:menuItems];
    }
    
    
}

- (void)pushMenuItem:(KxMenuItem *)sender {
    
    NSLog(@"%@", sender.title);
    if ([sender.title isEqualToString:@"推广"]) {
        [self shareGoods];
    }else {
        NSMutableDictionary *parame = [NSMutableDictionary dictionary];
        
        if ([sender.title isEqualToString:@"下架"]){
            parame[@"opertype"] = @"0";
        }else if ([sender.title isEqualToString:@"删除"]){
            parame[@"opertype"] = @"3";
        }else if ([sender.title isEqualToString:@"移到顶部"]){
            parame[@"opertype"] = @"2";
        }else if ([sender.title isEqualToString:@"上架"]){
            parame[@"opertype"] = @"1";
        }
        
        
        
        parame[@"userid"] = self.model.userId;
        parame[@"goodsid"] = self.good.goodsId;
        
        
        
        NSMutableString * url = [NSMutableString stringWithString:SISMainUrl];
        [url appendString:@"operGoods"];
        [SVProgressHUD showWithStatus:@"请稍等"];
        [UserLoginTool loginRequestPost:url parame:parame success:^(id json) {
            NSLog(@"%@",json);
            [SVProgressHUD dismiss];
            if ([json[@"systemResultCode"] intValue] == 1 && [json[@"resultCode"] intValue] == 1) {
                [self.goodsArray removeObject:self.good];
                [self.tableView reloadData];
                self.sisuptotal = json[@"resultData"][@"sisuptotal"];
                self.sisouttotal = json[@"resultData"][@"sisouttotal"];
                [self _initOutUPLabel];
                
            }
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:@"网络异常，请检查网络"];
            NSLog(@"%@", error);
        }];
        
    }
    
}

- (void)shareGoods{
    
    //1、创建分享参数
    NSArray* imageArray = @[self.good.imgUrl];
    if (imageArray) {
        NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
        [shareParams SSDKSetupShareParamsByText:nil
                                         images:imageArray
                                            url:[NSURL URLWithString:self.good.shareUrl]
                                          title:self.good.goodsName
                                           type:SSDKContentTypeAuto];
        //2、分享（可以弹出我们的分享菜单和编辑界面）
        [ShareSDK showShareActionSheet:nil //要显示菜单的视图, iPad版中此参数作为弹出菜单的参照视图，只有传这个才可以弹出我们的分享菜单，可以传分享的按钮对象或者自己创建小的view 对象，iPhone可以传nil不会影响
                                 items:nil
                           shareParams:shareParams
                   onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                       
                       switch (state) {
                           case SSDKResponseStateSuccess:
                           {
                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                                                                                   message:nil
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"确定"
                                                                         otherButtonTitles:nil];
                               [alertView show];
                               break;
                           }
                           case SSDKResponseStateFail:
                           {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                               message:[NSString stringWithFormat:@"%@",error]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil, nil];
                               [alert show];
                               break;
                           }
                           default:
                               break;
                       }
                       
                   }];
        
    }
}


@end
