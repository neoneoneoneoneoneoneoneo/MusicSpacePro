#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#include <dlfcn.h>

// =========================================================
// 🎵 MediaRemote (強制ダイナミックロード版)
// =========================================================
#define MR_TOGGLE_PLAY_PAUSE 2
#define MR_PAUSE 1

void SendMRCommand(int command) {
    void *mr = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    if (mr) {
        Boolean (*MRSendCommand)(int, id) = dlsym(mr, "MRMediaRemoteSendCommand");
        if (MRSendCommand) {
            MRSendCommand(command, nil);
        }
    }
}

@class MyMainContainerViewController;

// =========================================================
// 1. 各画面のクラス宣言
// =========================================================

@interface MySettingsViewController : UIViewController
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *generalView;
@property (nonatomic, strong) UIView *localFilesView;
@end

@interface MySidebarViewController : UIViewController
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@end

@interface MyHomeViewController : UIViewController
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@end

@interface MySearchViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *searchResults;
@end

@interface MyLibraryViewController : UIViewController
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@end

@interface MyDJPlayerViewController : UIViewController <UIDocumentPickerDelegate, AVAudioPlayerDelegate>
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@property (nonatomic, strong) UILabel *labelL, *labelR;
@property (nonatomic, strong) UIButton *playBtnL, *playBtnR;
@property (nonatomic, strong) UISlider *crossFader;
@property (nonatomic, strong) AVAudioPlayer *audioPlayerL;
@property (nonatomic, strong) AVAudioPlayer *audioPlayerR;
@property (nonatomic, strong) NSString *currentSelectingChannel;
@end

@interface MySpotifyCloneTabBarController : UITabBarController
@property (nonatomic, assign) MyMainContainerViewController *containerVC;
@property (nonatomic, strong) UIView *miniPlayerView;
@property (nonatomic, strong) UILabel *miniPlayerTitle;
@property (nonatomic, strong) UIButton *miniPlayerPlayBtn;
@end

@interface MyMainContainerViewController : UIViewController
@property (nonatomic, strong) MySidebarViewController *sidebarVC;
@property (nonatomic, strong) MySpotifyCloneTabBarController *tabBarVC;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, assign) BOOL isSidebarOpen;
- (void)toggleSidebar;
- (void)openSettingsScreen;
@end

@interface UIViewController (CustomHeader)
- (void)addCustomHeaderWithTitle:(NSString *)title container:(MyMainContainerViewController *)container;
@end

@implementation UIViewController (CustomHeader)
- (void)addCustomHeaderWithTitle:(NSString *)title container:(MyMainContainerViewController *)container {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    header.backgroundColor = [UIColor clearColor];

    UIButton *menuBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    menuBtn.frame = CGRectMake(15, 55, 40, 40);
    [menuBtn setImage:[UIImage systemImageNamed:@"line.3.horizontal"] forState:UIControlStateNormal];
    menuBtn.tintColor = [UIColor whiteColor];
    [menuBtn addTarget:container action:@selector(toggleSidebar) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:menuBtn];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(60, 55, self.view.bounds.size.width-120, 40)];
    lbl.text = title; lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold]; lbl.textAlignment = NSTextAlignmentCenter;
    [header addSubview:lbl];
    [self.view addSubview:header];
}
@end

// =========================================================
// 2. 実装部分
// =========================================================

@implementation MySettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    self.title = @"設定";

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"一般", @"ローカルファイル"]];
    self.segmentedControl.frame = CGRectMake(20, 110, self.view.bounds.size.width - 40, 32);
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.selectedSegmentTintColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0];
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];

    self.generalView = [[UIView alloc] initWithFrame:CGRectMake(0, 160, self.view.bounds.size.width, 400)];
    [self setupGeneralUI]; [self.view addSubview:self.generalView];

    self.localFilesView = [[UIView alloc] initWithFrame:self.generalView.frame];
    [self setupLocalUI]; self.localFilesView.hidden = YES; [self.view addSubview:self.localFilesView];
}
- (void)setupGeneralUI {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
    lbl.text = @"ダークモード（固定）"; lbl.textColor = [UIColor whiteColor]; [self.generalView addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 20, 50, 30)];
    sw.onTintColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"MSP_DarkMode_Enabled"];
    [sw addTarget:self action:@selector(darkModeSwitched:) forControlEvents:UIControlEventValueChanged];
    [self.generalView addSubview:sw];
}
- (void)setupLocalUI {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
    lbl.text = @"デフォルトクロスフェード"; lbl.textColor = [UIColor whiteColor]; [self.localFilesView addSubview:lbl];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 60, self.view.bounds.size.width - 40, 30)];
    slider.minimumTrackTintColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0];
    float savedVal = [[NSUserDefaults standardUserDefaults] floatForKey:@"MSP_Crossfade_Value"];
    slider.value = (savedVal == 0.0f) ? 0.5f : savedVal;
    [slider addTarget:self action:@selector(crossfadeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.localFilesView addSubview:slider];
}
- (void)darkModeSwitched:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"MSP_DarkMode_Enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)crossfadeSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"MSP_Crossfade_Value"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)segmentChanged:(UISegmentedControl *)sender {
    self.generalView.hidden = (sender.selectedSegmentIndex != 0);
    self.localFilesView.hidden = (sender.selectedSegmentIndex == 0);
}
@end

