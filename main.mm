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

// --- 1. CỜ TRẠNG THÁI & BIẾN ĐIỀU KHIỂN ---
bool g_BypassAntiCheat = true;
bool g_OneHit = true;
float g_DamageFactor = 50.0f;
bool g_BypassGMPanel = true;

// --- 2. KHAI BÁO CON TRỎ HÀM GỐC ---
static bool (*orig_AntiCheat_CheckIntegrity)(void *instance) = NULL;
static bool (*orig_GMCmd_IsGm)(void *instance) = NULL;
static float (*orig_AttackerSkill_HitAttacker)(void *instance) = NULL;

// --- 3. CÁC HÀM HOOK BYPASS & TÍNH NĂNG AN TOÀN ---

// Chặn kiểm tra tính toàn vẹn và chống lỗi update fail
bool hooked_AntiCheat_CheckIntegrity(void *instance) {
    if (g_BypassAntiCheat) {
        return false; // Ép hệ thống báo cáo: "Tệp sạch tuyệt đối, không có dấu hiệu can thiệp"
    }
    return orig_AntiCheat_CheckIntegrity ? orig_AntiCheat_CheckIntegrity(instance) : false;
}

// Mở khóa bảng lệnh GM Dev ẩn
bool hooked_GMCmd_IsGm(void *instance) {
    if (!instance) return false;
    if (g_BypassGMPanel) {
        return true;
    }
    return orig_GMCmd_IsGm(instance);
}

// Hàm nhân sát thương (One-Hit) bảo vệ con trỏ chống văng
float hooked_AttackerSkill_HitAttacker(void *instance) {
    if (!instance) return 0.0f;
    float baseDamage = orig_AttackerSkill_HitAttacker(instance);
    if (g_OneHit) {
        return baseDamage * g_DamageFactor;
    }
    return baseDamage;
}

// --- 4. GIAO DIỆN MOD MENU TỐI ƯU (SHEEPCT UI) ---
@interface SheepctModMenu : UIView
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation SheepctModMenu

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(30, 50, 340, 420)];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.06f alpha:0.94f];
        self.layer.cornerRadius = 18.0f;
        self.layer.borderWidth = 1.2f;
        self.layer.borderColor = [UIColor colorWithRed:0.6f green:0.2f blue:0.9f alpha:0.85f].CGColor;
        self.clipsToBounds = YES;
        self.hidden = YES;

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 310, 24)];
        self.titleLabel.text = @"Sheepct Ultimate Bypass | TRẦN MẠNH CƯỜNG";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:10.5f];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 45, 320, 360)];
        [self addSubview:self.contentScrollView];

        CGFloat yPos = 10;
        [self addToggleAtY:&yPos title:@"Vô Hiệu Hóa Anti-Cheat (Bypass)" isOn:g_BypassAntiCheat action:@selector(toggleBypass:)];
        [self addToggleAtY:&yPos title:@"Sát Thương Khủng (One-Hit 50x)" isOn:g_OneHit action:@selector(toggleOneHit:)];
        [self addToggleAtY:&yPos title:@"Mở Khóa Bảng Lệnh GM Dev" isOn:g_BypassGMPanel action:@selector(toggleGMPass:)];

        self.contentScrollView.contentSize = CGSizeMake(320, yPos + 20);
    }
    return self;
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
    *y += 45;
}

- (void)toggleBypass:(UISwitch *)sender { g_BypassAntiCheat = sender.isOn; }
- (void)toggleOneHit:(UISwitch *)sender { g_OneHit = sender.isOn; }
- (void)toggleGMPass:(UISwitch *)sender { g_BypassGMPanel = sender.isOn; }

@end

// --- 5. KHỞI CHẠY DYLIB & THỰC THI DOBBYHOOK AN TOÀN (DELAY 6 GIÂY) ---
__attribute__((constructor)) void initSheepctUltimateBypass() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t imageBase = (uintptr_t)_dyld_get_image_header(0);

        if (imageBase != 0) {
            // Thực hiện DobbyHook các hàm cốt lõi đã được cô lập an toàn
            DobbyHook((void *)(imageBase + 0x219bb6), (void *)hooked_GMCmd_IsGm, (void **)&orig_GMCmd_IsGm);
            DobbyHook((void *)(imageBase + 0x242e3), (void *)hooked_AttackerSkill_HitAttacker, (void **)&orig_AttackerSkill_HitAttacker);
            
            // Nếu game có offset hàm Integrity Check cụ thể, gán vào đây:
            // DobbyHook((void *)(imageBase + 0xOFFSET_INTEGRITY), (void *)hooked_AntiCheat_CheckIntegrity, (void **)&orig_AntiCheat_CheckIntegrity);
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
