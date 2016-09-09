//
//  HPSettingViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-20.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPSettingViewController.h"
#import "HPReadViewController.h"
#import "HPSetForumsViewController.h"
#import "HPRearViewController.h"
#import "HPBgFetchViewController.h"
#import "HPSetStupidBarController.h"
#import "HPSetImageSizeFilterViewController.h"
#import "HPBlockListViewController.h"
#import "HPLoginViewController.h"
#import "HPAppDelegate.h"

#import "MultilineTextItem.h"
#import "HPSetting.h"
#import "HPAccount.h"
#import "HPTheme.h"

#import "NSUserDefaults+Convenience.h"
#import "RETableViewManager.h"
#import "RETableViewOptionsController.h"
#import <SVProgressHUD.h>
#import "SWRevealViewController.h"
#import "UIAlertView+Blocks.h"
#import "DZWebBrowser.h"
#import <SDWebImage/SDImageCache.h>

#import "HPURLProtocol.h"

// mail
#import <MessageUI/MFMailComposeViewController.h>
#import "sys/utsname.h"

#define VERSION ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"])
#define BUILD ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"])

@interface HPSettingViewController () <UIWebViewDelegate>

@property (strong, nonatomic) RETableViewManager *manager;
@property (strong, nonatomic) RETableViewSection *preferenceSection;
@property (strong, nonatomic) RETableViewSection *imageSection;
@property (strong, nonatomic) RETableViewSection *dataTrackingSection;
@property (strong, nonatomic) RETableViewSection *aboutSection;

@end

@implementation HPSettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 在 RETableViewManager  修改字体 ui7kit 没patch tablecell
    
    self.title = @"设置";
    
    
    UIBarButtonItem *closeButtonItem = [
                                         [UIBarButtonItem alloc] initWithTitle:@"完成"
                                         style:UIBarButtonItemStylePlain
                                         target:self action:@selector(close:)];
     self.navigationItem.leftBarButtonItem = closeButtonItem;
    
    // clear btn
    UIBarButtonItem *clearButtonItem = [
                                        [UIBarButtonItem alloc] initWithTitle:@"重置"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(reset:)];
    self.navigationItem.rightBarButtonItem = clearButtonItem;
    
    if (IOS7_OR_LATER) {
        //[self.tableView setBackgroundColor:[HPTheme backgroundColor]];
    }
  
     
    // Create manager
    //
    self.manager = [[RETableViewManager alloc] initWithTableView:self.tableView delegate:self];
    
    
    
    self.preferenceSection = [self addPreferenceControls];
    self.imageSection = [self addImageControls];
    
    if (IOS7_OR_LATER) {
        RETableViewSection *bgFetchSection = [RETableViewSection sectionWithHeaderTitle:@" " footerTitle:nil];
        @weakify(self);
        RETableViewItem *bgFetchItem = [RETableViewItem itemWithTitle:@"后台应用程序刷新" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            HPBgFetchViewController *vc = [[HPBgFetchViewController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:vc animated:YES];
            
            [item deselectRowAnimated:YES];
            
            [Flurry logEvent:@"Account EnterBgFetch"];
        }];
        [bgFetchSection addItem:bgFetchItem];
        [self.manager addSection:bgFetchSection];
    }

    self.dataTrackingSection = [self addDataTrackingControls];
    self.aboutSection = [self addAboutControls];
    
    @weakify(self);
    RETableViewSection *logoutSection = [RETableViewSection sectionWithHeaderTitle:@"  " footerTitle:@" "];
    RETableViewItem *logoutItem = [RETableViewItem itemWithTitle:@"登出" accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
        
        [UIAlertView showConfirmationDialogWithTitle:@"登出"
                                             message:@"您确定要登出当前账号吗?\n该账号的设置不会丢失"
                                             handler:^(UIAlertView *alertView, NSInteger buttonIndex)
         {
             @strongify(self);
             if (buttonIndex == [alertView cancelButtonIndex]) {
                 ;
             } else {
                 
                 [Flurry logEvent:@"Account Logout"];
                 [[HPAccount sharedHPAccount] logout];
                 [self closeAndShowLoginVC];
             }
         }];
        
        [item deselectRowAnimated:YES];
    }];
    logoutItem.textAlignment = NSTextAlignmentCenter;
    [logoutSection addItem:logoutItem];
    [self.manager addSection:logoutSection];
    
    RETableViewSection *versionSection = [RETableViewSection section];
    RETableViewItem *versionItem = [RETableViewItem itemWithTitle:[NSString stringWithFormat:@"版本 %@", VERSION] accessoryType:UITableViewCellAccessoryNone selectionHandler:^(RETableViewItem *item) {
        
        [item deselectRowAnimated:YES];
    }];
    versionItem.selectionStyle = UITableViewCellSelectionStyleNone;
    versionItem.textAlignment = NSTextAlignmentCenter;
    [versionSection addItem:versionItem];
    
    [self.manager addSection:versionSection];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@" -- dealloc");
}

