#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <stdint.h>

// --- 1. BIẾN TRẠNG THÁI & HỆ SỐ ĐIỀU KHIỂN TOÀN CỤC (MULTI FACTORS) ---
bool g_BypassAntiCheat = true;
bool g_GodMode = false;
bool g_OneHit = false;
float g_DamageFactor = 10.0f;     // Hệ số nhân sát thương One-Hit (1x - 100x)
bool g_GlobalRange = false;
float g_RangeFactor = 3.0f;       // Hệ số mở rộng tầm đánh (1x - 10x)

bool g_MoveSpeed = false;
float g_MoveScale = 3.5f;         // Hệ số tốc độ chạy (1x - 10x)
bool g_SkillAnimSpeed = false;
float g_AnimScale = 3.5f;         // Hệ số tốc độ hoạt ảnh kỹ năng (1x - 10x)
bool g_GameSpeed = false;
float g_SpeedFactor = 3.0f;       // Hệ số tua nhanh toàn cục game (1x - 5x)
bool g_Unlock120FPS = true;

bool g_AllSkins = false;
bool g_UnlockDungeons = false;
bool g_BypassGMPanel = false;

bool g_AutoFarm = false;
bool g_AutoFish = false;
bool g_AutoTasks = false;
bool g_AutoSignIn = false;
bool g_AutoOnlineReward = false;
bool g_AutoMail = false;
bool g_InventoryBypass = false;

// --- 2. KHAI BÁO CON TRỎ HÀM GỐC ĐỂ HOOK (ORIGINAL FUNCTIONS) ---
static void *(*orig_BattleRole_TakeDamage)(void *instance, float damage) = NULL;
static float (*orig_AttackerSkill_GetDamage)(void *instance) = NULL;
static void *(*orig_TimeCtrl_Update)(void *instance, float deltaTime) = NULL;
static float (*orig_BulletMove_GetSpeed)(void *instance) = NULL;
static bool (*orig_GMCmd_CheckPermission)(void *instance) = NULL;
static bool (*orig_FarmCtrl_IsReady)(void *instance) = NULL;

// --- 3. CÁC HÀM HOOK THỰC TẾ (DOBBY HOOK LOGIC) ---
void *hooked_BattleRole_TakeDamage(void *instance, float damage) {
    if (g_GodMode) { damage = 0.0f; } // Bất tử: Triệt tiêu sát thương
    return orig_BattleRole_TakeDamage(instance, damage);
}

float hooked_AttackerSkill_GetDamage(void *instance) {
    float baseDamage = orig_AttackerSkill_GetDamage(instance);
    if (g_OneHit) { return baseDamage * g_DamageFactor; } // Sát thương khủng theo thanh trượt
    return baseDamage;
}

void *hooked_TimeCtrl_Update(void *instance, float deltaTime) {
    if (g_GameSpeed) { deltaTime *= g_SpeedFactor; } // Tua nhanh tốc độ game toàn cục
    return orig_TimeCtrl_Update(instance, deltaTime);
}

float hooked_BulletMove_GetSpeed(void *instance) {
    float speed = orig_BulletMove_GetSpeed(instance);
    if (g_MoveSpeed) { return speed * g_MoveScale; } // Tốc độ di chuyển theo hệ số
    return speed;
}

bool hooked_GMCmd_CheckPermission(void *instance) {
    if (g_BypassGMPanel) { return true; } // Mở khóa bảng lệnh nhà phát triển GM Dev ẩn
    return orig_GMCmd_CheckPermission(instance);
}

bool hooked_FarmCtrl_IsReady(void *instance) {
    if (g_AutoFarm) { return true; } // Tự động thu hoạch nông trại lập tức
    return orig_FarmCtrl_IsReady(instance);
}

// --- 4. GIAO DIỆN MOD MENU TOÀN DIỆN (SHEEPCT UI - 5 TABS) ---
@interface SheepctModMenu : UIView
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *floatingButton;
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

        // Tiêu đề & Credit chính chủ TRẦN MẠNH CƯỜNG & sheepct
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 310, 24];
        self.titleLabel.text = @"Sheepct Full Menu | TRẦN MẠNH CƯỜNG";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:11.0f];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        // Khu vực chứa danh sách tính năng
        self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 45, 320, 430];
        [self addSubview:self.contentScrollView];

        // Thanh Tab điều hướng (Chiến Đấu, Tốc Độ, Hiệu Năng, Tự Động, Hệ Thống)
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
            if (i == 1) { btn.selected = YES; self.currentTab = 1; }
        }

        [self loadTabContent:1];
    }
    return self;
}

- (void)tabTapped:(UIButton *)sender {
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIButton class]] && sub != self.floatingButton) {
            ((UIButton *)sub).selected = (sub.tag == sender.tag);
        }
    }
    self.currentTab = sender.tag;
    [self loadTabContent:self.currentTab];
}

