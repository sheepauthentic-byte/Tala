#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- 1. BIẾN TRẠNG THÁI 26 TÍNH NĂNG ---
static bool g_enableGodMode = false;          // 1. God Mode / Kháng sát thương
static bool g_enableSpeedHack = false;        // 2. Tốc độ di chuyển
static bool g_enableInvisibility = false;     // 3. Tàng hình nhân vật
static bool g_enableHighJump = false;         // 4. Khinh công / Nhảy cao
static bool g_enableAutoLoot = false;         // 5. Hút item toàn bản đồ
static bool g_enableHPRegen = false;          // 6. Khóa máu / HP Regen
static bool g_enableFPSUnlock = false;        // 7. Mở khóa FPS cao
static bool g_enableOneHit = false;           // 8. Đánh một phát chết luôn (One-Hit)
static bool g_enableAntiStun = false;         // 9. Chống khống chế / Anti-Stun
static bool g_enableZoomOut = false;          // 10. Phóng to tầm nhìn Camera
static bool g_enableFastAttack = false;       // 11. Tấn công siêu tốc / No Delay
static bool g_enableUnlimitedSkill = false;   // 12. Hồi chiêu kỹ năng 0 giây
static bool g_enableFreeCam = false;         // 13. Camera tự do thám hiểm
static bool g_enableAutoBot = false;          // 14. Tự động hóa Auto-Play / Bot
static bool g_enableSaveConfig = false;       // 15. Lưu cấu hình cục bộ
static bool g_enableBypassCheat = false;      // 16. Bỏ qua kiểm tra Integrity
static bool g_enableSkinUnlock = false;       // 17. Mở khóa trang phục hiển thị
static bool g_enableCurrencyHack = false;     // 18. Khóa/Tăng tài nguyên tiền tệ
static bool g_enableAchievement = false;      // 19. Mở khóa thành tựu / danh hiệu
static bool g_enableFastLoad = false;         // 20. Load cảnh phụ bản siêu tốc
static bool g_enableGlobalTime = false;       // 21. Tua nhanh thời gian game
static bool g_enableNoClip = false;           // 22. Đi xuyên vật thể / tường
static bool g_enableEnemyFreeze = false;      // 23. Đóng băng AI kẻ địch
static bool g_enableTargetLock = false;       // 24. Khóa mục tiêu tự động
static bool g_enableOcclusionFix = false;     // 25. Xóa vật cản tầm nhìn
static bool g_enableGlobalDamage = false;     // 26. Tăng sát thương toàn cục

static float g_speedMultiplier = 1.0f;
static float g_jumpMultiplier = 1.0f;

// --- LẤY ASLR SLIDE CHUẨN AN TOÀN ---
static uintptr_t get_slide() {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// ==========================================
// --- GIAO DIỆN MOD MENU ĐA TAB (SHEEPCT) ---
// ==========================================
@interface SheepctModMenuController : NSObject
@property (nonatomic, strong) UIWindow *menuWindow;
+ (instancetype)sharedInstance;
- (void)toggleMenu;
@end

@implementation SheepctModMenuController {
    UIView *mainView;
    UIScrollView *contentScroll;
    UILabel *speedValLabel;
    UILabel *jumpValLabel;
    int currentTab;
}

+ (instancetype)sharedInstance {
    static SheepctModMenuController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[SheepctModMenuController alloc] init];
        shared->currentTab = 0;
    });
    return shared;
}