@implementation MySidebarViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.1 alpha:1.0];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(25, 70, 200, 30)];
    title.text = @"Music Space Pro"; title.textColor = [UIColor whiteColor]; title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
    [self.view addSubview:title];

    [self addSidebarTabWithTitle:@"再生中の曲" icon:@"music.note" y:150 action:nil];
    [self addSidebarTabWithTitle:@"設定" icon:@"gearshape.fill" y:215 action:@selector(settingsTapped)];
}
- (void)addSidebarTabWithTitle:(NSString *)title icon:(NSString *)iconName y:(CGFloat)y action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(15, y, 250, 55);
    btn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    btn.layer.cornerRadius = 12; btn.tintColor = [UIColor whiteColor];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.imageEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0); btn.titleEdgeInsets = UIEdgeInsetsMake(0, 25, 0, 0);
    [btn setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    if (action) [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)settingsTapped { [self.containerVC openSettingsScreen]; }
@end

@implementation MyHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    [self addCustomHeaderWithTitle:@"ホーム" container:self.containerVC];

    UILabel *welcome = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 300, 30)];
    welcome.text = @"あなたへのおすすめ"; welcome.textColor = [UIColor whiteColor]; welcome.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [self.view addSubview:welcome];

    // 今はまだ空のカードですが、ここに将来APIから取ったデータが入ります
    for (int i=0; i<4; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(20 + (i%2)*170, 160 + (i/2)*180, 160, 170)];
        card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05]; card.layer.cornerRadius = 8;
        [self.view addSubview:card];
    }
}
@end

@implementation MySearchViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    self.searchResults = [NSMutableArray array];
    [self addCustomHeaderWithTitle:@"音楽検索" container:self.containerVC];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(10, 100, self.view.bounds.size.width-20, 50)];
    self.searchBar.delegate = self; self.searchBar.placeholder = @"曲名、アーティスト...";
    self.searchBar.barTintColor = self.view.backgroundColor; self.searchBar.searchTextField.textColor = [UIColor whiteColor];
    [self.view addSubview:self.searchBar];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 150, self.view.bounds.size.width, self.view.bounds.size.height-240)];
    self.tableView.backgroundColor = [UIColor clearColor]; self.tableView.dataSource = self; self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    NSString *query = searchBar.text;
    if (!query || query.length == 0) return;
    
    // 🌐 外部APIを使って本物の曲データを取得してリストに表示する
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@&entity=song&country=jp&limit=30", encodedQuery]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *results = json[@"results"];
            NSMutableArray *newResults = [NSMutableArray array];
            for (NSDictionary *item in results) {
                NSString *title = item[@"trackName"];
                NSString *artist = item[@"artistName"];
                if (title && artist) [newResults addObject:@{@"title": title, @"artist": artist}];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchResults = newResults;
                [self.tableView reloadData];
            });
        }
    }];
    [task resume];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.searchResults.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"c"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"c"];
        c.backgroundColor = [UIColor clearColor]; c.textLabel.textColor = [UIColor whiteColor]; 
        c.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        c.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    NSDictionary *item = self.searchResults[indexPath.row];
    c.textLabel.text = item[@"title"]; c.detailTextLabel.text = item[@"artist"];
    return c;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = self.searchResults[indexPath.row];
    NSString *title = item[@"title"];
    NSString *artist = item[@"artist"];
    
    // 🎵 ミニプレイヤーの表示を更新！
    NSString *displayString = [NSString stringWithFormat:@"%@ - %@", title, artist];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MSP_TrackChanged" object:displayString];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MSP_StateChanged" object:@(YES)];
    
    // 🔗 裏にいる本物のYouTube Musicに見えない命令（検索コマンド）を送る
    NSString *searchQuery = [NSString stringWithFormat:@"%@ %@", title, artist];
    NSString *encodedQuery = [searchQuery stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *ytmURL = [NSURL URLWithString:[NSString stringWithFormat:@"youtubemusic://search?q=%@", encodedQuery]];
    [[UIApplication sharedApplication] openURL:ytmURL options:@{} completionHandler:nil];
    
    NSLog(@"Music Space Pro: Sent command to background YTM: %@", searchQuery);
}
@end