- (RETableViewSection *)addPreferenceControls {
    
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:nil footerTitle:@"  "];
    //RETableViewSection *section = [RETableViewSection section];
    
    //
    BOOL isNightMode = [Setting boolForKey:HPSettingNightMode];
    @weakify(self);
    REBoolItem *isNightModeItem = [REBoolItem itemWithTitle:@"夜间模式" value:isNightMode switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"isNightMode Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingNightMode];

        if (item.value) {
            ;
        } else {
            ;
        }
        
        [[HPRearViewController sharedRearVC] themeDidChanged];
        @strongify(self);
        self.navigationController.navigationBar.barStyle = [UINavigationBar appearance].barStyle;
        [Flurry logEvent:@"Setting ToggleDarkMode" withParameters:@{@"flag":@(item.value)}];
    }];
    
    // isShowAvatar
    //
    BOOL isShowAvatar = [Setting boolForKey:HPSettingShowAvatar];
    REBoolItem *isShowAvatarItem = [REBoolItem itemWithTitle:@"显示头像" value:isShowAvatar switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"isShowAvatar Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingShowAvatar];
        
        if (item.value) {
            ;
        } else {
            ;
        }
        
        
        [[HPRearViewController sharedRearVC] themeDidChanged];
        
        [Flurry logEvent:@"Setting ToggleShowAvatar" withParameters:@{@"flag":@(item.value)}];
    }];
    
    //
    //
    NSString *postTail = [Setting objectForKey:HPSettingTail];
    RETextItem *postTailText = [RETextItem itemWithTitle:@"小尾巴" value:postTail placeholder:@"留空"];
    
    postTailText.returnKeyType = UIReturnKeyDone;
    postTailText.onEndEditing = ^(RETextItem *item) {
        NSLog(@"setPostTail _%@_", item.value);
        
        NSString *msg = [Setting isPostTailAllow:item.value];
        if (!msg) {
            [Setting setPostTail:item.value];
            
            [SVProgressHUD showSuccessWithStatus:@"已保存"];
        } else {
            [SVProgressHUD showErrorWithStatus:msg];
        }
        
        [Flurry logEvent:@"Setting SetTail" withParameters:@{@"text":item.value}];
    };
    
    //
    //
    RETableViewItem *setForumItem = [RETableViewItem itemWithTitle:@"板块设定" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        @strongify(self);
        HPSetForumsViewController *setForumsViewController = [[HPSetForumsViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:setForumsViewController animated:YES];
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting EnterSetForum"];
    }];
    
    //
    //
    RETableViewItem *blockListItem = [RETableViewItem itemWithTitle:@"屏蔽列表" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        @strongify(self);
        [self.navigationController pushViewController:[[HPBlockListViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting EnterBlockList"];
    }];
    
    // preferFav
    //
    BOOL isPreferNotice = [Setting boolForKey:HPSettingPreferNotice];
    REBoolItem *isPreferNoticeItem = [REBoolItem itemWithTitle:@"常用加关注" value:isPreferNotice switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"HPSettingPreferNotice Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingPreferNotice];
        
        [Flurry logEvent:@"Setting TogglePreferNotice" withParameters:@{@"flag":@(item.value)}];
    }];
    
    // 发送后提示
    //
    __typeof (&*self) __weak weakSelf = self;
    BOOL isShowConfirm = [Setting boolForKey:HPSettingAfterSendShowConfirm];
    BOOL isAutoJump = [Setting boolForKey:HPSettingAfterSendJump];
    NSArray *options = @[@"跳转到刚发的回帖", @"留在原处", @"每次都询问"];
    NSInteger i = isShowConfirm?2:(isAutoJump?0:1);
    RERadioItem *afterSendConfirmItem = [RERadioItem itemWithTitle:@"回帖成功后" value:options[i] selectionHandler:^(RERadioItem *item) {
        
        [item deselectRowAnimated:YES];
        
        // Present options controller
        //
        RETableViewOptionsController *optionsController = [[RETableViewOptionsController alloc] initWithItem:item options:options multipleChoice:NO completionHandler:^(RETableViewItem *vi) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            
            [item reloadRowWithAnimation:UITableViewRowAnimationNone];
            
            NSInteger i = [options indexOfObject:item.value];
            switch (i) {
                case 0:
                case 1:
                    [Setting saveBool:!((BOOL)i) forKey:HPSettingAfterSendJump];
                    [Setting saveBool:NO forKey:HPSettingAfterSendShowConfirm];
                    break;
                case 2:
                    [Setting saveBool:YES forKey:HPSettingAfterSendShowConfirm];
                    break;
                default:
                    break;
            }
            
            [Flurry logEvent:@"Setting SetAfterSendConfirm" withParameters:@{@"option":@(i)}];
        }];
        
        optionsController.delegate = weakSelf;
        optionsController.style = section.style;
        if (weakSelf.tableView.backgroundView == nil) {
            optionsController.tableView.backgroundColor = weakSelf.tableView.backgroundColor;
            optionsController.tableView.backgroundView = nil;
        }
        
        [weakSelf.navigationController pushViewController:optionsController animated:YES];
    }];
    
    // 上拉回复
    //
    BOOL isPullReply = [Setting boolForKey:HPSettingIsPullReply];
    REBoolItem *isPullReplyItem = [REBoolItem itemWithTitle:@"上拉回复" value:isPullReply switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"isPullReply Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingIsPullReply];
        
        [Flurry logEvent:@"Setting TogglePullReply" withParameters:@{@"flag":@(item.value)}];
    }];
    
    // 拖动返回
    //
    BOOL isSwipeBack = [Setting boolForKey:HPSettingSwipeBack];
    REBoolItem *isSwipeBackItem = [REBoolItem itemWithTitle:@"看帖全屏拖动返回(谨慎开启)" value:isSwipeBack switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"isSwipeBack Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingSwipeBack];
        
        [Flurry logEvent:@"Setting ToggleSwipeBack" withParameters:@{@"flag":@(item.value)}];
    }];
    
    
    //
    //
    RETableViewItem *setStupidBarItem = [RETableViewItem itemWithTitle:@"StupidBar" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        @strongify(self);
        HPSetStupidBarController *svc = [HPSetStupidBarController new];
        [self.navigationController pushViewController:svc animated:YES];
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting EnterStupidBar"];
    }];
    
    RERadioItem *nodeItem = [RERadioItem itemWithTitle:@"节点" value:HPBaseURL selectionHandler:^(RERadioItem *item) {
        
        [item deselectRowAnimated:YES];
        
        NSArray *nodeNames = @[
            [NSString stringWithFormat:@"%@ (电信)", HP_WWW_BASE_URL],
            [NSString stringWithFormat:@"%@ (联通)", HP_CNC_BASE_URL],
            [NSString stringWithFormat:@"%@ (电信, 强制指向)", HP_WWW_BASE_IP],
            [NSString stringWithFormat:@"%@ (联通, 强制指向)", HP_CNC_BASE_IP]
        ];
        
        NSArray *nodes = @[
            HP_WWW_BASE_URL,
            HP_CNC_BASE_URL,
            HP_WWW_BASE_URL,
            HP_CNC_BASE_URL
        ];
        
        // Present options controller
        //
        RETableViewOptionsController *optionsController = [[RETableViewOptionsController alloc] initWithItem:item options:nodeNames multipleChoice:NO completionHandler:^(RETableViewItem *vi) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            
            [item reloadRowWithAnimation:UITableViewRowAnimationNone];
            
            NSUInteger index = [nodeNames indexOfObject:item.value];
            NSString *node = [nodes objectAtIndex:index];
            [Setting saveObject:node forKey:HPSettingBaseURL];
            [Setting saveBool:index > 1 forKey:HPSettingForceDNS];
            [HPURLProtocol registerURLProtocolIfNeed];
            
            [Flurry logEvent:@"Setting Node" withParameters:@{@"option":item.value}];
            
            [UIAlertView showWithTitle:@"注意" message:@"需要重新启动后完全生效" handler:nil];
        }];
        
        optionsController.delegate = weakSelf;
        optionsController.style = section.style;
        if (weakSelf.tableView.backgroundView == nil) {
            optionsController.tableView.backgroundColor = weakSelf.tableView.backgroundColor;
            optionsController.tableView.backgroundView = nil;
        }
        
        [weakSelf.navigationController pushViewController:optionsController animated:YES];
    }];
    
    
    [section addItem:isNightModeItem];
    [section addItem:isShowAvatarItem];
    [section addItem:postTailText];
    [section addItem:setForumItem];
    [section addItem:blockListItem];
    [section addItem:isPreferNoticeItem];
    [section addItem:afterSendConfirmItem];
    [section addItem:isPullReplyItem];
    [section addItem:isSwipeBackItem];
    [section addItem:setStupidBarItem];
    [section addItem:nodeItem];
    
    [_manager addSection:section];
    return section;
}


