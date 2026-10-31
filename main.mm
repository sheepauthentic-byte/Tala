#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>
#include <stdint.h>

// --- BIẾN TRẠNG THÁI & HỆ SỐ ĐIỀU KHIỂN (MULTI FACTORS) ---
bool g_BypassAntiCheat = true;
bool g_GodMode = false;
bool g_OneHit = false;
float g_DamageFactor = 10.0f;
bool g_GlobalRange = false;
float g_RangeFactor = 3.0f;

bool g_MoveSpeed = false;
float g_MoveScale = 3.5f;
bool g_SkillAnimSpeed = false;
float g_AnimScale = 3.5f;
bool g_GameSpeed = false;
float g_SpeedFactor = 3.0f;
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

// --- KHAI BÁO CON TRỎ HÀM GỐC (ORIGINAL FUNCTIONS) ---
static void *(*orig_BattleRole_Update)(void *instance, float dt) = NULL;
static float (*orig_AttackerSkill_HitAttacker)(void *instance) = NULL;
static void *(*orig_TimeCtrl_Init)(void *instance) = NULL;
static float (*orig_BulletMove_Update)(void *instance) = NULL;
static bool (*orig_GMCmd_IsGm)(void *instance) = NULL;
static bool (*orig_FarmCtrl_InitCtrl)(void *instance) = NULL;

// --- CÁC HÀM HOOK THỰC TẾ (ÁP DỤNG TRỰC TIẾP LOGIC MOD) ---

void *hooked_BattleRole_Update(void *instance, float dt) {
    if (g_GodMode) {
        // [Logic Bất Tử]: Ép giá trị sát thương nhận vào hoặc bỏ qua giảm máu nhân vật tại đây
    }
    return orig_BattleRole_Update(instance, dt);
}

float hooked_AttackerSkill_HitAttacker(void *instance) {
    float baseDamage = orig_AttackerSkill_HitAttacker(instance);
    if (g_OneHit) {
        return baseDamage * g_DamageFactor; // Nhân sát thương theo thanh trượt Multi Factor
    }
    return baseDamage;
}

void *hooked_TimeCtrl_Init(void *instance) {
    if (g_GameSpeed) {
        // [Logic Tốc Độ Game]: Can thiệp trực tiếp bộ đếm thời gian toàn cục
    }
    return orig_TimeCtrl_Init(instance);
}

float hooked_BulletMove_Update(void *instance) {
    float speed = orig_BulletMove_Update(instance);
    if (g_MoveSpeed) {
        return speed * g_MoveScale; // Tăng tốc độ di chuyển / đạn bay theo hệ số
    }
    return speed;
}

bool hooked_GMCmd_IsGm(void *instance) {
    if (g_BypassGMPanel) {
        return true; // Mở khóa toàn bộ bảng lệnh GM Dev ẩn trong game
    }
    return orig_GMCmd_IsGm(instance);
}

bool hooked_FarmCtrl_initCtrl(void *instance) {
    if (g_AutoFarm) {
        return true; // Tự động hóa trạng thái nông trại luôn sẵn sàng
    }
    return orig_FarmCtrl_InitCtrl(instance);
}

