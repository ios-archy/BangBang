//
//  UserInfo.h
//  RealmDemo
//
//  Created by Mac on 16/7/30.
//  Copyright © 2016年 com.luohaifang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject

/** qq */
@property (nonatomic, strong) NSString  * QQ;
/** 头像 */
@property (nonatomic, strong) NSString  * avatar;
/** email(帐号) */
@property (nonatomic, strong) NSString  * email;
/** id  */
@property (nonatomic, assign) int id;
/** 手机号 */
@property (nonatomic, strong) NSString  * mobile;
/** 心情动态 */
@property (nonatomic, strong) NSString  * mood;
/** 姓名 必填 */
@property (nonatomic, strong) NSString  * real_name;
/** 性别：0-保密 1-男 2-女 */
@property (nonatomic, assign) int sex;
/** 用户唯一编号 */
@property (nonatomic, strong) NSString  * user_guid;
/** 用户唯一编号 */
@property (nonatomic, strong) NSString  * user_name;
/** 用户编号 */
@property (nonatomic, assign) int user_no;
/** weixin */
@property (nonatomic, strong) NSString  * weixin;

@end