- (RETableViewSection *) addImageControls {
    
    __typeof (&*self) __weak weakSelf = self;
    
    //RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Image load"];
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:nil];
    
    
    RETableViewItem *setImageSizeFilterItem = [RETableViewItem itemWithTitle:@"图片加载设置" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        
        HPSetImageSizeFilterViewController *svc = [HPSetImageSizeFilterViewController new];
        [weakSelf.navigationController pushViewController:svc animated:YES];
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting ImageSizeFilter"];
    }];
    [section addItem:setImageSizeFilterItem];
    
        
    RETableViewItem *cleanItem = [RETableViewItem itemWithTitle:@"清理缓存" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        [item deselectRowAnimated:YES];
        
        [SVProgressHUD showWithStatus:@"清理中" maskType:SVProgressHUDMaskTypeBlack];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[SDImageCache sharedImageCache] clearMemory];
            [[SDImageCache sharedImageCache] clearDisk];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"清理完成"];
            });
        });
    
        
        item.title = @"清理缓存";
        [item reloadRowWithAnimation:UITableViewRowAnimationAutomatic];
        
        [Flurry logEvent:@"Setting ClearCache"];
    }];
    
    
    [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        
        NSLog(@"%lu, %lu", fileCount, totalSize);
        //cleanItem.title = [NSString stringWithFormat:@"%d, %lld", fileCount, totalSize];
        cleanItem.title = [NSString stringWithFormat:@"清理缓存 %.1fm", totalSize/(1024.f*1024.f)];
        [cleanItem reloadRowWithAnimation:UITableViewRowAnimationAutomatic];
        
    }];
    
    [section addItem:cleanItem];
    
    
    CGFloat lastMinite = [Setting floatForKey:HPSettingBGLastMinite];
    RERadioItem *lastMiniteItem = [RERadioItem itemWithTitle:@"待读内容保存时间" value:[NSString stringWithFormat:@"%d分钟", (int)lastMinite] selectionHandler:^(RERadioItem *item) {
        [item deselectRowAnimated:YES];
        
        NSArray *options = @[@"10分钟", @"20分钟", @"30分钟",
                             @"1小时",@"3小时",
                             @"一天", @"三天",
                             @"永远"];
        
        // Present options controller
        //
        RETableViewOptionsController *optionsController = [[RETableViewOptionsController alloc] initWithItem:item options:options multipleChoice:NO completionHandler:^(RETableViewItem *vi) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            
            float lastMinite = 10;
            NSUInteger i = [options indexOfObject:item.value];
            
            switch (i) {
                case 0:case 1:case 2:
                    lastMinite = 10 * (i+1); break;
                case 3: lastMinite = 60; break;
                case 4: lastMinite = 60 * 3; break;
                case 5: lastMinite = 60 * 24; break;
                case 6: lastMinite = 60 * 3 * 24; break;
                case 7: lastMinite = 24 * 24 * 24; break;
                default:
                    lastMinite = 20;
                    break;
            }
            NSLog(@"%f", lastMinite);
            [Setting saveFloat:lastMinite forKey:HPSettingBGLastMinite];
            
            [item reloadRowWithAnimation:UITableViewRowAnimationNone];
            
            [Flurry logEvent:@"Setting SetLastMinite" withParameters:@{@"minite":@(lastMinite)}];
        }];
        
        // Adjust styles
        //
        optionsController.delegate = weakSelf;
        optionsController.style = section.style;
        if (weakSelf.tableView.backgroundView == nil) {
            optionsController.tableView.backgroundColor = weakSelf.tableView.backgroundColor;
            optionsController.tableView.backgroundView = nil;
        }
        
        // Push the options controller
        //
        [weakSelf.navigationController pushViewController:optionsController animated:YES];
    }];
    
    [section addItem:lastMiniteItem];
    
    [_manager addSection:section];
    return section;
}

