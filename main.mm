#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
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

// 1. PlayHurt (God Mode)
static void (*orig_ActorController_PlayHurt)(void *self, void *ppd, void *cb);
static void hook_ActorController_PlayHurt(void *self, void *ppd, void *cb) {
    if (g_enableGodMode) return;
    orig_ActorController_PlayHurt(self, ppd, cb);
}

// 2. FixedUpdate (Speed & Jump)
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

// 3. Game Speed Hack (Time.set_timeScale)
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
// --- 3. GIAO DIỆN WEBVIEW MOD MENU ---
// ==========================================
@interface WebModMenuController : NSObject <WKScriptMessageHandler, WKNavigationDelegate>
@property (nonatomic, strong) UIWindow *menuWindow;
+ (instancetype)sharedInstance;
- (void)toggleMenu;
@end

@implementation WebModMenuController {
    WKWebView *webView;
}

+ (instancetype)sharedInstance {
    static WebModMenuController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[WebModMenuController alloc] init];
    });
    return shared;
}

- (void)toggleMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.menuWindow) {
            self.menuWindow.hidden = !self.menuWindow.hidden;
            return;
        }

        self.menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 60, 345, 450)];
        self.menuWindow.windowLevel = UIWindowLevelStatusBar + 200;
        self.menuWindow.backgroundColor = [UIColor clearColor];

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        self.menuWindow.rootViewController = vc;

        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"modCallback"];

        webView = [[WKWebView alloc] initWithFrame:vc.view.bounds configuration:config];
        webView.backgroundColor = [UIColor clearColor];
        webView.scrollView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;

        NSString *htmlContent = @
        "<!DOCTYPE html>"
        "<html lang=\"vi\">"
        "<head>"
        "<meta charset=\"UTF-8\">"
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">"
        "<title>Sheepct Mod Menu</title>"
        "<style>"
        "body { margin: 0; padding: 0; background: transparent; font-family: -apple-system, sans-serif; color: #ffffff; user-select: none; -webkit-user-select: none; }"
        ".menu-container { position: absolute; top: 0; left: 0; width: 345px; height: 450px; background: rgba(15, 15, 25, 0.95); border: 1.5px solid rgba(0, 200, 255, 0.8); border-radius: 16px; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7); overflow: hidden; backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); }"
        ".header { padding: 12px; background: linear-gradient(90deg, rgba(0,100,200,0.5), rgba(0,200,255,0.2)); text-align: center; font-weight: bold; font-size: 13px; border-bottom: 1px solid rgba(255,255,255,0.1); }"
        ".author { font-size: 10px; color: #00e5ff; margin-top: 2px; }"
        ".content { padding: 12px; height: 330px; overflow-y: auto; }"
        ".btn-toggle { width: 100%; padding: 10px; margin-bottom: 8px; background: rgba(30, 30, 45, 0.9); border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 8px; color: #fff; font-weight: bold; font-size: 12px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; }"
        ".btn-toggle.active { background: rgba(20, 80, 40, 0.9); border-color: rgba(50, 255, 100, 0.6); color: #5eff7d; }"
        ".slider-group { margin-bottom: 12px; background: rgba(25, 25, 40, 0.6); padding: 8px; border-radius: 8px; }"
        ".slider-label { font-size: 11px; margin-bottom: 4px; display: flex; justify-content: space-between; color: #ffcc00; }"
        "input[type=range] { width: 100%; accent-color: #00e5ff; }"
        ".footer { position: absolute; bottom: 0; width: 100%; padding: 8px 0; text-align: center; background: rgba(10, 10, 15, 0.9); border-top: 1px solid rgba(255,255,255,0.1); }"
        ".btn-close { background: rgba(200, 50, 50, 0.8); color: white; border: none; padding: 6px 16px; border-radius: 6px; font-size: 11px; font-weight: bold; cursor: pointer; }"
        "</style>"
        "</head>"
        "<body>"
        "<div class=\"menu-container\">"
        "<div class=\"header\">👑 Sheepct Mod Menu<div class=\"author\">Tool do TRẦN MẠNH CƯỜNG phát triển</div></div>"
        "<div class=\"content\">"
        "<button class=\"btn-toggle\" id=\"godmode\" onclick=\"toggleMod('godmode')\"><span>1. Kháng sát thương (God Mode)</span><span id=\"txt-godmode\">[ TẮT ]</span></button>"
        "<button class=\"btn-toggle\" id=\"speed\" onclick=\"toggleMod('speed')\"><span>2. Tốc độ di chuyển</span><span id=\"txt-speed\">[ TẮT ]</span></button>"
        "<div class=\"slider-group\"><div class=\"slider-label\"><span>Hệ số Tốc độ</span><span id=\"val-speed\">1.0x</span></div><input type=\"range\" min=\"1\" max=\"10\" step=\"0.5\" value=\"1\" oninput=\"updateSlider('speed', this.value)\"></div>"
        "<button class=\"btn-toggle\" id=\"jump\" onclick=\"toggleMod('jump')\"><span>3. Khinh công / Nhảy cao</span><span id=\"txt-jump\">[ TẮT ]</span></button>"
        "<button class=\"btn-toggle\" id=\"gamespeed\" onclick=\"toggleMod('gamespeed')\"><span>4. Tăng tốc độ Game</span><span id=\"txt-gamespeed\">[ TẮT ]</span></button>"
        "</div>"
        "<div class=\"footer\"><button class=\"btn-close\" onclick=\"closeMenu()\">Ẩn Menu</button></div>"
        "</div>"
        "<script>"
        "let states = { godmode: false, speed: false, jump: false, gamespeed: false };"
        "function toggleMod(key) {"
        "  states[key] = !states[key];"
        "  let btn = document.getElementById(key);"
        "  let txt = document.getElementById('txt-' + key);"
        "  if (states[key]) { btn.classList.add('active'); txt.innerText = '[ BẬT ]'; } "
        "  else { btn.classList.remove('active'); txt.innerText = '[ TẮT ]'; }"
        "  window.webkit.messageHandlers.modCallback.postMessage({action: key, state: states[key]});"
        "}"
        "function updateSlider(key, val) {"
        "  document.getElementById('val-' + key).innerText = val + 'x';"
        "  window.webkit.messageHandlers.modCallback.postMessage({action: key + '_slider', value: val});"
        "}"
        "function closeMenu() { window.webkit.messageHandlers.modCallback.postMessage({action: 'close'}); }"
        "</script>"
        "</body>"
        "</html>";

        [webView loadHTMLString:htmlContent baseURL:nil];
        [vc.view addSubview:webView];
        self.menuWindow.hidden = NO;
    });
}

- (void)userContentController:(WKScriptMessageHandler *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"modCallback"]) {
        NSDictionary *dict = message.body;
        NSString *action = dict[@"action"];
        
        if ([action isEqualToString:@"close"]) {
            [self toggleMenu];
        } else if ([action isEqualToString:@"godmode"]) {
            g_enableGodMode = [dict[@"state"] boolValue];
        } else if ([action isEqualToString:@"speed"]) {
            g_enableSpeedHack = [dict[@"state"] boolValue];
        } else if ([action isEqualToString:@"jump"]) {
            g_enableHighJump = [dict[@"state"] boolValue];
        } else if ([action isEqualToString:@"gamespeed"]) {
            g_enableGameSpeed = [dict[@"state"] boolValue];
        } else if ([action isEqualToString:@"speed_slider"]) {
            g_speedMultiplier = [dict[@"value"] floatValue];
        }
    }
}

@end

// --- NÚT NỔI KÉO THẢ ---
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

// --- KHỞI TẠO & KÍCH HOẠT DOBBY HOOK ---
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

        [floatingBtn addTarget:[WebModMenuController sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [targetWindow addSubview:floatingBtn];
        [targetWindow bringSubviewToFront:floatingBtn];
    });
}
