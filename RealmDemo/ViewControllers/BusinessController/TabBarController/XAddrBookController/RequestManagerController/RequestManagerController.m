//
//  RequestManagerController.m
//  BangBang
//
//  Created by lottak_mac2 on 16/7/5.
//  Copyright © 2016年 Lottak. All rights reserved.
//

#import "RequestManagerController.h"
#import "RequestManagerCell.h"
#import "UserHttp.h"
#import "UserManager.h"

@interface RequestManagerController ()<UITableViewDelegate,UITableViewDataSource,RequestManagerCellDelegate,RBQFetchedResultsControllerDelegate> {
    UserManager *_userManager;//用户管理器
    UITableView *_tableView;//表格视图
    NSMutableArray<Employee*> *_joinDataArr;//申请加入的员工数组
    RBQFetchedResultsController *_joinFetchedResultsController;//状态为0的员工数据监听
    NSMutableArray<Employee*> *_exitDataArr;//申请退出的员工数组
    RBQFetchedResultsController *_exitFetchedResultsController;//状态为4的员工数据监听
}

@end

@implementation RequestManagerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"申请管理";
    //创建数据监听
    _userManager = [UserManager manager];
    _joinFetchedResultsController = [_userManager createEmployeesFetchedResultsControllerWithCompanyNo:_userManager.user.currCompany.company_no status:0];
    _joinFetchedResultsController.delegate = self;
    _exitFetchedResultsController = [_userManager createEmployeesFetchedResultsControllerWithCompanyNo:_userManager.user.currCompany.company_no status:4];
    _exitFetchedResultsController.delegate = self;
    _joinDataArr = [_userManager getEmployeeWithCompanyNo:_userManager.user.currCompany.company_no status:0];
    _exitDataArr = [_userManager getEmployeeWithCompanyNo:_userManager.user.currCompany.company_no status:4];
    //创建表格视图
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [_tableView registerNib:[UINib nibWithNibName:@"RequestManagerCell" bundle:nil] forCellReuseIdentifier:@"RequestManagerCell"];
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [UserHttp getEmployeeCompnyNo:_userManager.user.currCompany.company_no status:-1 userGuid:_userManager.user.user_guid handler:^(id data, MError *error) {
            [_tableView.mj_header endRefreshing];
            if(error) {
                [self.navigationController.view showFailureTips:@"获取失败，请重试"];
                return ;
            }
            NSMutableArray *array = [@[] mutableCopy];
            for (NSDictionary *dic in data[@"list"]) {
                Employee *employee = [Employee new];
                [employee mj_setKeyValues:[dic mj_keyValues]];
                [array addObject:employee];
            }
            //存入本地数据库
            [_userManager updateEmployee:array companyNo:_userManager.user.currCompany.company_no];
        }];
    }];
    [self.view addSubview:_tableView];
    // Do any additional setup after loading the view.
}
#pragma mark --
#pragma mark -- RBQFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(nonnull RBQFetchedResultsController *)controller {
    if(controller == _joinFetchedResultsController) {
        _joinDataArr = (id)_joinFetchedResultsController.fetchedObjects;
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
    else {
        _exitDataArr = (id)_exitFetchedResultsController.fetchedObjects;
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    }
}
#pragma mark --
#pragma mark -- RequestManagerCellDelegate
- (void)requestManagerAgree:(Employee*)employee {
    NSString *topStr = employee.status == 0 ? @"同意该用户加入圈子?" : @"同意该用户退出圈子?";
    int status = employee.status == 0 ? 1 : 2;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:topStr message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController.view showLoadingTips:@"请稍等..."];
        [UserHttp updateEmployeeStatus:employee.employee_guid status:status reason:nil handler:^(id data, MError *error) {
            if(error) {
                [self.navigationController.view showFailureTips:error.statsMsg];
                return ;
            }
            //更新用户信息
            employee.status = status;
            [_userManager updateEmployee:employee];
            //这里要调用加入/退出群租聊天
            if(status == 1) {
                [UserHttp joinRYGroup:employee.user_no companyNo:_userManager.user.currCompany.company_no handler:^(id data, MError *error) {
                    [self.navigationController.view dismissTips];
                    if(error) {
                        [self.navigationController.view showFailureTips:error.statsMsg];
                        return ;
                    }
                    [self.navigationController.view showSuccessTips:@"操作成功"];
                }];
            } else {
                [UserHttp quitRYGroup:employee.user_no companyNo:_userManager.user.currCompany.company_no handler:^(id data, MError *error) {
                    [self.navigationController.view dismissTips];
                    if(error) {
                        [self.navigationController.view showFailureTips:error.statsMsg];
                        return ;
                    }
                    [self.navigationController.view showSuccessTips:@"操作成功"];
                }];
            }
        }];
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancleAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}
- (void)requestManagerRefuse:(Employee*)employee {
    NSString *topStr = employee.status == 0 ? @"拒绝该用户加入圈子?" : @"拒绝该用户退出圈子?";
    int status = employee.status == 0 ? 3 : 1;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:topStr message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController.view showLoadingTips:@"请稍等..."];
        [UserHttp updateEmployeeStatus:employee.employee_guid status:status reason:nil handler:^(id data, MError *error) {
            [self.navigationController.view dismissTips];
            if(error) {
                [self.navigationController.view showFailureTips:error.statsMsg];
                return ;
            }
            //更新用户信息
            employee.status = status;
            [_userManager updateEmployee:employee];
            [self.navigationController.view showSuccessTips:@"操作成功"];
        }];
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancleAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}
#pragma mark --
#pragma mark -- UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, 45)];
    headerView.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 12.5, MAIN_SCREEN_WIDTH - 30, 20)];
    if(section == 0) {
        label.text = [NSString stringWithFormat:@"加入申请（%@）",@(_joinDataArr.count)];
    } else {
         label.text = [NSString stringWithFormat:@"退出申请（%@）",@(_exitDataArr.count)];
    }
    [headerView addSubview:label];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, MAIN_SCREEN_WIDTH, 1)];
    lineView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [headerView addSubview:lineView];
    return headerView;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
        return _joinDataArr.count;
    return _exitDataArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    RequestManagerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RequestManagerCell" forIndexPath:indexPath];
    if(indexPath.section == 0) {
        cell.data = _joinDataArr[indexPath.row];
    } else {
        cell.data = _exitDataArr[indexPath.row];
    }
    cell.delegate = self;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end