@implementation MyLibraryViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    [self addCustomHeaderWithTitle:@"マイライブラリ" container:self.containerVC];

    NSArray *chips = @[@"プレイリスト", @"ローカル曲", @"お気に入り"];
    for (int i=0; i<chips.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(15 + i*110, 110, 100, 32); btn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        btn.layer.cornerRadius = 16; btn.tintColor = [UIColor whiteColor];
        [btn setTitle:chips[i] forState:UIControlStateNormal]; btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [self.view addSubview:btn];
    }
}
@end

@implementation MyDJPlayerViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
    [self addCustomHeaderWithTitle:@"DJ Player" container:self.containerVC];

    CGFloat w = (self.view.bounds.size.width / 2) - 20;
    for (int i=0; i<2; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(12 + i*(w+16), 120, w, 320)];
        card.backgroundColor = (i == 0) ? [UIColor colorWithRed:0.08 green:0.12 blue:0.2 alpha:1.0] : [UIColor colorWithRed:0.2 green:0.08 blue:0.12 alpha:1.0];
        card.layer.cornerRadius = 12; [self.view addSubview:card];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, w-20, 40)];
        lbl.text = @"ローカル曲未選択"; lbl.textColor = [UIColor lightGrayColor]; lbl.font = [UIFont systemFontOfSize:11]; lbl.numberOfLines = 2; lbl.textAlignment = NSTextAlignmentCenter;
        [card addSubview:lbl];
        if(i==0) self.labelL = lbl; else self.labelR = lbl;

        UIButton *sel = [UIButton buttonWithType:UIButtonTypeSystem];
        sel.frame = CGRectMake(15, 80, w-30, 40);
        sel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        sel.layer.cornerRadius = 8;
        sel.tintColor = [UIColor whiteColor]; [sel setTitle:@"ファイル選択" forState:UIControlStateNormal];
        [sel addTarget:self action:(i==0 ? @selector(selL) : @selector(selR)) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:sel];

        UIButton *pBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        pBtn.frame = CGRectMake(15, 140, w-30, 50); pBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15]; pBtn.layer.cornerRadius = 25;
        pBtn.tintColor = [UIColor whiteColor]; [pBtn setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
        [pBtn addTarget:self action:(i==0 ? @selector(togglePlayL) : @selector(togglePlayR)) forControlEvents:UIControlEventTouchUpInside];
        pBtn.enabled = NO; [card addSubview:pBtn];
        if(i==0) self.playBtnL = pBtn; else self.playBtnR = pBtn;
    }

    self.crossFader = [[UISlider alloc] initWithFrame:CGRectMake(30, 500, self.view.bounds.size.width - 60, 40)];
    self.crossFader.minimumValue = 0.0f; self.crossFader.maximumValue = 1.0f; self.crossFader.value = 0.5f;
    self.crossFader.minimumTrackTintColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0];
    [self.crossFader addTarget:self action:@selector(faderMoved:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.crossFader];
}
- (void)selL { self.currentSelectingChannel = @"L"; [self openPicker]; }
- (void)selR { self.currentSelectingChannel = @"R"; [self openPicker]; }
- (void)openPicker {
    UIDocumentPickerViewController *p = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"] inMode:UIDocumentPickerModeImport];
    p.delegate = self; [self presentViewController:p animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject; if (!url) return;
    BOOL accessing = [url startAccessingSecurityScopedResource];
    
    if ([self.currentSelectingChannel isEqualToString:@"L"]) {
        self.labelL.text = url.lastPathComponent; self.audioPlayerL = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [self.audioPlayerL prepareToPlay]; self.playBtnL.enabled = YES;
    } else {
        self.labelR.text = url.lastPathComponent; self.audioPlayerR = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [self.audioPlayerR prepareToPlay]; self.playBtnR.enabled = YES;
    }
    [self updateVolumes];
    if (accessing) [url stopAccessingSecurityScopedResource];
}
- (void)togglePlayL {
    if (self.audioPlayerL.isPlaying) { 
        [self.audioPlayerL pause]; 
        [self.playBtnL setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal]; 
    } else { 
        SendMRCommand(MR_PAUSE); // YTを止める
        [self.audioPlayerL play]; 
        [self.playBtnL setImage:[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal]; 
    }
}
- (void)togglePlayR {
    if (self.audioPlayerR.isPlaying) { 
        [self.audioPlayerR pause]; 
        [self.playBtnR setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal]; 
    } else { 
        SendMRCommand(MR_PAUSE); // YTを止める
        [self.audioPlayerR play]; 
        [self.playBtnR setImage:[UIImage systemImageNamed:@"pause.fill"] forState:UIControlStateNormal]; 
    }
}
- (void)faderMoved:(UISlider *)sender { [self updateVolumes]; }
- (void)updateVolumes {
    if (self.audioPlayerL) self.audioPlayerL.volume = (1.0f - self.crossFader.value);
    if (self.audioPlayerR) self.audioPlayerR.volume = self.crossFader.value;
}
@end

@implementation MySpotifyCloneTabBarController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBar.barTintColor = [UIColor blackColor]; self.tabBar.tintColor = [UIColor colorWithRed:0.11 green:0.73 blue:0.33 alpha:1.0];

    MyHomeViewController *t1 = [[MyHomeViewController alloc] init]; t1.containerVC = self.containerVC;
    t1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"ホーム" image:[UIImage systemImageNamed:@"house.fill"] tag:0];

    MySearchViewController *t2 = [[MySearchViewController alloc] init]; t2.containerVC = self.containerVC;
    t2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"検索" image:[UIImage systemImageNamed:@"magnifyingglass"] tag:1];

    MyLibraryViewController *t3 = [[MyLibraryViewController alloc] init]; t3.containerVC = self.containerVC;
    t3.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"ライブラリ" image:[UIImage systemImageNamed:@"rectangle.stack.fill"] tag:2];

    MyDJPlayerViewController *t4 = [[MyDJPlayerViewController alloc] init]; t4.containerVC = self.containerVC;
    t4.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"DJ Player" image:[UIImage systemImageNamed:@"music.note.house.fill"] tag:3];

    self.viewControllers = @[t1, t2, t3, t4];
    [self setupMiniPlayer];
}
- (void)setupMiniPlayer {
    CGFloat tabBarHeight = self.tabBar.frame.size.height;
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat yPos = self.view.bounds.size.height - tabBarHeight - safeBottom - 65;

    self.miniPlayerView = [[UIView alloc] initWithFrame:CGRectMake(10, yPos, self.view.bounds.size.width - 20, 60)];
    self.miniPlayerView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.18 alpha:0.95];
    self.miniPlayerView.layer.cornerRadius = 8; self.miniPlayerView.hidden = YES;
    [self.view addSubview:self.miniPlayerView];

    UIImageView *art = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 40, 40)];
    art.backgroundColor = [UIColor darkGrayColor]; art.image = [UIImage systemImageNamed:@"music.note"];
    art.tintColor = [UIColor lightGrayColor]; art.layer.cornerRadius = 4;
    [self.miniPlayerView addSubview:art];

    self.miniPlayerTitle = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, self.miniPlayerView.bounds.size.width - 120, 40)];
    self.miniPlayerTitle.textColor = [UIColor whiteColor]; self.miniPlayerTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.miniPlayerView addSubview:self.miniPlayerTitle];

    self.miniPlayerPlayBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.miniPlayerPlayBtn.frame = CGRectMake(self.miniPlayerView.bounds.size.width - 50, 10, 40, 40);
    [self.miniPlayerPlayBtn setImage:[UIImage systemImageNamed:@"play.fill"] forState:UIControlStateNormal];
    self.miniPlayerPlayBtn.tintColor = [UIColor whiteColor];
    [self.miniPlayerPlayBtn addTarget:self action:@selector(miniPlayerPlayTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.miniPlayerView addSubview:self.miniPlayerPlayBtn];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackChanged:) name:@"MSP_TrackChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:@"MSP_StateChanged" object:nil];
}
- (void)trackChanged:(NSNotification *)n { self.miniPlayerTitle.text = n.object; self.miniPlayerView.hidden = NO; }
- (void)stateChanged:(NSNotification *)n {
    BOOL isPlaying = [n.object boolValue];
    [self.miniPlayerPlayBtn setImage:[UIImage systemImageNamed:isPlaying ? @"pause.fill" : @"play.fill"] forState:UIControlStateNormal];
}
- (void)miniPlayerPlayTapped {
    SendMRCommand(MR_TOGGLE_PLAY_PAUSE);
}
@end

