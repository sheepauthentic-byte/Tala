#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include "dobby.h"

// --- 1. BIẾN TRẠNG THÁI TOÀN CỤC ---
static bool g_enableGodMode = false;          // 1. Kháng sát thương
static bool g_enableSpeedHack = false;        // 2. Tốc độ di chuyển
static bool g_enableHighJump = false;         // 3. Nhảy cao / Khinh công
static bool g_enableGameSpeed = false;        // 4. Tăng tốc độ toàn cục game
static bool g_enableNoCameraShake = false;    // 5. Tắt rung màn hình
static bool g_enableNoHalt = false;           // 6. Chống khựng chuyển động
static bool g_enableFootsteps = false;        // 7. Âm thanh bước chân
static bool g_enableSceneFade = false;        // 8. Hiệu ứng chuyển cảnh
static bool g_enableBlink = false;            // 9. Chớp sáng nhân vật
static bool g_enableForceLanding = false;     // 10. Ép hạ cánh tức thì

static float g_speedMultiplier = 1.0f;        
static float g_jumpMultiplier = 1.0f;         
static float g_gameSpeedScale = 1.0f;         

static uintptr_t get_unity_slide() {
    uint32_t image_count = _dyld_image_count();
    for (uint32_t i = 0; i < image_count; i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (image_name && strstr(image_name, "UnityFramework")) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// ==========================================
// --- 2. HỆ THỐNG HOOK THẬT CHO TỪNG HÀM ---
// ==========================================

static void (*orig_ActorController_PlayHurt)(void *self, void *ppd, void *cb);
static void hook_ActorController_PlayHurt(void *self, void *ppd, void *cb) {
    if (g_enableGodMode) return;
    orig_ActorController_PlayHurt(self, ppd, cb);
}

static void (*orig_ActorQingGong_FixedUpdate)(void *self);
static void hook_ActorQingGong_FixedUpdate(void *self) {
    if (self) {
        uintptr_t instance = (uintptr_t)self;
        if (g_enableSpeedHack) {
            float *speedPtr = (float *)(instance + 0x18);
            if (speedPtr) *speedPtr = 6.0f * g_speedMultiplier;
        }
        if (g_enableHighJump) {
            float *gravityPtr = (float *)(instance + 0x1C);
            if (gravityPtr) *gravityPtr = 1.0f / g_jumpMultiplier;
        }
    }
    orig_ActorQingGong_FixedUpdate(self);
}

static void (*orig_Time_set_timeScale)(float value);
static void hook_Time_set_timeScale(float value) {
    if (g_enableGameSpeed) {
        orig_Time_set_timeScale(g_gameSpeedScale);
        return;
    }
    orig_Time_set_timeScale(value);
}

static void (*orig_ActorController_EnableCameraShake)(void *self, bool enable);
static void hook_ActorController_EnableCameraShake(void *self, bool enable) {
    if (g_enableNoCameraShake) enable = false;
    orig_ActorController_EnableCameraShake(self, enable);
}

static void (*orig_ActorController_EnableHalt)(void *self, bool enable);
static void hook_ActorController_EnableHalt(void *self, bool enable) {
    if (g_enableNoHalt) enable = false;
    orig_ActorController_EnableHalt(self, enable);
}

static void (*orig_ActorController_EnableFootsteps)(void *self, bool enable);
static void hook_ActorController_EnableFootsteps(void *self, bool enable) {
    if (g_enableFootsteps) enable = true;
    orig_ActorController_EnableFootsteps(self, enable);
}

static void (*orig_ActorController_EnableSceneFade)(void *self, bool enable);
static void hook_ActorController_EnableSceneFade(void *self, bool enable) {
    if (g_enableSceneFade) enable = true;
    orig_ActorController_EnableSceneFade(self, enable);
}

static void (*orig_ActorController_Blink)(void *self);
static void hook_ActorController_Blink(void *self) {
    if (g_enableBlink) {}
    orig_ActorController_Blink(self);
}

static void (*orig_ActorQingGong_ForceLanding)(void *self);
static void hook_ActorQingGong_ForceLanding(void *self) {
    if (g_enableForceLanding) {}
    orig_ActorQingGong_ForceLanding(self);
}

// ==========================================
// --- 3. GIAO DIỆN NATIVE UIKIT CYBER MENU ---
// ==========================================
@interface NativeCyberMenu : NSObject
@property (nonatomic, strong) UIWindow *menuWindow;
+ (instancetype)sharedInstance;
- (void)toggleMenu;
@end

@implementation NativeCyberMenu {
    UIView *panelView;
}

+ (instancetype)sharedInstance {
    static NativeCyberMenu *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[NativeCyberMenu alloc] init];
    });
    return shared;
}