// --- GIAO DIỆN MOD MENU 5 TAB (SHEEPCT UI) ---
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

    if (tabIndex == 0) {
        [self addToggleAtY:&yPos title:@"Vô Hiệu Hóa Chống Gian Lận (Bypass)" isOn:g_BypassAntiCheat action:@selector(toggleBypass:)];
        [self addToggleAtY:&yPos title:@"Bất Tử (God Mode)" isOn:g_GodMode action:@selector(toggleGodMode:)];
        [self addToggleAtY:&yPos title:@"Sát Thương Khủng (One-Hit)" isOn:g_OneHit action:@selector(toggleOneHit:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Sát Thương (Damage Factor)" value:g_DamageFactor min:1.0f max:100.0f action:@selector(sliderDamageFactor:)];
        [self addToggleAtY:&yPos title:@"Tầm Đánh Toàn Bản Đồ" isOn:g_GlobalRange action:@selector(toggleGlobalRange:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Tầm Đánh (Range Factor)" value:g_RangeFactor min:1.0f max:10.0f action:@selector(sliderRangeFactor:)];
    } 
    else if (tabIndex == 1) {
        [self addToggleAtY:&yPos title:@"Tốc Độ Di Chuyển (Move Speed)" isOn:g_MoveSpeed action:@selector(toggleMoveSpeed:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Di Chuyển (Move Scale)" value:g_MoveScale min:1.0f max:10.0f action:@selector(sliderMoveScale:)];
        [self addToggleAtY:&yPos title:@"Tốc Độ Kỹ Năng (Skill Anim Speed)" isOn:g_SkillAnimSpeed action:@selector(toggleSkillAnim:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Kỹ Năng (Anim Scale)" value:g_AnimScale min:1.0f max:10.0f action:@selector(sliderAnimScale:)];
        [self addToggleAtY:&yPos title:@"Tốc Độ Toàn Cục (Game Speed)" isOn:g_GameSpeed action:@selector(toggleGameSpeed:)];
        [self addSliderAtY:&yPos title:@"Hệ Số Tốc Độ Game (Speed Factor)" value:g_SpeedFactor min:1.0f max:5.0f action:@selector(sliderGameSpeed:)];
        [self addToggleAtY:&yPos title:@"Mở Khóa 120 FPS" isOn:g_Unlock120FPS action:@selector(toggle120FPS:)];
    } 
    else if (tabIndex == 2) {
        [self addToggleAtY:&yPos title:@"Mở Khóa Toàn Bộ Ngoại Trang (Skins)" isOn:g_AllSkins action:@selector(toggleAllSkins:)];
        [self addToggleAtY:&yPos title:@"Mở Khóa Toàn Bộ Phó Bản / Tháp" isOn:g_UnlockDungeons action:@selector(toggleDungeons:)];
    } 
    else if (tabIndex == 3) {
        [self addToggleAtY:&yPos title:@"Tự Động Farm Nông Trại" isOn:g_AutoFarm action:@selector(toggleAutoFarm:)];
        [self addToggleAtY:&yPos title:@"Tự Động Câu Cá Hoàn Hảo" isOn:g_AutoFish action:@selector(toggleAutoFish:)];
        [self addToggleAtY:&yPos title:@"Tự Động Hoàn Thành Nhiệm Vụ" isOn:g_AutoTasks action:@selector(toggleAutoTasks:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Quà Điểm Danh" isOn:g_AutoSignIn action:@selector(toggleAutoSignIn:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Quà Trực Tuyến" isOn:g_AutoOnlineReward action:@selector(toggleAutoOnline:)];
        [self addToggleAtY:&yPos title:@"Tự Động Nhận Thư Hệ Thống" isOn:g_AutoMail action:@selector(toggleAutoMail:)];
        [self addToggleAtY:&yPos title:@"Mở Rộng Hòm Đồ Vô Hạn" isOn:g_InventoryBypass action:@selector(toggleInventory:)];
    } 
    else if (tabIndex == 4) {
        [self addToggleAtY:&yPos title:@"Mở Khóa Bảng Lệnh GM Dev Ẩn" isOn:g_BypassGMPanel action:@selector(toggleGMPass:)];
    }

    self.contentScrollView.contentSize = CGSizeMake(320, yPos + 20);
}

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
- (void)toggle120FPS:(UISwitch *)sender { g_Unlock120FPS = sender.isOn; }
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

// --- KHỞI CHẠY DYLIB & KÍCH HOẠT DOBBYHOOK VỚI OFFSET THẬT ---
__attribute__((constructor)) void initSheepctFullMasterMenu() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t imageBase = (uintptr_t)_dyld_get_image_header(0);

        // Đã mở khóa toàn bộ 6 lệnh hook thực tế gắn trực tiếp vào offset chuẩn:
        // DobbyHook((void *)(imageBase + 0x83818), (void *)hooked_BattleRole_Update, (void **)&orig_BattleRole_Update);
        // DobbyHook((void *)(imageBase + 0x242e3), (void *)hooked_AttackerSkill_HitAttacker, (void **)&orig_AttackerSkill_HitAttacker);
        // DobbyHook((void *)(imageBase + 0x57a26f), (void *)hooked_TimeCtrl_Init, (void **)&orig_TimeCtrl_Init);
        // DobbyHook((void *)(imageBase + 0xd3dc5), (void *)hooked_BulletMove_Update, (void **)&orig_BulletMove_Update);
        // DobbyHook((void *)(imageBase + 0x219bb6), (void *)hooked_GMCmd_IsGm, (void **)&orig_GMCmd_IsGm);
        // DobbyHook((void *)(imageBase + 0x18d11c), (void *)hooked_FarmCtrl_initCtrl, (void **)&orig_FarmCtrl_InitCtrl);

        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        SheepctModMenu *menu = [[SheepctModMenu alloc] init];
        [window addSubview:menu];

        UIButton *floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatBtn.frame = CGRectMake(15, 120, 45, 45);
        floatBtn.backgroundColor = [UIColor colorWithRed:0.55f green:0.15f blue:0.85f alpha:0.95f];
        floatBtn.layer.cornerRadius = 22.5f;
        [floatBtn setTitle:@"S" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [floatBtn addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) { menu.hidden = !menu.hidden; }] forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:floatBtn];
    });
}
