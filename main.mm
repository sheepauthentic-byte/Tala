#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <stdint.h>

#if __has_include(<dobby.h>)
#include <dobby.h>
#elif __has_include(<dobby/dobby.h>)
#include <dobby/dobby.h>
#else
extern "C" {
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
}
#endif

// --- BIẾN TRẠNG THÁI MENU ---
bool g_BypassAntiCheat = true;
bool g_GodMode = false;
bool g_OneHit = false;
float g_DamageFactor = 10.0f;
bool g_GameSpeed = false;
float g_SpeedFactor = 3.0f;
bool g_BypassGMPanel = false;
bool g_AutoFarm = false;

// --- CON TRỎ HÀM GỐC ---
static bool (*orig_GMCmd_IsGm)(void *instance) = NULL;

// Chỉ giữ lại 1 hook an toàn nhất (Bypass GM / Kiểm tra trạng thái) để tránh sập app lúc load dữ liệu
bool hooked_GMCmd_IsGm(void *instance) {
    if (!instance) return false;
    if (g_BypassGMPanel) {
        return true;
    }
    return orig_GMCmd_IsGm(instance);
}

// --- GIAO DIỆN MOD MENU 5 TAB (SHEEPCT UI) ---
@interface SheepctModMenu : UIView
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) NSInteger currentTab;
@end

@implementation SheepctModMenu

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(30, 50, 340, 540)];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.06f alpha:0.94f];
        self.layer.cornerRadius = 18.0f;
        self.layer.borderWidth = 1.2f;
        self.layer.borderColor = [UIColor colorWithRed:0.6f green:0.2f blue:0.9f alpha:0.85f].CGColor;
        self.clipsToBounds = YES;
        self.hidden = YES;

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 310, 24)];
        self.titleLabel.text = @"Sheepct Full Menu | TRẦN MẠNH CƯỜNG";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:11.0f];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 45, 320, 430)];
        [self addSubview:self.contentScrollView];

        NSArray *tabs = @[@"Chiến Đấu", @"Tốc Độ", @"Hiệu Năng", @"Tự Động", @"Hệ Thống"];
        CGFloat tabWidth = 340.0f / tabs.count;
        for (int i = 0; i < tabs.count; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(i * tabWidth, 485, tabWidth, 45);
            [btn setTitle:tabs[i] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorWithRed:0.75f green:0.35f blue:1.0f alpha:1.0f] forState:UIControlStateSelected];
            btn.titleLabel.font = [UIFont boldSystemFontOfSize:11.0f];
            btn.tag = i;
            [btn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            if (i == 4) { btn.selected = YES; self.currentTab = 4; }
        }

        [self loadTabContent:4];
    }
    return self;
}

- (void)tabTapped:(UIButton *)sender {
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) {
            ((UIButton *)sub).selected = (sub.tag == sender.tag);
        }
    }
    self.currentTab = sender.tag;
    [self loadTabContent:self.currentTab];
}

- (void)loadTabContent:(NSInteger)tabIndex {
    for (UIView *v in self.contentScrollView.subviews) { [v removeFromSuperview]; }
    CGFloat yPos = 10;

    if (tabIndex == 4) {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, yPos, 300, 60)];
        lbl.text = @"Chế độ an toàn: Đã cô lập các hàm nặng để chống văng game khi load dữ liệu.";
        lbl.textColor = [UIColor orangeColor];
        lbl.font = [UIFont systemFontOfSize:11.0f];
        lbl.numberOfLines = 0;
        [self.contentScrollView addSubview:lbl];
        yPos += 70;

        UILabel *lblGm = [[UILabel alloc] initWithFrame:CGRectMake(10, yPos, 210, 30)];
        lblGm.text = @"Mở Khóa Bảng Lệnh GM Dev";
        lblGm.textColor = [UIColor whiteColor];
        lblGm.font = [UIFont systemFontOfSize:11.5f];
        [self.contentScrollView addSubview:lblGm];

        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(240, yPos, 50, 30)];
        sw.on = g_BypassGMPanel;
        [sw addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            g_BypassGMPanel = sw.isOn;
        }] forControlEvents:UIControlEventValueChanged];
        [self.contentScrollView addSubview:sw];
    }

    self.contentScrollView.contentSize = CGSizeMake(320, yPos + 20);
}

@end

// --- KHỞI CHẠY DYLIB AN TOÀN ---
__attribute__((constructor)) void initSheepctFullMasterMenu() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t imageBase = (uintptr_t)_dyld_get_image_header(0);

        // Chỉ hook 1 hàm kiểm tra GM tại 0x219bb6 để kiểm tra độ ổn định
        if (imageBase != 0) {
            DobbyHook((void *)(imageBase + 0x219bb6), (void *)hooked_GMCmd_IsGm, (void **)&orig_GMCmd_IsGm);
        }

        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        if (window) {
            SheepctModMenu *menu = [[SheepctModMenu alloc] init];
            [window addSubview:menu];

            UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatBtn.frame = CGRectMake(15, 120, 45, 45);
            floatBtn.backgroundColor = [UIColor colorWithRed:0.55f green:0.15f blue:0.85f alpha:0.95f];
            floatBtn.layer.cornerRadius = 22.5f;
            [floatBtn setTitle:@"S" forState:UIControlStateNormal];
            [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [floatBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) { 
                menu.hidden = !menu.hidden; 
            }] forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:floatBtn];
        }
    });
}
