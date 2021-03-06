//
//  OaLoginController.h
//  HuoBanMall
//
//  Created by lhb on 2017/8/25.
//  Copyright © 2017年 HT. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol OaLoginControllerDelegate <NSObject>

/***/
- (void) OaLoginControllerResult:(int)type;

@end

@interface OaLoginController : UIViewController
@property (nonatomic, strong) NSString *goUrl;

// 首页和非首页
@property (nonatomic, assign) int inWeb;


/**云品星球代理*/
@property (nonatomic,weak) id <OaLoginControllerDelegate> delegate;

@end