- (void)toggleMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.menuWindow) {
            self.menuWindow.hidden = !self.menuWindow.hidden;
            return;
        }

        // Cửa sổ UIWindow độc lập
        self.menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(15, 40, 360, 520)];
        self.menuWindow.windowLevel = UIWindowLevelStatusBar + 500;
        self.menuWindow.backgroundColor = [UIColor clearColor];

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        self.menuWindow.rootViewController = vc;

        // Container chính
        panelView = [[UIView alloc] initWithFrame:vc.view.bounds];
        panelView.backgroundColor = [UIColor colorWithRed:0.06f green:0.06f blue:0.09f alpha:0.96f];
        panelView.layer.cornerRadius = 22.0f;
        panelView.layer.borderWidth = 1.5f;
        panelView.layer.borderColor = [UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:0.8f].CGColor;
        [vc.view addSubview:panelView];

        // Tiêu đề
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 330, 24)];
        titleLabel.text = @"👑 SHEEPCT MOD MENU (TRẦN MẠNH CƯỜNG)";
        titleLabel.textColor = [UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:1.0f];
        titleLabel.font = [UIFont boldSystemFontOfSize:12];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [panelView addSubview:titleLabel];

        // ScrollView chứa danh sách các chức năng
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 45, 340, 410)];
        scrollView.contentSize = CGSizeMake(320, 780);
        scrollView.showsVerticalScrollIndicator = YES;
        [panelView addSubview:scrollView];

        CGFloat yPos = 10;
        NSArray *features = @[
            @{@"title": @"1. Kháng sát thương (God Mode)", @"key": @1},
            @{@"title": @"2. Tốc độ di chuyển (Speed Hack)", @"key": @2},
            @{@"title": @"3. Khinh công / Nhảy cao", @"key": @3},
            @{@"title": @"4. Tăng tốc độ Game (TimeScale)", @"key": @4},
            @{@"title": @"5. Tắt rung màn hình", @"key": @5},
            @{@"title": @"6. Chống khựng chuyển động", @"key": @6},
            @{@"title": @"7. Âm thanh bước chân", @"key": @7},
            @{@"title": @"8. Hiệu ứng chuyển cảnh", @"key": @8},
            @{@"title": @"9. Chớp sáng nhân vật", @"key": @9},
            @{@"title": @"10. Ép hạ cánh tức thì", @"key": @10}
        ];

        for (NSDictionary *feat in features) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(10, yPos, 320, 40);
            [btn setTitle:[NSString stringWithFormat:@"[ TẮT ] %@", feat[@"title"]] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor colorWithRed:0.18f green:0.18f blue:0.24f alpha:1.0f];
            btn.layer.cornerRadius = 10.0f;
            btn.tag = [feat[@"key"] integerValue];
            [btn addTarget:self action:@selector(onToggleFeature:) forControlEvents:UIControlEventTouchUpInside];
            [scrollView addSubview:btn];
            yPos += 50;
        }

        // Nút Đóng Menu
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(105, 465, 150, 42);
        [closeBtn setTitle:@"✕ ĐÓNG MENU" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        closeBtn.backgroundColor = [UIColor colorWithRed:1.0f green:0.18f blue:0.31f alpha:0.9f];
        closeBtn.layer.cornerRadius = 12.0f;
        [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [panelView addSubview:closeBtn];

        self.menuWindow.hidden = NO;
    });
}

