//
//  MasterViewController.m
//  Getter
//
//  Created by 大坪裕樹 on 2013/10/22.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

//#import "MasterViewController.h"
#import "DetailViewController.h"
#import "TweetViewController.h"
#import "ProfileViewController.h"

@interface MasterViewController : UITableViewController <UIAlertViewDelegate, TweetViewControllerDelegate>
{
    UIImage *profileImage;
    UIImage *bannerImage;
}
@property (nonatomic, retain) UIImage *profileImage;
@property (nonatomic, retain) UIImage *bannerImage;
@end



#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"

@implementation MasterViewController {
    // OAuth認証オブジェクト
    GTMOAuthAuthentication *auth_;
    // 表示中ツイート情報
    NSArray *timelineStatuses_;
    NSArray *timelineStatuses2_;
    
    NSDictionary *user;
    NSDictionary *user2;
}

@synthesize profileImage;
@synthesize bannerImage;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

// KeyChain登録サービス名
static NSString *const kKeychainAppServiceName = @"KodawariButter";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // GTMOAuthAuthenticationインスタンス生成
    // ※自分の登録アプリの Consumer Key と Consumer Secret に書き換えてください
    NSString *consumerKey = @"AlYNIai1ijrgUUmlbfaxg";
    NSString *consumerSecret = @"DeUNpwTEhn0FpuoRQKAwLF7O1dzjvgWEpT2zZhrPc";
    auth_ = [[GTMOAuthAuthentication alloc]
             initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
             consumerKey:consumerKey
             privateKey:consumerSecret];
    
    // 既にOAuth認証済みであればKeyChainから認証情報を読み込む
    BOOL authorized = [GTMOAuthViewControllerTouch
                       authorizeFromKeychainForName:kKeychainAppServiceName
                       authentication:auth_];
    if (authorized) {
        // 認証済みの場合はタイムライン更新
        [self asyncShowHomeTimeline];
    } else {
        // 未認証の場合は認証処理を実施
        [self asyncSignIn];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 認証処理
- (void)asyncSignIn
{
    NSString *requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    NSString *accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    NSString *authorizeURL = @"https://api.twitter.com/oauth/authorize";
    
    NSString *keychainAppServiceName = @"KodawariButter";
    
    auth_.serviceProvider = @"Twitter";
    auth_.callback = @"http://www.example.com/OAuthCallback";
    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[GTMOAuthViewControllerTouch alloc]
                      initWithScope:nil
                      language:nil
                      requestTokenURL:[NSURL URLWithString:requestTokenURL]
                      authorizeTokenURL:[NSURL URLWithString:authorizeURL]
                      accessTokenURL:[NSURL URLWithString:accessTokenURL]
                      authentication:auth_
                      appServiceName:keychainAppServiceName
                      delegate:self
                      finishedSelector:@selector(authViewContoller:finishWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

// 認証エラー表示AlertViewタグ
static const int kMyAlertViewTagAuthenticationError = 1;

// 認証処理が完了した場合の処理
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    if (error != nil) {
        // 認証失敗
        NSLog(@"Authentication error: %d.", error.code);
        UIAlertView *alertView;
        alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Authentication failed."
                                              delegate:self
                                     cancelButtonTitle:@"Confirm"
                                     otherButtonTitles:nil];
        alertView.tag = kMyAlertViewTagAuthenticationError;
        [alertView show];
    } else {
        // 認証成功
        NSLog(@"Authentication succeeded.");
        // タイムライン表示
        [self asyncShowHomeTimeline];
    }
}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 再度認証
        [self asyncSignIn];
    }
}

