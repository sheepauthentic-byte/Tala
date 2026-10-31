#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include "dobby.h"

static bool g_enableGodMode = false;
static bool g_enableSpeedHack = false;
static bool g_enableHighJump = false;
static bool g_enableGameSpeed = false;
static bool g_enableNoCameraShake = false;
static bool g_enableNoHalt = false;
static bool g_enableFootsteps = false;
static bool g_enableSceneFade = false;
static bool g_enableBlink = false;
static bool g_enableForceLanding = false;

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
    UILabel *gameSpeedValLabel;
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
    [vc.view addSubview:mainView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 316, 22)];
    titleLabel.text = @"👑 Sheepct Mod - Full Hook & Speed";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:13];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:titleLabel];

    UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 34, 316, 16)];
    authorLabel.text = @"Tool do TRẦN MẠNH CƯỜNG phát triển";
    authorLabel.textColor = [UIColor colorWithRed:0.0f green:0.8f blue:1.0f alpha:1.0f];
    authorLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    authorLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:authorLabel];

    NSArray *tabs = @[@"Chiến đấu", @"Di chuyển", @"Hệ thống"];
    CGFloat tabWidth = 316.0f / tabs.count;
    [tabButtons removeAllObjects];
    
    for (int i = 0; i < tabs.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(12 + i * tabWidth, 58, tabWidth - 4, 30);
        [tabBtn setTitle:tabs[i] forState:UIControlStateNormal];
        tabBtn.tag = i;
        tabBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [tabBtn addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventTouchUpInside];
        tabBtn.layer.cornerRadius = 8.0f;
        [mainView addSubview:tabBtn];
        [tabButtons addObject:tabBtn];
    }

    contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(12, 98, 316, 330)];
    contentScroll.backgroundColor = [UIColor clearColor];
    contentScroll.showsVerticalScrollIndicator = YES;
    [mainView addSubview:contentScroll];

    [self updateTabStyles];
    [self reloadTabContent];

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
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"1. Kháng sát thương (God Mode)" state:g_enableGodMode action:@selector(toggleGodMode:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);

    } else if (currentTab == 1) {
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"2. Tốc độ di chuyển (Speed)" state:g_enableSpeedHack action:@selector(toggleSpeedHack:)]; yOffset += 40;
        
        speedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, 316, 18)];
        speedValLabel.text = [NSString stringWithFormat:@"Hệ số Tốc độ: %.1fx", g_speedMultiplier];
        speedValLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f];
        speedValLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        speedValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:speedValLabel]; yOffset += 22;

        UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 296, 25)];
        speedSlider.minimumValue = 1.0f; speedSlider.maximumValue = 10.0f; speedSlider.value = g_speedMultiplier;
        [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:speedSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"3. Khinh công / Nhảy cao" state:g_enableHighJump action:@selector(toggleHighJump:)]; yOffset += 40;

        jumpValLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, 316, 18)];
        jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Nhảy cao: %.1fx", g_jumpMultiplier];
        jumpValLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f];
        jumpValLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        jumpValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:jumpValLabel]; yOffset += 22;

        UISlider *jumpSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 296, 25)];
        jumpSlider.minimumValue = 1.0f; jumpSlider.maximumValue = 5.0f; jumpSlider.value = g_jumpMultiplier;
        [jumpSlider addTarget:self action:@selector(jumpChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:jumpSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"4. Ép hạ cánh tức thì" state:g_enableForceLanding action:@selector(toggleForceLanding:)]; yOffset += 44;
        contentScroll.contentSize = CGSizeMake(316, yOffset + 10);

    } else if (currentTab == 2) {
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"5. Tăng tốc độ toàn cục game" state:g_enableGameSpeed action:@selector(toggleGameSpeed:)]; yOffset += 40;

        gameSpeedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset, 316, 18)];
        gameSpeedValLabel.text = [NSString stringWithFormat:@"Tốc độ Game: %.1fx", g_gameSpeedScale];
        gameSpeedValLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f];
        gameSpeedValLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        gameSpeedValLabel.textAlignment = NSTextAlignmentCenter;
        [contentScroll addSubview:gameSpeedValLabel]; yOffset += 22;

        UISlider *gameSpeedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, yOffset, 296, 25)];
        gameSpeedSlider.minimumValue = 1.0f; gameSpeedSlider.maximumValue = 10.0f; gameSpeedSlider.value = g_gameSpeedScale;
        [gameSpeedSlider addTarget:self action:@selector(gameSpeedChanged:) forControlEvents:UIControlEventValueChanged];
        [contentScroll addSubview:gameSpeedSlider]; yOffset += 35;

        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"6. Tắt rung màn hình" state:g_enableNoCameraShake action:@selector(toggleNoCameraShake:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"7. Chống khựng chuyển động" state:g_enableNoHalt action:@selector(toggleNoHalt:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"8. Âm thanh bước chân" state:g_enableFootsteps action:@selector(toggleFootsteps:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"9. Hiệu ứng chuyển cảnh" state:g_enableSceneFade action:@selector(toggleSceneFade:)]; yOffset += 44;
        [self addToggleButton:CGRectMake(0, yOffset, 316, 36) title:@"10. Chớp sáng nhân vật (Blink)" state:g_enableBlink action:@selector(toggleBlink:)]; yOffset += 44;
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

- (void)toggleGodMode:(UIButton *)sender { g_enableGodMode = !g_enableGodMode; [self reloadTabContent]; }
- (void)toggleSpeedHack:(UIButton *)sender { g_enableSpeedHack = !g_enableSpeedHack; [self reloadTabContent]; }
- (void)speedChanged:(UISlider *)sender { g_speedMultiplier = sender.value; speedValLabel.text = [NSString stringWithFormat:@"Hệ số Tốc độ: %.1fx", g_speedMultiplier]; }
- (void)toggleHighJump:(UIButton *)sender { g_enableHighJump = !g_enableHighJump; [self reloadTabContent]; }
- (void)jumpChanged:(UISlider *)sender { g_jumpMultiplier = sender.value; jumpValLabel.text = [NSString stringWithFormat:@"Hệ số Nhảy cao: %.1fx", g_jumpMultiplier]; }
- (void)toggleForceLanding:(UIButton *)sender { g_enableForceLanding = !g_enableForceLanding; [self reloadTabContent]; }
- (void)toggleGameSpeed:(UIButton *)sender { g_enableGameSpeed = !g_enableGameSpeed; [self reloadTabContent]; }
- (void)gameSpeedChanged:(UISlider *)sender { g_gameSpeedScale = sender.value; gameSpeedValLabel.text = [NSString stringWithFormat:@"Tốc độ Game: %.1fx", g_gameSpeedScale]; }
- (void)toggleNoCameraShake:(UIButton *)sender { g_enableNoCameraShake = !g_enableNoCameraShake; [self reloadTabContent]; }
- (void)toggleNoHalt:(UIButton *)sender { g_enableNoHalt = !g_enableNoHalt; [self reloadTabContent]; }
- (void)toggleFootsteps:(UIButton *)sender { g_enableFootsteps = !g_enableFootsteps; [self reloadTabContent]; }
- (void)toggleSceneFade:(UIButton *)sender { g_enableSceneFade = !g_enableSceneFade; [self reloadTabContent]; }
- (void)toggleBlink:(UIButton *)sender { g_enableBlink = !g_enableBlink; [self reloadTabContent]; }

@end

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

__attribute__((constructor)) static void init_sheepct_mod() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
        if (!targetWindow) targetWindow = [UIApplication sharedApplication].keyWindow;
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

        [floatingBtn addTarget:[SheepctModMenuController sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [targetWindow addSubview:floatingBtn];
        [targetWindow bringSubviewToFront:floatingBtn];
    });
}
