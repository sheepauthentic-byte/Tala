#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- 1. BIẾN TRẠNG THÁI 26 TÍNH NĂNG (ĐÃ VIỆT HÓA) ---
static bool g_enableGodMode = false;          // 1. Kháng sát thương (God Mode)
static bool g_enableSpeedHack = false;        // 2. Tốc độ di chuyển
static bool g_enableInvisibility = false;     // 3. Tàng hình nhân vật
static bool g_enableHighJump = false;         // 4. Khinh công / Nhảy cao
static bool g_enableAutoLoot = false;         // 5. Hút item toàn bản đồ
static bool g_enableHPRegen = false;          // 6. Khóa máu / Hồi phục HP
static bool g_enableFPSUnlock = false;        // 7. Mở khóa FPS cao
static bool g_enableOneHit = false;           // 8. Đánh 1 hit chết luôn
static bool g_enableAntiStun = false;         // 9. Chống khống chế (Anti-Stun)
static bool g_enableZoomOut = false;          // 10. Phóng to tầm nhìn Camera
static bool g_enableFastAttack = false;       // 11. Tấn công siêu tốc (No Delay)
static bool g_enableUnlimitedSkill = false;   // 12. Hồi chiêu kỹ năng 0 giây
static bool g_enableFreeCam = false;         // 13. Camera tự do thám hiểm
static bool g_enableAutoBot = false;          // 14. Tự động hóa Auto-Play / Bot
static bool g_enableSaveConfig = false;       // 15. Lưu cấu hình cục bộ
static bool g_enableBypassCheat = false;      // 16. Bỏ qua kiểm tra Anti-Cheat
static bool g_enableSkinUnlock = false;       // 17. Mở khóa trang phục hiển thị
static bool g_enableCurrencyHack = false;     // 18. Khóa/Tăng tài nguyên tiền tệ
static bool g_enableAchievement = false;      // 19. Mở khóa thành tựu / danh hiệu
static bool g_enableFastLoad = false;         // 20. Load cảnh phụ bản siêu tốc
static bool g_enableGlobalTime = false;       // 21. Tua nhanh thời gian game
static bool g_enableNoClip = false;           // 22. Đi xuyên tường / vật thể
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
    NSMutableArray *tabButtons;
}

+ (instancetype)sharedInstance {
    static SheepctModMenuController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[SheepctModMenuController alloc] init];
        shared->currentTab = 0;
        shared->tabButtons = [NSMutableArray array];
    });
    return shared;
}

- (void)toggleMenu {
    if (self.menuWindow) {
        self.menuWindow.hidden = !self.menuWindow.hidden;
        return;
    }

    self.menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(30, 80, 340, 480)];
    self.menuWindow.windowLevel = UIWindowLevelAlert + 1;
    self.menuWindow.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [[UIViewController alloc] init];
    self.menuWindow.rootViewController = vc;

    mainView = [[UIView alloc] initWithFrame:vc.view.bounds];
    mainView.backgroundColor = [UIColor colorWithRed:0.06f green:0.06f blue:0.09f alpha:0.95f];
    mainView.layer.cornerRadius = 18.0f;
    mainView.layer.borderWidth = 1.5f;
    mainView.layer.borderColor = [UIColor colorWithRed:0.0f green:0.8f blue:1.0f alpha:0.8f].CGColor;
    mainView.layer.shadowColor = [UIColor blackColor].CGColor;
    mainView.layer.shadowOpacity = 0.5f;
    mainView.layer.shadowOffset = CGSizeMake(0, 6);
    mainView.layer.shadowRadius = 10.0f;
    [vc.view addSubview:mainView];

    // Tiêu đề Menu
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 316, 22)];
    titleLabel.text = @"👑 Sheepct Mod - Tiếng Việt";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:titleLabel];

    // Tác giả
    UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 34, 316, 16)];
    authorLabel.text = @"Tool do TRẦN MẠNH CƯỜNG phát triển";
    authorLabel.textColor = [UIColor colorWithRed:0.0f green:0.8f blue:1.0f alpha:1.0f];
    authorLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    authorLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:authorLabel];

    // Thanh Tab phân loại (Việt hóa danh mục)
    NSArray *tabs = @[@"Chiến đấu", @"Di chuyển", @"Thế giới", @"Hệ thống"];
    CGFloat tabWidth = 316.0f / tabs.count;
    [tabButtons removeAllObjects];
    
    for (int i = 0; i < tabs.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(12 + i * tabWidth, 58, tabWidth - 4, 30);
        [tabBtn setTitle:tabs[i] forState:UIControlStateNormal];
        tabBtn.tag = i;
        tabBtn.titleLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightBold];
        [tabBtn addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventTouchUpInside];
        tabBtn.layer.cornerRadius = 8.0f;
        [mainView addSubview:tabBtn];
        [tabButtons addObject:tabBtn];
    }

    // Scroll chứa danh sách tính năng
    contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(12, 98, 316, 330)];
    contentScroll.backgroundColor = [UIColor clearColor];
    contentScroll.showsVerticalScrollIndicator = YES;
    [mainView addSubview:contentScroll];

    [self updateTabStyles];
    [self reloadTabContent];

    // Nút ẩn Menu nhanh
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(95, 436, 150, 32);
    [closeBtn setTitle:@"Ẩn Menu Nhanh" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor colorWithRed:1.0f green:0.3f blue:0.3f alpha:1.0f] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    closeBtn.backgroundColor = [UIColor colorWithRed:0.15f green:0.08f blue:0.08f alpha:0.8f];
    closeBtn.layer.cornerRadius = 8.0f;
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:closeBtn];

    self.menuWindow.hidden = NO;
}

