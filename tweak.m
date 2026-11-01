#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <objc/message.h>

static id hooked_FakeUDID(id self, SEL _cmd) {
    return @"00008110-001A2B3C4D5E6F00";
}

static id hooked_FakeIDFV(id self, SEL _cmd) {
    return @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
}

static id hooked_FakeIDFVWithCache(id self, SEL _cmd, BOOL *status) {
    if (status) {
        *status = YES;
    }
    return @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
}

static BOOL hooked_ReturnNO(id self, SEL _cmd) {
    return NO;
}

static BOOL hooked_ReturnYES(id self, SEL _cmd) {
    return YES;
}

static int hooked_ActivationState(id self, SEL _cmd) {
    return 1;
}

static void hooked_NoOp(id self, SEL _cmd) {
}

static void purgeBlockingOverlays(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<UIWindow *> *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *win in windows) {
            NSString *winClass = NSStringFromClass([win class]);
            
            if ([winClass containsString:@"APIClient"] ||
                [winClass containsString:@"ASStatus"] ||
                [winClass containsString:@"Alert"] ||
                win.windowLevel > UIWindowLevelNormal) {
                win.hidden = YES;
                win.alpha = 0.0;
                win.userInteractionEnabled = NO;
            }
            
            for (UIView *sub in [win subviews]) {
                NSString *subClass = NSStringFromClass([sub class]);
                if ([subClass containsString:@"ASStatus"] ||
                    [subClass containsString:@"APIClient"] ||
                    [subClass containsString:@"FCAlert"]) {
                    [sub removeFromSuperview];
                } else {
                    for (UIView *child in [sub subviews]) {
                        if ([child isKindOfClass:[UILabel class]]) {
                            UILabel *lbl = (UILabel *)child;
                            if ([lbl.text containsString:@"Package initializing"] ||
                                [lbl.text containsString:@"Initializing"]) {
                                [sub removeFromSuperview];
                                break;
                            }
                        }
                    }
                }
            }
        }
    });
}

static void hooked_BypassAndDismissUI(id self, SEL _cmd) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isKindOfClass:[UIWindow class]]) {
            UIWindow *win = (UIWindow *)self;
            win.hidden = YES;
            win.alpha = 0.0;
            win.userInteractionEnabled = NO;
        } else if ([self isKindOfClass:[UIView class]]) {
            [(UIView *)self removeFromSuperview];
        } else if ([self isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)self;
            [vc.view removeFromSuperview];
            if (vc.view.window && vc.view.window != [[UIApplication sharedApplication] keyWindow]) {
                vc.view.window.hidden = YES;
                vc.view.window.userInteractionEnabled = NO;
            }
        }

        const char *dismissNames[] = {
            "dismiss",
            "hide",
            "hideLoading",
            "dismissLoading",
            "dismissOverlay",
            "removeOverlay",
            "onLoginSuccess"
        };
        for (size_t i = 0; i < sizeof(dismissNames) / sizeof(dismissNames[0]); i++) {
            SEL dSel = sel_registerName(dismissNames[i]);
            if ([self respondsToSelector:dSel]) {
                ((void (*)(id, SEL))objc_msgSend)(self, dSel);
            }
        }

        purgeBlockingOverlays();
    });
}

static void hookSelectorOnClass(Class cls, SEL sel, IMP newImp) {
    if (!cls || !sel || !newImp) return;

    Method instMethod = class_getInstanceMethod(cls, sel);
    if (instMethod) {
        class_replaceMethod(cls, sel, newImp, method_getTypeEncoding(instMethod));
    }

    Method clsMethod = class_getClassMethod(cls, sel);
    if (clsMethod) {
        Class metaCls = object_getClass((id)cls);
        if (metaCls) {
            class_replaceMethod(metaCls, sel, newImp, method_getTypeEncoding(clsMethod));
        }
    }
}