// デフォルトのタイムライン処理表示
- (void)asyncShowHomeTimeline
{
    //[self fetchGetHomeTimeline];
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

// タイムライン (home_timeline) 取得
- (void)fetchGetHomeTimeline:(NSURL *)url timeLine:(NSString *)tl
{
    // 要求を準備
    //NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 非同期通信による取得開始
    if([tl  isEqual: @"tl01"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl02"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher02:finishedWithData:error:)];
    }
}

// タイムライン (home_timeline) 取得応答時
- (void)homeTimelineFetcher:(GTMHTTPFetcher *)fetcher
           finishedWithData:(NSData *)data
                      error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (statuses == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    timelineStatuses_ = statuses;
    
    // テーブルを更新
    [self.tableView reloadData];
}
    
- (void)homeTimelineFetcher02:(GTMHTTPFetcher *)fetcher
finishedWithData:(NSData *)data
error:(NSError *)error
    {
        if (error != nil) {
            // タイムライン取得時エラー
            NSLog(@"Fetching status/home_timeline error: %d", error.code);
            return;
        }
        
        // タイムライン取得成功
        // JSONデータをパース
        NSError *jsonError = nil;
        NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&jsonError];
        
        // JSONデータのパースエラー
        if (statuses == nil) {
            NSLog(@"JSON Parser error: %d", jsonError.code);
            return;
        }
        
        // データを保持
        timelineStatuses2_ = statuses;
    }

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [timelineStatuses_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文を表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.text = [status objectForKey:@"text"];
    
    
    // ユーザ情報から screen_name を取り出して表示
    //NSDictionary *user = [status objectForKey:@"user"];
    user = [status objectForKey:@"user"];
    cell.detailTextLabel.text = [user objectForKey:@"screen_name"];
    NSURL *url = [NSURL URLWithString:[user objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    cell.imageView.image = [UIImage imageWithData:Tweetdata];
    
    NSLog(@"%@ - %@", [status objectForKey:@"text"], [[status objectForKey:@"user"] objectForKey:@"screen_name"]);
    
    return cell;
}


// 指定位置の行で使用する高さの要求
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文をもとにセルの高さを決定
    NSString *content = [status objectForKey:@"text"];
    CGSize labelSize = [content sizeWithFont:[UIFont systemFontOfSize:12]
                           constrainedToSize:CGSizeMake(300, 1000)
                               lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 25;
}

//セルを選択したときにscreen_nameを特定する。
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //特定した人のタイムラインだけを「NSDictionary *title」にいれる。
    NSDictionary *title = [timelineStatuses_ objectAtIndex:indexPath.row];
    //titleの中身を表示
    NSLog (@"start-----------------------------------------------------------------");
    NSLog(@"%@",title);
    NSLog (@"end-------------------------------------------------------------------");
    //titleから「user」の構造だけをぬきとる。
    user2 = [title objectForKey:@"user"];
    //プロフィール画像用。
    NSURL *url = [NSURL URLWithString:[user2 objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    profileImage = [UIImage imageWithData:Tweetdata];
    
    NSURL *url2 = [NSURL URLWithString:[user2 objectForKey:@"profile_banner_url"]];
    NSData *Tweetdata2 = [NSData dataWithContentsOfURL:url2];
    bannerImage = [UIImage imageWithData:Tweetdata2];
    
    NSString *scname = [user2 objectForKey:@"screen_name"];
    NSString *str_cid = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=%@",scname];
    NSURL *url02 = [NSURL URLWithString:[str_cid stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl02 = @"tl02";
    [self fetchGetHomeTimeline:url02 timeLine:tl02];
    
}

// ツイート投稿要求
- (void)fetchPostTweet:(NSString *)text
{
    // 要求を準備
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // statusパラメータをURI符号化してbodyにセット
    NSString *encodedText = [GTMOAuthAuthentication encodedOAuthParameterForString:text];
    NSString *body = [NSString stringWithFormat:@"status=%@", encodedText];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 接続開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(postTweetFetcher:finishedWithData:error:)];
}

// ツイート投稿要求に対する応答
- (void)postTweetFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if (error != nil) {
        // ツイート投稿取得エラー
        NSLog(@"Fetching statuses/update error: %d", error.code);
        return;
    }
    
    // タイムライン更新
    //[self fetchGetHomeTimeline];
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTweetView"]) {
        [segue.destinationViewController setDelegate:self];
    }else if ([[segue identifier] isEqualToString:@"reply"]) {
        [segue.destinationViewController setDelegate:self];
        
        TweetViewController *tweetViewController = (TweetViewController*)[segue destinationViewController];
        tweetViewController.username = [user2 objectForKey:@"screen_name"];

    }else if ([[segue identifier] isEqualToString:@"showProfileView"]) {
        
        ProfileViewController *profileViewController = (ProfileViewController*)[segue destinationViewController];
        
        profileViewController.username = [user2 objectForKey:@"screen_name"];
        profileViewController.name = [user2 objectForKey:@"name"];
        [profileViewController setProf:self.profileImage];
        profileViewController.tweets = [user2 objectForKey:@"statuses_count"];
        profileViewController.following = [user2 objectForKey:@"friends_count"];
        profileViewController.followers = [user2 objectForKey:@"followers_count"];
        [profileViewController setBann:self.bannerImage];
        
        profileViewController.timeline =  timelineStatuses2_;
    }
}

// TweetViewでCancelが押された
- (void)tweetViewControllerDidCancel:(TweetViewController *)viewController
{
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
}

// TweetViewでDoneが押された
-(void)tweetViewControllerDidFinish:(TweetViewController *)viewController
                            content:(NSString *)content
{
    // ツイートを投稿する
    if ([content length] > 0) {
        [self fetchPostTweet:content];
    }
    
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
    
}




/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



@end
