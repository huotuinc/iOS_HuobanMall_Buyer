//
//  LoginViewController.m
//  HuoBanMallBuy
//
//  Created by lhb on 15/10/12.
//  Copyright (c) 2015年 HT. All rights reserved.
//

#import "LoginViewController.h"
#import "WXApi.h"
#import "RootViewController.h"
#import "MJExtension.h"
#import "AccountTool.h"
#import "UserInfo.h"
#import "AQuthModel.h"
#import "MJExtension.h"
//#import <AFNetworking.h>
#import "AFNetworking.h"
#import "NSDictionary+HuoBanMallSign.h"
#import "PayModel.h"
#import <SVProgressHUD.h>
#import "MBProgressHUD+MJ.h"
#import "AppDelegate.h"
#import "AccountModel.h"
#import "UIViewController+MonitorNetWork.h"
#import "UserLoginTool.h"
#import "LeftMenuModel.h"
#import "MallMessage.h"
#import "IponeVerifyViewController.h"
#import <UIBarButtonItem+BlocksKit.h>
#import <ShareSDK/ShareSDK.h>

@interface LoginViewController ()<WXApiDelegate>

- (IBAction)loginBtnClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.image.contentMode = UIViewContentModeScaleAspectFit;
    
    
    
    
    [UIViewController MonitorNetWork];
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    self.navigationController.navigationBar.barTintColor = HuoBanMallBuyNavColor;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"取消" style:UIBarButtonItemStylePlain handler:^(id sender) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CannelLoginBackHome" object:nil];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }];
    
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    
    
    self.loginButton.layer.cornerRadius = 22;

}



- (void)OquthByWeiXinSuccess2:(NSNotification *) note{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ToGetUserInfo" object:nil];
    [SVProgressHUD showWithStatus:@"登录中"];
    NSLog(@"-=------------%@",note);
//    AQuthModel * account = [AccountTool account];
//    if (account.refresh_token.length) {
//        [self toRefreshaccess_token];
//    }else{
        [self accessTokenWithCode:note.userInfo[@"code"]];
//    }
    [self ToGetShareMessage];
    
}

/**
 * 分享商城信息
 */
- (void)ToGetShareMessage{
    NSMutableString * url = [NSMutableString stringWithString:AppOriginUrl];
    [url appendString:@"/mall/getConfig"];
    NSMutableDictionary * parame = [NSMutableDictionary dictionary];
    parame[@"custo  merid"] = HuoBanMallBuyApp_Merchant_Id;
    [UserLoginTool loginRequestGet:url parame:parame success:^(id json) {
        MallMessage * mallmodel = [MallMessage objectWithKeyValues:json];
        NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * filename = [[array objectAtIndex:0] stringByAppendingPathComponent:HuoBanMaLLMess];
        [NSKeyedArchiver archiveRootObject:mallmodel toFile:filename];
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
    
    
}


- (IBAction)loginBtnClick:(id)sender {
    NSNumber *str = [[NSUserDefaults standardUserDefaults] objectForKey:TestMode];
    if ([[str stringValue] isEqualToString:@"1"]) {
        [self WeiXinFailureToUserOrigin1];
    }else {
        
        
        if ([AccountTool verifyAccess_Token_Effect]) {
            [self toRefreshaccess_token]; //刷新access_token
        }else{
            
            if ([WXApi isWXAppInstalled]) {
                [self WeiXinLog];
            }else {
                [self WeiXinFailureToUserOrigin1];
            }
            
        }
    }
}

/**
 *  微信授权登录
 */
- (void)WeiXinLog{
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OquthByWeiXinSuccess2:) name:@"ToGetUserInfo" object:nil];
//    //构造SendAuthReq结构体
//    SendAuthReq* req =[[SendAuthReq alloc ] init];
//    req.scope = @"snsapi_userinfo" ;
//    req.state = @"123" ;
//    //第三方向微信终端发送一个SendAuthReq消息结构
//    [WXApi sendAuthReq:req viewController:self delegate:self];
    __weak LoginViewController * wself = self;
    [ShareSDK getUserInfo:SSDKPlatformTypeWechat onStateChanged:^(SSDKResponseState state, SSDKUser *user, NSError *error) {
        if (state == SSDKResponseStateSuccess) {
            
            UserInfo * userInfo = [UserInfo objectWithKeyValues:user.rawData];
            NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *fileName = [path stringByAppendingPathComponent:WeiXinUserInfo];
            [NSKeyedArchiver archiveRootObject:userInfo toFile:fileName];
            //向服务端提供微信数据
            [wself toPostWeiXinUserMessage:userInfo];
            //获取主地址
            [wself toGetMainUrl];
            //微信授权成功后获取支付参数
            [wself WeiXinLoginSuccessToGetPayParameter];
            //获得用户账户列表
        }
    }];
    
}