static void applyAuthBypass(void) {
    const char *deviceClasses[] = {
        "VKKeychainIDFV",
        "ASClientInfo",
        "DeviceInfo",
        "ASStatusUDIDAlertView",
        "ASDebugSessionManager",
        "UIDevice"
    };

    SEL udidSelectors[] = {
        sel_registerName("VKgetUdidFromKeyChain"),
        sel_registerName("VKKeychainUDID"),
        sel_registerName("getDeviceIdentifier")
    };

    SEL idfvSelectors[] = {
        sel_registerName("VKgetIdfvFromKeyChain"),
        sel_registerName("VKKeychainIDFV"),
        sel_registerName("identifierForVendor")
    };

    for (size_t i = 0; i < sizeof(deviceClasses) / sizeof(deviceClasses[0]); i++) {
        Class cls = objc_getClass(deviceClasses[i]);
        if (!cls) continue;

        for (size_t j = 0; j < sizeof(udidSelectors) / sizeof(udidSelectors[0]); j++) {
            hookSelectorOnClass(cls, udidSelectors[j], (IMP)hooked_FakeUDID);
        }
        for (size_t k = 0; k < sizeof(idfvSelectors) / sizeof(idfvSelectors[0]); k++) {
            hookSelectorOnClass(cls, idfvSelectors[k], (IMP)hooked_FakeIDFV);
        }

        hookSelectorOnClass(cls, sel_registerName("VKKeychainIDFVWithCacheStatus:"), (IMP)hooked_FakeIDFVWithCache);
        hookSelectorOnClass(cls, sel_registerName("activationState"), (IMP)hooked_ActivationState);
        hookSelectorOnClass(cls, sel_registerName("isAuthorized"), (IMP)hooked_ReturnYES);
        hookSelectorOnClass(cls, sel_registerName("isActivated"), (IMP)hooked_ReturnYES);
        hookSelectorOnClass(cls, sel_registerName("isVerified"), (IMP)hooked_ReturnYES);
    }

    Class jbCls = objc_getClass("DTTJailbreakDetection");
    if (jbCls) {
        hookSelectorOnClass(jbCls, sel_registerName("isJailbroken"), (IMP)hooked_ReturnNO);
    }

    const char *uiClasses[] = {
        "ASStatusUDIDAlertView",
        "ASStatusView",
        "APIClientOverlayViewController",
        "APIClientOverlayWindow",
        "FCAlertView"
    };

    SEL dismissTriggerSelectors[] = {
        sel_registerName("showLoginForm"),
        sel_registerName("setupLoginForm"),
        sel_registerName("showLoginFormWithTitle:description:placeholder:submitTitle:contactTitle:countdownFrom:"),
        sel_registerName("showExpiredForm"),
        sel_registerName("setupExpiredForm"),
        sel_registerName("showExpiredWithTitle:message:changeKeyTitle:copyUDIDTitle:copyKeyTitle:countdownFrom:"),
        sel_registerName("showUDIDAlertWithTitle:message:leftTitle:rightTitle:leftAction:rightAction:"),
        sel_registerName("showAlertView"),
        sel_registerName("showLoginError:"),
        sel_registerName("showLoginLoading")
    };

    SEL timerSelectors[] = {
        sel_registerName("startCountdownTimer"),
        sel_registerName("countdownTimerFired"),
        sel_registerName("scheduleExpiry")
    };

    for (size_t i = 0; i < sizeof(uiClasses) / sizeof(uiClasses[0]); i++) {
        Class cls = objc_getClass(uiClasses[i]);
        if (!cls) continue;

        for (size_t j = 0; j < sizeof(dismissTriggerSelectors) / sizeof(dismissTriggerSelectors[0]); j++) {
            hookSelectorOnClass(cls, dismissTriggerSelectors[j], (IMP)hooked_BypassAndDismissUI);
        }
        for (size_t k = 0; k < sizeof(timerSelectors) / sizeof(timerSelectors[0]); k++) {
            hookSelectorOnClass(cls, timerSelectors[k], (IMP)hooked_NoOp);
        }
        hookSelectorOnClass(cls, sel_registerName("isAlertVisible"), (IMP)hooked_ReturnNO);
    }
}

__attribute__((constructor)) static void initAuthBypass(void) {
    applyAuthBypass();

    dispatch_async(dispatch_get_main_queue(), ^{
        applyAuthBypass();
        purgeBlockingOverlays();
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        applyAuthBypass();
        purgeBlockingOverlays();
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        purgeBlockingOverlays();
    });
}