- (void)toggleMenu {
    if (self.menuWindow) {
        self.menuWindow.hidden = !self.menuWindow.hidden;
        return;
    }

    self.menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 50, 350, 520)];
    self.menuWindow.windowLevel = UIWindowLevelAlert + 1;
    self.menuWindow.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [[UIViewController alloc] init];
    self.menuWindow.rootViewController = vc;

    mainView = [[UIView alloc] initWithFrame:vc.view.bounds];
    mainView.backgroundColor = [UIColor colorWithRed:0.04f green:0.04f blue:0.06f alpha:0.97f];
    mainView.layer.cornerRadius = 16.0f;
    mainView.layer.borderWidth = 1.8f;
    mainView.layer.borderColor = [UIColor systemCyanColor].CGColor;
    [vc.view addSubview:mainView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 330, 22)];
    titleLabel.text = @"👑 Sheepct Mod - Full 26 Features";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:titleLabel];

    UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 28, 330, 16)];
    authorLabel.text = @"Tool do TRẦN MẠNH CƯỜNG phát triển";
    authorLabel.textColor = [UIColor systemCyanColor];
    authorLabel.font = [UIFont systemFontOfSize:11];
    authorLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:authorLabel];

    // Thanh Tab phân loại (4 Tab chính)
    NSArray *tabs = @[@"Combat", @"Movement", @"World", @"System"];
    CGFloat tabWidth = 330.0f / tabs.count;
    for (int i = 0; i < tabs.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(10 + i * tabWidth, 50, tabWidth - 4, 28);
        [tabBtn setTitle:tabs[i] forState:UIControlStateNormal];
        tabBtn.tag = i;
        [tabBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        tabBtn.backgroundColor = [UIColor colorWithRed:0.15f green:0.15f blue:0.22f alpha:1.0f];
        tabBtn.layer.cornerRadius = 6.0f;
        [tabBtn addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:tabBtn];
    }

    // Scroll chứa danh sách tính năng
    contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 85, 330, 375)];
    contentScroll.backgroundColor = [UIColor clearColor];
    [mainView addSubview:contentScroll];

    [self reloadTabContent];

    // Nút ẩn Menu nhanh
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(105, 470, 140, 35);
    [closeBtn setTitle:@"Ẩn Menu Nhanh" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:closeBtn];

    self.menuWindow.hidden = NO;
}

- (void)switchTab:(UIButton *)sender {
    currentTab = (int)sender.tag;
    [self reloadTabContent];
}