/**
 *  用户登录成功
 *
 *  @param note
 */
- (void)UserLoginSuccess{
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:MallUserRelatedType];
    
    [[NSUserDefaults standardUserDefaults] setObject:Success forKey:LoginStatus];
    if ([str intValue] == 1) {
        [SVProgressHUD dismiss];
        [self.view endEditing:NO];
        IponeVerifyViewController *bundle = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"IponeVerifyViewController"];
        bundle.isBundlPhone = YES;
        bundle.goUrl = _goUrl;
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [app resetUserAgent:nil];
        [self.navigationController pushViewController:bundle animated:YES];
    }else {
        
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [app resetUserAgent:_goUrl];
        [app sendTokenAndUserIdToSevern];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [SVProgressHUD dismiss];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}



/**
 *  通过code获取accessToken
 *
 *  @param code code
 */

- (void)accessTokenWithCode:(NSString * )code
{
    
    
     __weak LoginViewController * wself = self;
    //进行授权
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",HuoBanMallBuyWeiXinAppId,HuoBanMallShareSdkWeiXinSecret,code];
    [UserLoginTool loginRequestGet:url parame:nil success:^(id json) {
        
//        NSLog(@"accessTokenWithCode%@",json);
        AQuthModel * aquth = [AQuthModel objectWithKeyValues:json];
        [AccountTool saveAccount:aquth];
        //获取用户信息
        [wself getUserInfo:aquth];
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
}



/**
 *  刷新access_token
 */
- (void)toRefreshaccess_token{
    
    
    __weak LoginViewController * wself = self;
    AQuthModel * mode = [AccountTool account];
    NSString * ss = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%@&grant_type=refresh_token&refresh_token=%@",HuoBanMallBuyWeiXinAppId,mode.refresh_token];
    [UserLoginTool loginRequestGet:ss parame:nil success:^(id json) {
        AQuthModel * aquth = [AQuthModel objectWithKeyValues:json];
        [AccountTool saveAccount:aquth];
        //获取用户信息
        [wself getUserInfo:aquth];
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
}




/**
 *  微信授权登录后返回的用户信息
 */
-(void)getUserInfo:(AQuthModel*)aquth
{
    __weak LoginViewController * wself = self;
    NSMutableDictionary * parame = [NSMutableDictionary dictionary];
    parame[@"access_token"] = aquth.access_token;
    parame[@"openid"] = aquth.openid;
    [UserLoginTool loginRequestGet:@"https://api.weixin.qq.com/sns/userinfo" parame:parame success:^(id json) {
        UserInfo * userInfo = [UserInfo objectWithKeyValues:json];
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *fileName = [path stringByAppendingPathComponent:WeiXinUserInfo];
        [NSKeyedArchiver archiveRootObject:userInfo toFile:fileName];
        //向服务端提供微信数据
        [wself toPostWeiXinUserMessage:userInfo];
        //获取主地址
        [wself toGetMainUrl];
        //微信授权成功后获取支付参数
        [wself WeiXinLoginSuccessToGetPayParameter];
        //获得用户账户列表

        
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
    
}


/**
 *  获取主地址
 */
- (void)toGetMainUrl{
    
    NSMutableDictionary * parame = [NSMutableDictionary dictionary];
    UserInfo * usaa = nil;
    if ([AccountTool account]) {
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *fileName = [path stringByAppendingPathComponent:WeiXinUserInfo];
        usaa =  [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
    };
    parame[@"unionid"] = usaa.unionid;
    parame = [NSDictionary asignWithMutableDictionary:parame];
    NSMutableString * url = [NSMutableString stringWithString:AppOriginUrl];
    [url appendString:@"/mall/getmsiteurl"];
    [UserLoginTool loginRequestGet:url parame:parame success:^(id json) {
        if ([json[@"code"] integerValue] == 200) {
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"msiteUrl"] forKey:AppMainUrl];
            
        }
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
}


/**
 *  提交数据给服务端
 *
 *  @param user <#user description#>
 */
- (void)toPostWeiXinUserMessage:(UserInfo *) user{
//    [MBProgressHUD showMessage:nil];
    __weak LoginViewController * wself = self;
    NSMutableDictionary * parame = [NSMutableDictionary dictionary];
    parame[@"sex"] = [NSString stringWithFormat:@"%ld",(long)[user.sex integerValue]];
    parame[@"nickname"] = user.nickname;
    parame[@"openid"] = user.openid;
    parame[@"city"] = user.city;
    parame[@"country"] = user.country;
    parame[@"province"] = user.province;
    parame[@"headimgurl"] = user.headimgurl;
    parame[@"unionid"] = user.unionid;
    parame = [NSDictionary asignWithMutableDictionary:parame];
    NSMutableString * url = [NSMutableString stringWithString:AppOriginUrl];
    [url appendString:@"/weixin/LoginAuthorize"];
    [UserLoginTool loginRequestPost:url parame:parame success:^(id json) {
        if ([json[@"code"] integerValue] == 200) {
            
            
            user.nickname = json[@"data"][@"nickName"];
            user.headimgurl = json[@"data"][@"headImgUrl"];
            user.openid = json[@"data"][@"openId"];
            user.relatedType = json[@"data"][@"relatedType"];
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"relatedType"] forKey:MallUserRelatedType];
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"levelName"] forKey:HuoBanMallMemberLevel];
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"userid"] forKey:HuoBanMallUserId];
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"headImgUrl"] forKey:IconHeadImage];
            [[NSUserDefaults standardUserDefaults] setObject:json[@"data"][@"relatedType"] forKey:MallUserRelatedType];
            NSArray * lefts = [LeftMenuModel objectArrayWithKeyValuesArray:json[@"data"][@"home_menus"]];
            NSMutableData *data = [[NSMutableData alloc] init];
            //创建归档辅助类
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            //编码
            [archiver encodeObject:lefts forKey:LeftMenuModels];
            //结束编码
            [archiver finishEncoding];
            NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString * filename = [[array objectAtIndex:0] stringByAppendingPathComponent:LeftMenuModels];
            //写入
            [data writeToFile:filename atomically:YES];
            
            NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *fileName = [path stringByAppendingPathComponent:WeiXinUserInfo];
            [NSKeyedArchiver archiveRootObject:user toFile:fileName];
            [self UserLoginSuccess];
            
        }
    } failure:^(NSError *error) {
//        [MBProgressHUD hideHUD];
         NSLog(@"%@ --- ",error.description);
    }];
   
}


