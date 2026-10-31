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
// --- 3. GIAO DIỆN CYBER WEBVIEW MOD MENU ---
// ==========================================
@interface CyberMenuController : NSObject <WKScriptMessageHandler, WKNavigationDelegate>
@property (nonatomic, strong) UIWindow *menuWindow;
+ (instancetype)sharedInstance;
- (void)preloadMenu;
- (void)toggleMenu;
@end

@implementation CyberMenuController {
    WKWebView *webView;
}

+ (instancetype)sharedInstance {
    static CyberMenuController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CyberMenuController alloc] init];
    });
    return shared;
}

- (void)preloadMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.menuWindow) return;

        self.menuWindow = [[UIWindow alloc] initWithFrame:CGRectMake(15, 40, 360, 480)];
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
        "<!doctype html>"
        "<html lang=\"vi\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no\"><title>Cyber Menu UI</title><style>"
        ":root{--bg:#101014;--card:#18181e;--line:#303039;--red:#ff304f;--cyan:#57e5ff;--muted:#9696a1}*{box-sizing:border-box}body{margin:0;background:transparent;font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif;color:#f4f4f7;padding:0}"
        ".panel{width:360px;height:480px;background:#101014f5;border:1px solid #34343e;border-radius:22px;box-shadow:0 25px 90px #000b;overflow:hidden;display:flex;flex-direction:column}"
        ".top{height:60px;flex:none;display:flex;align-items:center;gap:10px;padding:0 16px;border-bottom:1px solid #26262e}"
        ".logo{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#173654,#10121b);display:grid;place-items:center;color:var(--cyan);font-size:16px;font-weight:900;box-shadow:0 0 12px #00d9ff35}"
        ".brand{font-size:16px;font-weight:800;letter-spacing:.4px}"
        ".sub{font-size:10px;color:var(--muted);margin-top:2px}"
        ".spacer{flex:1}"
        ".topbtn{border:0;border-radius:10px;background:#202027;color:#eee;padding:8px 12px;font-size:12px;font-weight:700;cursor:pointer}"
        ".topbtn.hot{color:var(--red)}"
        ".main{flex:1;min-height:0;overflow-y:auto;padding:12px;display:flex;flex-direction:column;gap:10px}"
        ".card{background:var(--card);border:1px solid #22222a;border-radius:18px;padding:12px}"
        ".card h2{font-size:13px;margin:0 0 10px;text-transform:uppercase;letter-spacing:.5px}"
        ".accent{color:var(--red);margin-right:6px}"
        ".row{min-height:48px;display:flex;align-items:center;gap:10px;padding:6px 2px;border-bottom:1px solid #292930}"
        ".ico{width:20px;text-align:center;color:var(--red);font-size:16px;font-weight:800}"
        ".text{min-width:0;flex:1}"
        ".label{font-size:13px;font-weight:650;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}"
        ".hint{font-size:10px;color:var(--muted);margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}"
        ".switch{width:42px;height:24px;border-radius:20px;border:0;background:#414149;padding:2px;cursor:pointer;flex:none}"
        ".switch:after{content:\"\";display:block;width:20px;height:20px;border-radius:50%;background:#aaa;transition:.18s}"
        ".switch.on{background:var(--red)}.switch.on:after{transform:translateX(18px);background:white}"
        ".sliderbox{padding:10px 2px 2px}"
        ".sliderhead{display:flex;justify-content:space-between;font-size:12px;font-weight:650}"
        ".sliderhead span:last-child{color:#fff}"
        ".range{width:100%;margin:10px 0 0;accent-color:var(--red)}"
        ".nav{height:50px;flex:none;display:flex;justify-content:space-around;align-items:center;border-top:1px solid #292930;background:#121216}"
        ".nav button{border:0;background:none;color:#a3a3ad;font-weight:700;font-size:11px;padding:8px 10px;cursor:pointer}"
        ".nav button.sel{color:white;background:#25252d;border-radius:10px}"
        ".foot{text-align:center;color:#66d9ec;font-size:10px;font-weight:700;padding:6px;letter-spacing:.3px}"
        "</style></head><body>"
        "<div class=\"panel\">"
        "<header class=\"top\"><div class=\"logo\">C✦</div><div><div class=\"brand\">CYBER CONTROL</div><div class=\"sub\">TRẦN MẠNH CƯỜNG</div></div><div class=\"spacer\"></div><button class=\"topbtn hot\" onclick=\"closeMenu()\">✕ ĐÓNG</button></header>"
        "<main class=\"main\">"
        "<section class=\"card\"><h2><span class=\"accent\">◉</span>TÙY CHỈNH MOD</h2>"
        "<div class=\"row\"><span class=\"ico\">✧</span><div class=\"text\"><div class=\"label\">1. Kháng sát thương</div><div class=\"hint\">God Mode</div></div><button class=\"switch\" id=\"sw-godmode\" onclick=\"toggleMod('godmode')\"></button></div>"
        "<div class=\"row\"><span class=\"ico\">▦</span><div class=\"text\"><div class=\"label\">2. Tốc độ di chuyển</div><div class=\"hint\">Speed Hack</div></div><button class=\"switch\" id=\"sw-speed\" onclick=\"toggleMod('speed')\"></button></div>"
        "<div class=\"sliderbox\"><div class=\"sliderhead\"><span>Hệ số Tốc độ</span><span id=\"val-speed\">1.0x</span></div><input class=\"range\" type=\"range\" min=\"1\" max=\"10\" step=\"0.5\" value=\"1\" oninput=\"updateSlider('speed', this.value)\"></div>"
        "</section>"
        "<section class=\"card\"><h2><span class=\"accent\">⌁</span>HỆ THỐNG & GAME</h2>"
        "<div class=\"row\"><span class=\"ico\">◉</span><div class=\"text\"><div class=\"label\">3. Khinh công / Nhảy cao</div><div class=\"hint\">High Jump</div></div><button class=\"switch\" id=\"sw-jump\" onclick=\"toggleMod('jump')\"></button></div>"
        "<div class=\"sliderbox\"><div class=\"sliderhead\"><span>Tốc độ Game</span><span id=\"val-gamespeed\">1.0x</span></div><input class=\"range\" type=\"range\" min=\"1\" max=\"10\" step=\"0.5\" value=\"1\" oninput=\"updateSlider('gamespeed', this.value)\"></div>"
        "</section>"
        "</main>"
        "<nav class=\"nav\"><button class=\"sel\">TỔNG QUAN</button><button>CÀI ĐẶT</button></nav>"
        "<div class=\"foot\">CYBER UI • TRẦN MẠNH CƯỜNG PHÁT TRIỂN</div>"
        "</div>"
        "<script>"
        "let states = { godmode: false, speed: false, jump: false };"
        "function toggleMod(key) {"
        "  states[key] = !states[key];"
        "  let btn = document.getElementById('sw-' + key);"
        "  if (states[key]) { btn.classList.add('on'); } else { btn.classList.remove('on'); }"
        "  window.webkit.messageHandlers.modCallback.postMessage({action: key, state: states[key]});"
        "}"
        "function updateSlider(key, val) {"
        "  document.getElementById('val-' + key).innerText = val + 'x';"
        "  window.webkit.messageHandlers.modCallback.postMessage({action: key + '_slider', value: val});"
        "}"
        "function closeMenu() { window.webkit.messageHandlers.modCallback.postMessage({action: 'close'}); }"
        "</script>"
        "</body></html>";

        [webView loadHTMLString:htmlContent baseURL:nil];
        [vc.view addSubview:webView];
        
        self.menuWindow.hidden = YES;
    });
}

- (void)toggleMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.menuWindow) {
            self.menuWindow.hidden = !self.menuWindow.hidden;
        }
    });
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
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
            g_enableGameSpeed = YES;
            g_gameSpeedScale = [dict[@"value"] floatValue];
        } else if ([action isEqualToString:@"speed_slider"]) {
            g_speedMultiplier = [dict[@"value"] floatValue];
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

// --- 5. KHỞI TẠO & KÍCH HOẠT DOBBY HOOK ---
__attribute__((constructor)) static void init_sheepct_mod() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[CyberMenuController sharedInstance] preloadMenu];
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
        [floatingBtn setTitle:@"C" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
        [floatingBtn setTitleColor:[UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:1.0f] forState:UIControlStateNormal];
        floatingBtn.layer.cornerRadius = 24.0f;
        floatingBtn.layer.borderWidth = 1.8f;
        floatingBtn.layer.borderColor = [UIColor colorWithRed:0.34f green:0.9f blue:1.0f alpha:1.0f].CGColor;

        [floatingBtn addTarget:[CyberMenuController sharedInstance] action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [targetWindow addSubview:floatingBtn];
        [targetWindow bringSubviewToFront:floatingBtn];
    });
}