@implementation MyMainContainerViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = [UIColor blackColor];

    self.sidebarVC = [[MySidebarViewController alloc] init]; self.sidebarVC.containerVC = self;
    self.sidebarVC.view.frame = CGRectMake(0, 0, 280, self.view.bounds.size.height);
    [self addChildViewController:self.sidebarVC]; [self.view addSubview:self.sidebarVC.view];

    self.contentContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.contentContainerView];

    self.tabBarVC = [[MySpotifyCloneTabBarController alloc] init]; self.tabBarVC.containerVC = self;
    self.tabBarVC.view.frame = self.contentContainerView.bounds;
    [self addChildViewController:self.tabBarVC]; [self.contentContainerView addSubview:self.tabBarVC.view];

    self.dimmingView = [[UIView alloc] initWithFrame:self.contentContainerView.bounds];
    self.dimmingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5]; self.dimmingView.alpha = 0.0;
    [self.dimmingView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSidebar)]];
    [self.contentContainerView addSubview:self.dimmingView];
}
- (void)toggleSidebar {
    self.isSidebarOpen = !self.isSidebarOpen;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.contentContainerView.frame; f.origin.x = self.isSidebarOpen ? 280 : 0;
        self.contentContainerView.frame = f; self.dimmingView.alpha = self.isSidebarOpen ? 1.0 : 0.0;
    }];
}
- (void)openSettingsScreen {
    [self toggleSidebar]; MySettingsViewController *s = [[MySettingsViewController alloc] init];
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:s];
    n.modalPresentationStyle = UIModalPresentationFullScreen;
    s.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"閉じる" style:UIBarButtonItemStyleDone target:self action:@selector(closeSettings)];
    [self presentViewController:n animated:YES completion:nil];
}
- (void)closeSettings { [self dismissViewControllerAnimated:YES completion:nil]; }
@end