- (void)reloadTabContent {
    for (UIView *sub in contentScroll.subviews) {
        [sub removeFromSuperview];
    }

    CGFloat yOffset = 10;
    
    if (currentTab == 0) {
        // --- TAB 1: COMBAT (Chiến đấu & Sát thương) ---
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"1. God Mode / Kháng sát thương" state:g_enableGodMode action:@selector(toggleGodMode:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"2. One-Hit / Sát thương cực lớn" state:g_enableOneHit action:@selector(toggleOneHit:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"3. Khóa máu / Hồi phục HP" state:g_enableHPRegen action:@selector(toggleHPRegen:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"4. Chống khống chế (Anti-Stun)" state:g_enableAntiStun action:@selector(toggleAntiStun:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"5. Tấn công siêu tốc (No Delay)" state:g_enableFastAttack action:@selector(toggleFastAttack:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"6. Hồi chiêu kỹ năng 0 giây" state:g_enableUnlimitedSkill action:@selector(toggleUnlimitedSkill:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"7. Khóa mục tiêu tự động" state:g_enableTargetLock action:@selector(toggleTargetLock:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"8. Sát thương diện rộng toàn cục" state:g_enableGlobalDamage action:@selector(toggleGlobalDamage:)]; yOffset += 40;
        contentScroll.contentSize = CGSizeMake(330, yOffset + 20);

    } else if (currentTab == 1) {
        // --- TAB 2: MOVEMENT (Di chuyển & Tốc độ) ---
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"9. Tốc độ di chuyển (Speed Hack)" state:g_enableSpeedHack action:@selector(toggleSpeedHack:)]; yOffset += 38;
        
        speedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yOffset, 310, 18)];
        speedValLabel.text = [NSString stringWithFormat:@"Hệ số Tốc độ: %.1fx", g_speedMultiplier];
        speedValLabel.textColor = [UIColor yellowColor];
        speedValLabel.font = [UIFont systemFontOfSize:12];
        speedValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:speedValLabel]; yOffset += 22;

        UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 310, 25)];
        speedSlider.minimumValue = 1.0f; speedSlider.maximumValue = 15.0f; speedSlider.value = g_speedMultiplier;
        [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:speedSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"10. Khinh công / Nhảy cao" state:g_enableHighJump action:@selector(toggleHighJump:)]; yOffset += 38;

        jumpValLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yOffset, 310, 18)];
        jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Khinh công: %.1fx", g_jumpMultiplier];
        jumpValLabel.textColor = [UIColor yellowColor];
        jumpValLabel.font = [UIFont systemFontOfSize:12];
        jumpValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:jumpValLabel]; yOffset += 22;

        UISlider *jumpSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 310, 25)];
        jumpSlider.minimumValue = 1.0f; jumpSlider.maximumValue = 8.0f; jumpSlider.value = g_jumpMultiplier;
        [jumpSlider addTarget:self action:@selector(jumpChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:jumpSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"11. Đi xuyên địa hình (No-Clip)" state:g_enableNoClip action:@selector(toggleNoClip:)]; yOffset += 40;
        contentScroll.contentSize = CGSizeMake(330, yOffset + 20);

    } else if (currentTab == 2) {
        // --- TAB 3: WORLD (Thế giới, Tầm nhìn & Môi trường) ---
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"12. Hút Item toàn bản đồ" state:g_enableAutoLoot action:@selector(toggleAutoLoot:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"13. Tàng hình nhân vật" state:g_enableInvisibility action:@selector(toggleInvisibility:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"14. Đóng băng AI quái vật" state:g_enableEnemyFreeze action:@selector(toggleEnemyFreeze:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"15. Phóng to tầm nhìn Camera" state:g_enableZoomOut action:@selector(toggleZoomOut:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"16. Chế độ Camera tự do" state:g_enableFreeCam action:@selector(toggleFreeCam:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"17. Xóa vật cản (Occlusion Fix)" state:g_enableOcclusionFix action:@selector(toggleOcclusionFix:)]; yOffset += 40;
        contentScroll.contentSize = CGSizeMake(330, yOffset + 20);

    } else if (currentTab == 3) {
        // --- TAB 4: SYSTEM (Hệ thống, Tự động & Tiện ích) ---
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"18. Mở khóa FPS cao (60/120)" state:g_enableFPSUnlock action:@selector(toggleFPSUnlock:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"19. Tự động hóa Auto-Play / Bot" state:g_enableAutoBot action:@selector(toggleAutoBot:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"20. Tăng tốc thời gian game" state:g_enableGlobalTime action:@selector(toggleGlobalTime:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"21. Load cảnh phụ bản siêu tốc" state:g_enableFastLoad action:@selector(toggleFastLoad:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"22. Hack tài nguyên / tiền tệ" state:g_enableCurrencyHack action:@selector(toggleCurrencyHack:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"23. Mở khóa trang phục / Skin" state:g_enableSkinUnlock action:@selector(toggleSkinUnlock:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"24. Mở khóa thành tựu / danh hiệu" state:g_enableAchievement action:@selector(toggleAchievement:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"25. Lưu cấu hình cục bộ (Config)" state:g_enableSaveConfig action:@selector(toggleSaveConfig:)]; yOffset += 40;
        [self addToggleButton:CGRectMake(10, yOffset, 310, 32) title:@"26. Bỏ qua Anti-Cheat / Bảo mật" state:g_enableBypassCheat action:@selector(toggleBypassCheat:)]; yOffset += 40;
        contentScroll.contentSize = CGSizeMake(330, yOffset + 20);
    }
}

- (void)addToggleButton:(CGRect)frame title:(NSString *)title state:(bool)state action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", title, state ? @"BẬT" : @"TẮT"] forState:UIControlStateNormal];
    [btn setTitleColor:state ? [UIColor greenColor] : [UIColor lightGrayColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.15f alpha:1.0f];
    btn.layer.cornerRadius = 6.0f;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [contentScroll addSubview:btn];
}

// --- HÀNH ĐỘNG CHUYỂN TRẠNG THÁI ---
- (void)toggleGodMode:(UIButton *)sender { g_enableGodMode = !g_enableGodMode; [self reloadTabContent]; }
- (void)toggleOneHit:(UIButton *)sender { g_enableOneHit = !g_enableOneHit; [self reloadTabContent]; }
- (void)toggleHPRegen:(UIButton *)sender { g_enableHPRegen = !g_enableHPRegen; [self reloadTabContent]; }
- (void)toggleAntiStun:(UIButton *)sender { g_enableAntiStun = !g_enableAntiStun; [self reloadTabContent]; }
- (void)toggleFastAttack:(UIButton *)sender { g_enableFastAttack = !g_enableFastAttack; [self reloadTabContent]; }
- (void)toggleUnlimitedSkill:(UIButton *)sender { g_enableUnlimitedSkill = !g_enableUnlimitedSkill; [self reloadTabContent]; }
- (void)toggleTargetLock:(UIButton *)sender { g_enableTargetLock = !g_enableTargetLock; [self reloadTabContent]; }
- (void)toggleGlobalDamage:(UIButton *)sender { g_enableGlobalDamage = !g_enableGlobalDamage; [self reloadTabContent]; }

- (void)toggleSpeedHack:(UIButton *)sender { g_enableSpeedHack = !g_enableSpeedHack; [self reloadTabContent]; }
- (void)speedChanged:(UISlider *)sender { g_speedMultiplier = sender.value; speedValLabel.text = [NSString stringWithFormat:@"Hệ số Tốc độ: %.1fx", g_speedMultiplier]; }
- (void)toggleHighJump:(UIButton *)sender { g_enableHighJump = !g_enableHighJump; [self reloadTabContent]; }
- (void)jumpChanged:(UISlider *)sender { g_jumpMultiplier = sender.value; jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Khinh công: %.1fx", g_jumpMultiplier]; }
- (void)toggleNoClip:(UIButton *)sender { g_enableNoClip = !g_enableNoClip; [self reloadTabContent]; }

- (void)toggleAutoLoot:(UIButton *)sender { g_enableAutoLoot = !g_enableAutoLoot; [self reloadTabContent]; }
- (void)toggleInvisibility:(UIButton *)sender { g_enableInvisibility = !g_enableInvisibility; [self reloadTabContent]; }
- (void)toggleEnemyFreeze:(UIButton *)sender { g_enableEnemyFreeze = !g_enableEnemyFreeze; [self reloadTabContent]; }
- (void)toggleZoomOut:(UIButton *)sender { g_enableZoomOut = !g_enableZoomOut; [self reloadTabContent]; }
- (void)toggleFreeCam:(UIButton *)sender { g_enableFreeCam = !g_enableFreeCam; [self reloadTabContent]; }
- (void)toggleOcclusionFix:(UIButton *)sender { g_enableOcclusionFix = !g_enableOcclusionFix; [self reloadTabContent]; }

- (void)toggleFPSUnlock:(UIButton *)sender { g_enableFPSUnlock = !g_enableFPSUnlock; [self reloadTabContent]; }
- (void)toggleAutoBot:(UIButton *)sender { g_enableAutoBot = !g_enableAutoBot; [self reloadTabContent]; }
- (void)toggleGlobalTime:(UIButton *)sender { g_enableGlobalTime = !g_enableGlobalTime; [self reloadTabContent]; }
- (void)toggleFastLoad:(UIButton *)sender { g_enableFastLoad = !g_enableFastLoad; [self reloadTabContent]; }
- (void)toggleCurrencyHack:(UIButton *)sender { g_enableCurrencyHack = !g_enableCurrencyHack; [self reloadTabContent]; }
- (void)toggleSkinUnlock:(UIButton *)sender { g_enableSkinUnlock = !g_enableSkinUnlock; [self reloadTabContent]; }
- (void)toggleAchievement:(UIButton *)sender { g_enableAchievement = !g_enableAchievement; [self reloadTabContent]; }
- (void)toggleSaveConfig:(UIButton *)sender { g_enableSaveConfig = !g_enableSaveConfig; [self reloadTabContent]; }
- (void)toggleBypassCheat:(UIButton *)sender { g_enableBypassCheat = !g_enableBypassCheat; [self reloadTabContent]; }

@end

// --- NÚT NỔI KÉO THẢ (DRAGGABLE BUTTON) ---
@interface DraggableButton : UIButton
@end

@implementation DraggableButton {
    CGPoint touchLocation;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    touchLocation = [[touches anyObject] locationInView:self.superview];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint curr = [[touches anyObject] locationInView:self.superview];
    CGFloat dx = curr.x - touchLocation.x;
    CGFloat dy = curr.y - touchLocation.y;
    self.center = CGPointMake(self.center.x + dx, self.center.y + dy);
    touchLocation = curr;
}
@end

// --- KHỞI TẠO AN TOÀN BẰNG CONSTRUCTOR CHUẨN C ---
__attribute__((constructor)) static void init_sheepct_mod() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *win in windowScene.windows) {
                    if (win.isKeyWindow) {
                        targetWindow = win;
                        break;
                    }
                }
            }
        }
        if (!targetWindow) {
            targetWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!targetWindow) return;

        DraggableButton *floatingBtn = [DraggableButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(15, 120, 50, 50);
        floatingBtn.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.15f alpha:0.9f];
        [floatingBtn setTitle:@"👑" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont systemFontOfSize:22];
        floatingBtn.layer.cornerRadius = 25.0f;
        floatingBtn.layer.borderWidth = 1.8f;
        floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;

        [floatingBtn addTarget:[SheepctModMenuController sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [targetWindow addSubview:floatingBtn];
    });
}