- (RETableViewSection *)addDataTrackingControls {
    
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@" " footerTitle:nil];
    
    //
    BOOL dataTrackingEnable = [Setting boolForKey:HPSettingDataTrackEnable];
    REBoolItem *dataTrackingEnableItem = [REBoolItem itemWithTitle:@"使用行为统计" value:dataTrackingEnable switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"dataTrackingEnable %@", item.value ? @"YES" : @"NO");
        
        if (item.value == NO) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"o(>﹏<)o不要关啊"
                                  message:@"这个会统计一些使用行为, 以帮助俺改进App, 比如读帖子时哪些按钮使用频繁俺就会根据统计放到更显眼的位置"
                                  delegate:nil
                                  cancelButtonTitle:@"关关关"
                                  otherButtonTitles:@"算了", nil];
            [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    item.value = YES;
                    [item reloadRowWithAnimation:UITableViewRowAnimationNone];
                    [Flurry logEvent:@"Setting DataTracking" withParameters:@{@"action":@"StopClose"}];
                } else {
                    [Setting saveBool:item.value forKey:HPSettingDataTrackEnable];
                    [Flurry logEvent:@"Setting DataTracking" withParameters:@{@"action":@"StillClose"}];
                }
            }];
        } else {
            [Setting saveBool:item.value forKey:HPSettingDataTrackEnable];
            [Flurry logEvent:@"Setting DataTracking" withParameters:@{@"action":@"Open"}];
        }
        
    }];
    
    //
    BOOL bugTrackingEnable = [Setting boolForKey:HPSettingBugTrackEnable];
    REBoolItem *bugTrackingEnableItem = [REBoolItem itemWithTitle:@"错误信息收集" value:bugTrackingEnable switchValueChangeHandler:^(REBoolItem *item) {
        
        NSLog(@"bugTrackingEnable %@", item.value ? @"YES" : @"NO");
        
        if (item.value == NO) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"o(>﹏<)o不要关啊"
                                  message:@"这个会发送App错误报告给俺\n帮助俺定位各种bug"
                                   delegate:nil
                                   cancelButtonTitle:@"关关关"
                                   otherButtonTitles:@"算了", nil];
            [alert showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    item.value = YES;
                    [item reloadRowWithAnimation:UITableViewRowAnimationNone];
                    [Flurry logEvent:@"Setting BugTracking" withParameters:@{@"action":@"StopClose"}];
                } else {
                    [Setting saveBool:item.value forKey:HPSettingBugTrackEnable];
                    [Flurry logEvent:@"Setting BugTracking" withParameters:@{@"action":@"StillClose"}];
                }
            }];
        } else {
            [Setting saveBool:item.value forKey:HPSettingBugTrackEnable];
            [Flurry logEvent:@"Setting BugTracking" withParameters:@{@"action":@"Open"}];
        }
    }];
    
    // isForceLogin
    //
    BOOL isForceLogin = [Setting boolForKey:HPSettingForceLogin];
    REBoolItem *isForceLoginItem = [REBoolItem itemWithTitle:@"强制登录 (无法登录时可打开)" value:isForceLogin switchValueChangeHandler:^(REBoolItem *item) {
        NSLog(@"isForceLoginItem Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingForceLogin];
        
        [Flurry logEvent:@"Setting ToggleForceLogin" withParameters:@{@"flag":@(item.value)}];
    }];
    
    // 模拟XHR强力绕过广告
    //
    BOOL isEnableXHR = [Setting boolForKey:HPSettingEnableXHR];
    REBoolItem *isEnableXHRItem = [REBoolItem itemWithTitle:@"强力绕过运营商劫持" value:isEnableXHR switchValueChangeHandler:^(REBoolItem *item) {
        NSLog(@"isEnableXHRItem Value: %@", item.value ? @"YES" : @"NO");
        [Setting saveBool:item.value forKey:HPSettingEnableXHR];
        
        [Flurry logEvent:@"Setting ToggleEnableXHR" withParameters:@{@"flag":@(item.value)}];
    }];
    
    [section addItem:dataTrackingEnableItem];
    [section addItem:bugTrackingEnableItem];
    [section addItem:isForceLoginItem];
    [section addItem:isEnableXHRItem];
    
    [_manager addSection:section];
    return section;
}