- (void)switchTab:(UIButton *)sender {
    currentTab = (int)sender.tag;
    [self updateTabStyles];
    [self reloadTabContent];
}

- (void)updateTabStyles {
    for (int i = 0; i < tabButtons.count; i++) {
        UIButton *btn = tabButtons[i];
        if (i == currentTab) {
            btn.backgroundColor = [UIColor colorWithRed:0.0f green:0.5f blue:0.8f alpha:1.0f];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            btn.backgroundColor = [UIColor colorWithRed:0.12f green:0.12f blue:0.18f alpha:1.0f];
            [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
    }
}

- (void)reloadTabContent {
    for (UIView *sub in contentScroll.subviews) {
        [sub removeFromSuperview];
    }

    CGFloat yOffset = 10;
    
    if (currentTab == 0) {
        // --- TAB 1: CHIẾN ĐẤU (COMBAT) ---
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"1. Kháng sát thương (God Mode)" state:g_enableGodMode action:@selector(toggleGodMode:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"2. Sát thương cực lớn (One-Hit)" state:g_enableOneHit action:@selector(toggleOneHit:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"3. Khóa máu / Hồi phục HP" state:g_enableHPRegen action:@selector(toggleHPRegen:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"4. Chống khống chế (Anti-Stun)" state:g_enableAntiStun action:@selector(toggleAntiStun:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"5. Tấn công siêu tốc (No Delay)" state:g_enableFastAttack action:@selector(toggleFastAttack:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"6. Hồi chiêu kỹ năng 0 giây" state:g_enableUnlimitedSkill action:@selector(toggleUnlimitedSkill:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"7. Khóa mục tiêu tự động" state:g_enableTargetLock action:@selector(toggleTargetLock:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"8. Tăng sát thương toàn cục" state:g_enableGlobalDamage action:@selector(toggleGlobalDamage:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);

    } else if (currentTab == 1) {
        // --- TAB 2: DI CHUYỂN (MOVEMENT) ---
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"9. Tốc độ di chuyển (Speed)" state:g_enableSpeedHack action:@selector(toggleSpeedHack:)]; yOffset += 40;
        
        speedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, 316, 18)];
        speedValLabel.text = [NSString stringWithFormat:@"Hệ số Tốc độ: %.1fx", g_speedMultiplier];
        speedValLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f];
        speedValLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        speedValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:speedValLabel]; yOffset += 22;

        UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 296, 25)];
        speedSlider.minimumValue = 1.0f; speedSlider.maximumValue = 15.0f; speedSlider.value = g_speedMultiplier;
        [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:speedSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"10. Khinh công / Nhảy cao" state:g_enableHighJump action:@selector(toggleHighJump:)]; yOffset += 40;

        jumpValLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, 316, 18)];
        jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Nhảy cao: %.1fx", g_jumpMultiplier];
        jumpValLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f];
        jumpValLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        jumpValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:jumpValLabel]; yOffset += 22;

        UISlider *jumpSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 296, 25)];
        jumpSlider.minimumValue = 1.0f; jumpSlider.maximumValue = 8.0f; jumpSlider.value = g_jumpMultiplier;
        [jumpSlider addTarget:self action:@selector(jumpChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:jumpSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"11. Đi xuyên tường (No-Clip)" state:g_enableNoClip action:@selector(toggleNoClip:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);

    } else if (currentTab == 2) {
        // --- TAB 3: THẾ GIỚI (WORLD) ---
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"12. Hút vật phẩm toàn bản đồ" state:g_enableAutoLoot action:@selector(toggleAutoLoot:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"13. Tàng hình nhân vật" state:g_enableInvisibility action:@selector(toggleInvisibility:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"14. Đóng băng AI kẻ địch" state:g_enableEnemyFreeze action:@selector(toggleEnemyFreeze:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"15. Phóng to tầm nhìn Camera" state:g_enableZoomOut action:@selector(toggleZoomOut:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"16. Chế độ Camera tự do" state:g_enableFreeCam action:@selector(toggleFreeCam:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"17. Xóa vật cản tầm nhìn" state:g_enableOcclusionFix action:@selector(toggleOcclusionFix:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);

    } else if (currentTab == 3) {
        // --- TAB 4: HỆ THỐNG (SYSTEM) ---
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"18. Mở khóa FPS cao (60/120)" state:g_enableFPSUnlock action:@selector(toggleFPSUnlock:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"19. Tự động hóa Auto-Play" state:g_enableAutoBot action:@selector(toggleAutoBot:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"20. Tăng tốc thời gian game" state:g_enableGlobalTime action:@selector(toggleGlobalTime:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"21. Load cảnh phụ bản siêu tốc" state:g_enableFastLoad action:@selector(toggleFastLoad:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"22. Hack tài nguyên / tiền tệ" state:g_enableCurrencyHack action:@selector(toggleCurrencyHack:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"23. Mở khóa trang phục / Skin" state:g_enableSkinUnlock action:@selector(toggleSkinUnlock:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"24. Mở khóa thành tựu danh hiệu" state:g_enableAchievement action:@selector(toggleAchievement:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"25. Lưu cấu hình cục bộ" state:g_enableSaveConfig action:@selector(toggleSaveConfig:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"26. Bỏ qua Anti-Cheat / Bảo mật" state:g_enableBypassCheat action:@selector(toggleBypassCheat:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);
    }
}

- (void)addToggleButton:(CGRect)frame title:(NSString *)title state:(bool)state action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", title, state ? @"[ ĐÃ BẬT ]" : @"[ ĐÃ TẮT ]"] forState:UIControlStateNormal];
    
    if (state) {
        [btn setTitleColor:[UIColor colorWithRed:0.2f green:1.0f blue:0.4f alpha:1.0f] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:0.08f green:0.25f blue:0.12f alpha:0.9f];
    } else {
        [btn setTitleColor:[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:0.12f green:0.12f blue:0.18f alpha:0.9f];
    }
    
    btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    btn.layer.cornerRadius = 8.0f;
    btn.layer.borderWidth = 0.8f;
    btn.layer.borderColor = state ? [UIColor colorWithRed:0.2f green:1.0f blue:0.4f alpha:0.5f].CGColor : [UIColor colorWithWhite:0.25f alpha:1.0f].CGColor;
    
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
- (void)jumpChanged:(UISlider *)sender { g_jumpMultiplier = sender.value; jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Nhảy cao: %.1fx", g_jumpMultiplier]; }
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

// --- NÚT NỔI KÉO THẢ MƯỢT MÀ ---
@interface DraggableButton : UIButton
@end

@implementation DraggableButton {
    CGPoint touchLocation;
    BOOL isDragging;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isDragging = NO;
    touchLocation = [[touches anyObject] locationInView:self.superview];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint curr = [[touches anyObject] locationInView:self.superview];
    CGFloat dx = curr.x - touchLocation.x;
    CGFloat dy = curr.y - touchLocation.y;
    if (ABS(dx) > 2.0 || ABS(dy) > 2.0) {
        isDragging = YES;
    }
    
    CGFloat newX = self.center.x + dx;
    CGFloat newY = self.center.y + dy;
    
    if (self.superview) {
        CGSize boundSize = self.superview.bounds.size;
        newX = MAX(25.0f, MIN(boundSize.width - 25.0f, newX));
        newY = MAX(35.0f, MIN(boundSize.height - 35.0f, newY));
    }
    
    self.center = CGPointMake(newX, newY);
    touchLocation = curr;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!isDragging) {
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}
@end

// --- KHỞI TẠO AN TOÀN CHO GAME ---
__attribute__((constructor)) static void init_sheepct_mod() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            targetWindow = window;
                            break;
                        }
                    }
                }
            }
        }
        
        if (!targetWindow) {
            targetWindow = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!targetWindow && [UIApplication sharedApplication].delegate.window) {
            targetWindow = [UIApplication sharedApplication].delegate.window;
        }

        if (!targetWindow) return;

        DraggableButton *floatingBtn = [DraggableButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(20, 120, 48, 48);
        floatingBtn.backgroundColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.12f alpha:0.95f];
        [floatingBtn setTitle:@"👑" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont systemFontOfSize:22];
        floatingBtn.layer.cornerRadius = 24.0f;
        floatingBtn.layer.borderWidth = 1.8f;
        floatingBtn.layer.borderColor = [UIColor colorWithRed:0.0f green:0.8f blue:1.0f alpha:1.0f].CGColor;
        floatingBtn.layer.shadowColor = [UIColor colorWithRed:0.0f green:0.8f blue:1.0f alpha:0.5f].CGColor;
        floatingBtn.layer.shadowOpacity = 0.8f;
        floatingBtn.layer.shadowOffset = CGSizeMake(0, 0);
        floatingBtn.layer.shadowRadius = 6.0f;

        [floatingBtn addTarget:[SheepctModMenuController sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [targetWindow addSubview:floatingBtn];
        [targetWindow bringSubviewToFront:floatingBtn];
    });
}