/**
 *  微信授权成功后获取支付参数
 */
- (void) WeiXinLoginSuccessToGetPayParameter{
//    NSString * url = [NSString stringWithFormat:@"http://mallapi.huobanj.cn/PayConfig?customerId=%@",HuoBanMallBuyApp_Merchant_Id];
    NSMutableDictionary * parame = [NSMutableDictionary dictionary];
    parame = [NSDictionary asignWithMutableDictionary:parame];
    NSString * cc = [NSString stringWithFormat:@"%@%@",AppOriginUrl,@"/PayConfig"];
    [UserLoginTool loginRequestGet:cc parame:parame success:^(id json) {
        if ([json[@"code"] integerValue] == 200) {
            NSArray * payType = [PayModel objectArrayWithKeyValuesArray:json[@"data"]];
            NSMutableData *data = [[NSMutableData alloc] init];
            //创建归档辅助类
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            //编码
            [archiver encodeObject:payType forKey:PayTypeflat];
            //结束编码
            [archiver finishEncoding];
            NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString * filename = [[array objectAtIndex:0] stringByAppendingPathComponent:PayTypeflat];
            //写入
            [data writeToFile:filename atomically:YES];
        }
    } failure:^(NSError *error) {
        NSLog(@"%@",error.description);
    }];
    
}

- (void)WeiXinFailureToUserOrigin1{
    
    IponeVerifyViewController * iphone = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"IponeVerifyViewController"];
    UINavigationController *nav =[[UINavigationController alloc] initWithRootViewController:iphone];
    [self presentViewController:nav animated:YES completion:nil];
    
  
    
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