- (RETableViewSection *)addAboutControls
{
    //RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"About"];
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"  " footerTitle:nil];
    
    // 致谢
    //
    @weakify(self);
    RETableViewItem *aboutItem = [RETableViewItem itemWithTitle:@"致谢" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        [item deselectRowAnimated:YES];
        @strongify(self);
        UIWebView *webView=[[UIWebView alloc]initWithFrame:self.view.frame];
        webView.delegate = self;
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"acknowledgement" withExtension:@"html"];
        
        [webView loadRequest:[NSURLRequest requestWithURL:url]];
        
        UIViewController *webViewController = [[UIViewController alloc] init];
        [webViewController.view addSubview: webView];
        
        webViewController.title = @"致谢";
        [self.navigationController pushViewController:webViewController animated:YES];
        
        [Flurry logEvent:@"Setting EnterAcknowledgement"];
    }];

    
    // Bug & 建议
    //
    RETableViewItem *reportItem = [RETableViewItem itemWithTitle:@"联系作者" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        [item deselectRowAnimated:YES];
        @strongify(self);
        // 获得设备信息
        //
        /*!
         *  get the information of the device and system
         *  "i386"          simulator
         *  "iPod1,1"       iPod Touch
         *  "iPhone1,1"     iPhone
         *  "iPhone1,2"     iPhone 3G
         *  "iPhone2,1"     iPhone 3GS
         *  "iPad1,1"       iPad
         *  "iPhone3,1"     iPhone 4
         *  @return null
         */
        struct utsname systemInfo;
        uname(&systemInfo);
        //get the device model and the system version
        NSString *device_model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        NSString *system_version = [[UIDevice currentDevice] systemVersion];
        NSLog(@"device_model %@, system_version %@", device_model, system_version);
        
        
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setToRecipients:@[@"wujichao.hpclient@gmail.com"]];
        [controller setSubject:@"HP论坛客户端反馈: "];
        [controller setMessageBody:[NSString stringWithFormat:@"\n\n\n网络(eg:移动2g): \n设备: %@ \niOS版本: %@ \n客户端版本: v%@", device_model, system_version, VERSION] isHTML:NO];
        if (controller) [self presentViewController:controller animated:YES completion:NULL];
    }];
    

    
    //
    //
    RETableViewItem *replyItem = [RETableViewItem itemWithTitle:@"回帖建议" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        @strongify(self);
        
        HPThread *thread = [HPThread new];
        thread.fid = 2;
        thread.tid = 1272557;
        thread.title = @"D版 iOS 客户端";
    
        HPReadViewController *rvc = [[HPReadViewController alloc] initWithThread:thread];
        [self.navigationController pushViewController:rvc animated:YES];
        
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting EnterAdvice"];
    }];
    
    //
    //
    RETableViewItem *githubItem = [RETableViewItem itemWithTitle:@"github/hipda_ios_client_v3" accessoryType:UITableViewCellAccessoryDisclosureIndicator selectionHandler:^(RETableViewItem *item) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/wujichao/hipda_ios_client_v3"]];
        
        [item deselectRowAnimated:YES];
        
        [Flurry logEvent:@"Setting EnterGithub"];
    }];
   
    
    
    [section addItem:reportItem];
    [section addItem:replyItem];
    [section addItem:aboutItem];
    [section addItem:githubItem];
    
    [_manager addSection:section];
    return section;
}