// =========================================================
// 🚀 3. フック部分 (YouTube Musicの乗っ取り＆絶対領域生成)
// =========================================================

%hook MPNowPlayingInfoCenter
- (void)setNowPlayingInfo:(NSDictionary *)info {
    %orig;
    if (info) {
        NSString *title = info[MPMediaItemPropertyTitle];
        if (title) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MSP_TrackChanged" object:title];
        }
    }
}
- (void)setPlaybackState:(NSUInteger)state {
    %orig;
    BOOL isPlaying = (state == 1);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MSP_StateChanged" object:@(isPlaying)];
}
%end

// 最上位に君臨し続けるための専用ウィンドウ（絶対領域）
static UIWindow *musicSpaceWindow = nil;

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // 自作UIの画面なら何もしない
    if ([NSStringFromClass([self class]) hasPrefix:@"My"]) return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // アプリが安定するまで1.5秒待つ
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 🛡️ 本物のYouTube Musicから「Scene（通行証）」を奪い取る！
            UIWindowScene *windowScene = self.view.window.windowScene;
            
            if (windowScene) {
                musicSpaceWindow = [[UIWindow alloc] initWithWindowScene:windowScene];
            } else {
                musicSpaceWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            }
            
            // アラートよりも上に固定
            musicSpaceWindow.windowLevel = UIWindowLevelAlert + 1;
            
            // 自作UIをセットして表示！
            MyMainContainerViewController *c = [[MyMainContainerViewController alloc] init];
            musicSpaceWindow.rootViewController = c;
            [musicSpaceWindow makeKeyAndVisible];
            
            NSLog(@"Music Space Pro: Absolute Overlay Window Activated with Scene!");
        });
    });
}
%end

// =========================================================
// 🔓 Googleログイン突破パッチ (YTSignInFix)
// =========================================================
%hook SSORPCService
+ (id)URLFromURL:(id)arg1 withAdditionalFragmentParameters:(NSDictionary *)arg2 {
    NSURL *orig = %orig;
    if (!orig) return nil;
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:orig resolvingAgainstBaseURL:NO];
    NSMutableArray *newQueryItems = [urlComponents.queryItems mutableCopy];
    
    for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
        if ([queryItem.name isEqualToString:@"system_version"]
            || [queryItem.name isEqualToString:@"app_version"]
            || [queryItem.name isEqualToString:@"kdlc"]
            || [queryItem.name isEqualToString:@"kss"]
            || [queryItem.name isEqualToString:@"lib_ver"]
            || [queryItem.name isEqualToString:@"device_model"]) {
            [newQueryItems removeObject:queryItem];
        }
    }
    urlComponents.queryItems = [newQueryItems copy];
    return urlComponents.URL;
}
%end