- (void)loadTabContent:(NSInteger)tabIndex {
    for (UIView *v in self.contentScrollView.subviews) { [v removeFromSuperview]; }
    CGFloat yPos = 10;

    if (tabIndex == 0) { // TAB 0: CHIẾN ĐẤU (COMBAT)
        [self addToggleAtY:&yPos title:@"Vô Hiệu Hóa Chống Gian Lận (Bypass)" isOn:g_BypassAntiCheat action:@selector(toggleBypass:)];
        [self addToggleAtY:&yPos title:@"Bất Tử (God Mode)" isOn:g_GodMode action:@selector(toggleGodMode:)];
        [self addToggleAtY:&yPos title:@"Sát Thương Khủng (One-Hit)" isOn:g_OneHit action:@selector(toggleOneHit:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Sát Thương (Damage Factor)" value:g_DamageFactor min:1.0f max:100.0f action:@selector(sliderDamageFactor:)];
        [self addToggleAtY:&yPos title:@"Tầm Đánh Toàn Bản Đồ" isOn:g_GlobalRange action:@selector(toggleGlobalRange:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Tầm Đánh (Range Factor)" value:g_RangeFactor min:1.0f max:10.0f action:@selector(sliderRangeFactor:)];
    } 
    else if (tabIndex == 1) { // TAB 1: TỐC ĐỘ & HỆ SỐ (SPEED & FACTORS)
        [self addToggleAtY:&yPos title:@"Tốc Độ Di Chuyển (Move Speed)" isOn:g_MoveSpeed action:@selector(toggleMoveSpeed:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Di Chuyển (Move Scale)" value:g_MoveScale min:1.0f max:10.0f action:@selector(sliderMoveScale:)];
        [self addToggleAtY:&yPos title:@"Tốc Độ Kỹ Năng (Skill Anim Speed)" isOn:g_SkillAnimSpeed action:@selector(toggleSkillAnim:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Kỹ Năng (Anim Scale)" value:g_AnimScale min:1.0f max:10.0f action:@selector(sliderAnimScale:)];
        [self addToggleAtY:&yPos title:@"Tốc Độ Toàn Cục (Game Speed)" isOn:g_GameSpeed action:@selector(toggleGameSpeed:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Tốc Độ Game (Speed Factor)" value:g_SpeedFactor min:1.0f max:5.0f action:@selector(sliderGameSpeed:)];
        [self addToggleAtY:&yPos title:@"Mở Khóa 120 FPS (Unlock 120 FPS)" isOn:g_Unlock120FPS action:@selector(toggle120FPS:)];
    } 
    else if (tabIndex == 2) { // TAB 2: HIỆU NĂNG & MỞ KHÓA (VISUALS)
        [self addToggleAtY:&yPos title:@"Mở Khóa Toàn Bộ Ngoại Trang (Skins)" isOn:g_AllSkins action:@selector(toggleAllSkins:)];
        [self addToggleAtY:&yPos title:@"Mở Khóa Toàn Bộ Phó Bản / Tháp" isOn:g_UnlockDungeons action:@selector(toggleDungeons:)];
    } 
    else if (tabIndex == 3) { // TAB 3: TỰ ĐỘNG HÓA (AUTO)
        [self addToggleAtY:&yPos title:@"Tự Động Farm Nông Trại" isOn:g_AutoFarm action:@selector(toggleAutoFarm:)];
        [self addToggleAtY:&yPos title:@"Tự Động Câu Cá Hoàn Hảo" isOn:g_AutoFish action:@selector(toggleAutoFish:)];
        [self addToggleAtY:&yPos title:@"Tự Động Hoàn Thành Nhiệm Vụ" isOn:g_AutoTasks action:@selector(toggleAutoTasks:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Quà Điểm Danh" isOn:g_AutoSignIn action:@selector(toggleAutoSignIn:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Quà Trực Tuyến" isOn:g_AutoOnlineReward action:@selector(toggleAutoOnline:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Thư Hệ Thống" isOn:g_AutoMail action:@selector(toggleAutoMail:)];
        [self addToggleAtY:&yPos title:@"Mở Rộng Hòm Đồ Vô Hạn" isOn:g_InventoryBypass action:@selector(toggleInventory:)];
    } 
    else if (tabIndex == 4) { // TAB 4: HỆ THỐNG (SETTINGS)
        [self addToggleAtY:&yPos title:@"Mở Khóa Bảng Lệnh GM Dev Ẩn" isOn:g_BypassGMPanel action:@selector(toggleGMPass:)];
    }

    self.contentScrollView.contentSize = CGSizeMake(320, yPos + 20);
}

// --- HÀM TẠO UI (TOGGLE & SLIDER) ---
- (void)addToggleAtY:(CGFloat *)y title:(NSString *)title isOn:(BOOL)isOn action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, *y, 210, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:11.5f];
    [self.contentScrollView addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(240, *y, 50, 30)];
    sw.on = isOn;
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.contentScrollView addSubview:sw];
    *y += 42;
}

- (void)addSliderAtY:(CGFloat *)y title:(NSString *)title value:(float)val min:(float)min max:(float)max action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, *y, 300, 20)];
    lbl.text = [NSString stringWithFormat:@"%@: %.2fx", title, val];
    lbl.textColor = [UIColor colorWithRed:0.8f green:0.6f blue:1.0f alpha:1.0f];
    lbl.font = [UIFont boldSystemFontOfSize:10.5f];
    [self.contentScrollView addSubview:lbl];
    *y += 20;

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, *y, 300, 20)];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = val;
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.contentScrollView addSubview:slider];
    *y += 38;
}

// --- SỰ KIỆN GẮN TRẠNG THÁI ---
- (void)toggleBypass:(UISwitch *)sender { g_BypassAntiCheat = sender.isOn; }
- (void)toggleGodMode:(UISwitch *)sender { g_GodMode = sender.isOn; }
- (void)toggleOneHit:(UISwitch *)sender { g_OneHit = sender.isOn; }
- (void)sliderDamageFactor:(UISlider *)sender { g_DamageFactor = sender.value; }
- (void)toggleGlobalRange:(UISwitch *)sender { g_GlobalRange = sender.isOn; }
- (void)sliderRangeFactor:(UISlider *)sender { g_RangeFactor = sender.value; }

- (void)toggleMoveSpeed:(UISwitch *)sender { g_MoveSpeed = sender.isOn; }
- (void)sliderMoveScale:(UISlider *)sender { g_MoveScale = sender.value; }
- (void)toggleSkillAnim:(UISwitch *)sender { g_SkillAnimSpeed = sender.isOn; }
- (void)sliderAnimScale:(UISlider *)sender { g_AnimScale = sender.value; }
- (void)toggleGameSpeed:(UISwitch *)sender { g_GameSpeed = sender.isOn; }
- (void)sliderGameSpeed:(UISlider *)sender { g_SpeedFactor = sender.value; }
- (void)toggle120FPS:(UISwitch *)sender {
    g_Unlock120FPS = sender.isOn;
    if (g_Unlock120FPS) { UIScreen.mainScreen.maximumFramesPerSecond = 120; }
}

- (void)toggleAllSkins:(UISwitch *)sender { g_AllSkins = sender.isOn; }
- (void)toggleDungeons:(UISwitch *)sender { g_UnlockDungeons = sender.isOn; }

- (void)toggleAutoFarm:(UISwitch *)sender { g_AutoFarm = sender.isOn; }
- (void)toggleAutoFish:(UISwitch *)sender { g_AutoFish = sender.isOn; }
- (void)toggleAutoTasks:(UISwitch *)sender { g_AutoTasks = sender.isOn; }
- (void)toggleAutoSignIn:(UISwitch *)sender { g_AutoSignIn = sender.isOn; }
- (void)toggleAutoOnline:(UISwitch *)sender { g_AutoOnlineReward = sender.isOn; }
- (void)toggleAutoMail:(UISwitch *)sender { g_AutoMail = sender.isOn; }
- (void)toggleInventory:(UISwitch *)sender { g_InventoryBypass = sender.isOn; }
- (void)toggleGMPass:(UISwitch *)sender { g_BypassGMPanel = sender.isOn; }

@end

// --- 5. KHỞI CHẠY DYLIB, KÍCH HOẠT HOOK VÀ NÚT NỔI MENU ---
__attribute__((constructor)) void initSheepctFullMasterMenu() {
    // Ví dụ mẫu tích hợp DobbyHook tại đây:
    /*
    DobbyHook((void *)DobbySymbolResolver(NULL, "BattleRole_TakeDamage"), (void *)hooked_BattleRole_TakeDamage, (void **)&orig_BattleRole_TakeDamage);
    DobbyHook((void *)DobbySymbolResolver(NULL, "AttackerSkill_GetDamage"), (void *)hooked_AttackerSkill_GetDamage, (void **)&orig_AttackerSkill_GetDamage);
    DobbyHook((void *)DobbySymbolResolver(NULL, "TimeCtrl_Update"), (void *)hooked_TimeCtrl_Update, (void **)&orig_TimeCtrl_Update);
    DobbyHook((void *)DobbySymbolResolver(NULL, "BulletMove_GetSpeed"), (void *)hooked_BulletMove_GetSpeed, (void **)&orig_BulletMove_GetSpeed);
    DobbyHook((void *)DobbySymbolResolver(NULL, "GMCmdCtrl_CheckPermission"), (void *)hooked_GMCmd_CheckPermission, (void **)&orig_GMCmd_CheckPermission);
    DobbyHook((void *)DobbySymbolResolver(NULL, "FarmCtrl_IsReady"), (void *)hooked_FarmCtrl_IsReady, (void **)&orig_FarmCtrl_IsReady);
    */

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        SheepctModMenu *menu = [[SheepctModMenu alloc] init];
        [window addSubview:menu];

        UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatBtn.frame = CGRectMake(15, 120, 45, 45];
        floatBtn.backgroundColor = [UIColor colorWithRed:0.55f green:0.15f blue:0.85f alpha:0.95f];
        floatBtn.layer.cornerRadius = 22.5f;
        [floatBtn setTitle:@"S" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [floatBtn addTarget:^int(UIButton *b){
            menu.hidden = !menu.hidden;
            return 0;
        }(floatBtn) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:floatBtn];
    });
}