#pragma mark -

- (void)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[HPRearViewController sharedRearVC] forumDidChanged];
    }];
}

- (void)closeAndShowLoginVC {
    [self dismissViewControllerAnimated:YES completion:^{
        // 板块列表复原
        [[HPRearViewController sharedRearVC] forumDidChanged];
        // 换到帖子列表
        [[HPRearViewController sharedRearVC] switchToThreadVC];
        // 关闭侧边栏
        HPAppDelegate *d = [[UIApplication sharedApplication] delegate];
        [d.viewController revealToggle:d];
        // 弹出登录, 登录好了会刷新帖子列表
        HPLoginViewController *loginvc = [[HPLoginViewController alloc] init];
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:[HPCommon NVCWithRootVC:loginvc] animated:YES completion:^{}];
    }];
}


- (void)reset:(id)sender
{
    @weakify(self);
    [UIAlertView showConfirmationDialogWithTitle:@"重置设置"
                                         message:@"您确定要重置所有设置吗?"
                                         handler:^(UIAlertView *alertView, NSInteger buttonIndex)
     {
         @strongify(self);
         BOOL confirm = (buttonIndex != [alertView cancelButtonIndex]);
         if (confirm) {
             [Setting loadDefaults];
             [SVProgressHUD showSuccessWithStatus:@"设置已重置"];
             
             [self close:nil];
         }
         
         [Flurry logEvent:@"Setting Reset" withParameters:@{@"confirm":@(confirm)}];
     }];
}

#pragma mark mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"sent");
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [Flurry logEvent:@"Setting ContactAuthor" withParameters:@{@"result":@(result)}];
}

#pragma mark webView delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked &&
        [request.URL.scheme hasPrefix:@"http"]) {
        
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    NSLog(@"%@, %ld", request, navigationType);
    
    return YES;
}


@end