- (void)onToggleFeature:(UIButton *)sender {
    NSInteger tag = sender.tag;
    bool newState = false;

    switch (tag) {
        case 1: g_enableGodMode = !g_enableGodMode; newState = g_enableGodMode; break;
        case 2: g_enableSpeedHack = !g_enableSpeedHack; newState = g_enableSpeedHack; break;
        case 3: g_enableHighJump = !g_enableHighJump; newState = g_enableHighJump; break;
        case 4: g_enableGameSpeed = !g_enableGameSpeed; newState = g_enableGameSpeed; g_gameSpeedScale = newState ? 2.0f : 1.0f; break;
        case 5: g_enableNoCameraShake = !g_enableNoCameraShake; newState = g_enableNoCameraShake; break;
        case 6: g_enableNoHalt = !g_enableNoHalt; newState = g_enableNoHalt; break;
        case 7: g_enableFootsteps = !g_enableFootsteps; newState = g_enableFootsteps; break;
        case 8: g_enableSceneFade = !g_enableSceneFade; newState = g_enableSceneFade; break;
        case 9: g_enableBlink = !g_enableBlink; newState = g_enableBlink; break;
        case 10: g_enableForceLanding = !g_enableForceLanding; newState = g_enableForceLanding; break;
        default: break;
    }

    NSString *titleText = sender.currentTitle;
    // Cập nhật nhãn nút bấm
    NSRange range = [titleText rangeOfString:@"] "];
    if (range.location != NSNotFound) {
        NSString *pureTitle = [titleText substringFromIndex:range.location + range.length];
        if (newState) {
            [sender setTitle:[NSString stringWithFormat:@"[ ĐÃ BẬT ] %@", pureTitle] forState:UIControlStateNormal];
            sender.backgroundColor = [UIColor colorWithRed:0.0f green:0.5f blue:0.2f alpha:1.0f];
        } else {
            [sender setTitle:[NSString stringWithFormat:@"[ TẮT ] %@", pureTitle] forState:UIControlStateNormal];
            sender.backgroundColor = [UIColor colorWithRed:0.18f green:0.18f blue:0.24f alpha:1.0f];
        }
    }
}

@end

// --- 4. NÚT NỔI KÉO THẢ ---
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
    if (ABS(dx) > 2.0 || ABS(dy) > 2.0) isDragging = YES;
    
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
    if (!isDragging) [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}
@end

// --- 5. KHỞI TẠO AN TOÀN ---
__attribute__((constructor)) static void init_sheepct_mod() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Hook Dobby an toàn
        uintptr_t slide = get_unity_slide();
        if (slide > 0) {
            DobbyHook((void *)(slide + 0x33561BC), (void *)&hook_ActorController_PlayHurt, (void **)&orig_ActorController_PlayHurt);
            DobbyHook((void *)(slide + 0x40BA3A8), (void *)&hook_ActorQingGong_FixedUpdate, (void **)&orig_ActorQingGong_FixedUpdate);
            DobbyHook((void *)(slide + 0x3354B7C), (void *)&hook_ActorController_EnableCameraShake, (void **)&orig_ActorController_EnableCameraShake);
            DobbyHook((void *)(slide + 0x33551DC), (void *)&hook_ActorController_EnableHalt, (void **)&orig_ActorController_EnableHalt);
            DobbyHook((void *)(slide + 0x3356458), (void *)&hook_ActorController_EnableFootsteps, (void **)&orig_ActorController_EnableFootsteps);
            DobbyHook((void *)(slide + 0x33589A0), (void *)&hook_ActorController_EnableSceneFade, (void **)&orig_ActorController_EnableSceneFade);
            DobbyHook((void *)(slide + 0x3354ADC), (void *)&hook_ActorController_Blink, (void **)&orig_ActorController_Blink);
            DobbyHook((void *)(slide + 0x40BAD00), (void *)&hook_ActorQingGong_ForceLanding, (void **)&orig_ActorQingGong_ForceLanding);
        }

        void *timeScaleSym = dlsym(RTLD_DEFAULT, "_ZN4Time12set_timeScaleEf");
        if (!timeScaleSym) {
            timeScaleSym = dlsym(RTLD_DEFAULT, "Time_set_timeScale_m35EE0403AD");
        }
        if (timeScaleSym) {
            DobbyHook(timeScaleSym, (void *)&hook_Time_set_timeScale, (void **)&orig_Time_set_timeScale);
        }

        // Tạo nút nổi mở menu
        UIWindow *targetWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *win in ((UIWindowScene *)scene).windows) {
                        if (win.isKeyWindow) { targetWindow = win; break; }
                    }
                }
            }
        }
        if (!targetWindow) targetWindow = [UIApplication sharedApplication].keyWindow;
        if (!targetWindow) return;

        DraggableButton *floatingBtn = [DraggableButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(20, 120, 48, 48);
        floatingBtn.backgroundColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.12f alpha:0.95f];
        [floatingBtn setTitle:@"C" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
        [floatingBtn setTitleColor:[UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:1.0f] forState:UIControlStateNormal];
        floatingBtn.layer.cornerRadius = 24.0f;
        floatingBtn.layer.borderWidth = 1.8f;
        floatingBtn.layer.borderColor = [UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:1.0f].CGColor;

        [floatingBtn addTarget:[NativeCyberMenu sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [targetWindow addSubview:floatingBtn];
        [targetWindow bringSubviewToFront:floatingBtn];
    });
}
